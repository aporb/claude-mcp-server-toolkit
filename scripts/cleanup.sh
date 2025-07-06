#!/bin/bash

# =============================================================================
# MCP Server Cleanup Script
# =============================================================================
# Purpose: Remove all configured MCP servers and clean up Docker resources
# Usage: bash scripts/cleanup.sh [--force] [--docker-only] [--config-only]
# Exit Codes:
#   0 - Success
#   1 - User cancelled operation
#   2 - Claude CLI not available
#   3 - Docker cleanup failed
#   4 - Configuration cleanup failed
# =============================================================================

# Strict error handling
set -euo pipefail

# Trap for cleanup on script termination
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo "❌ Script failed at line $1 with exit code $exit_code" >&2
    fi
}
trap 'cleanup $LINENO' EXIT ERR

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  echo "[$timestamp] ℹ️  $message" ;;
        "WARN")  echo "[$timestamp] ⚠️  $message" >&2 ;;
        "ERROR") echo "[$timestamp] ❌ $message" >&2 ;;
        "SUCCESS") echo "[$timestamp] ✅ $message" ;;
        *) echo "[$timestamp] $message" ;;
    esac
}

# Parse command line arguments
FORCE_MODE=false
DOCKER_ONLY=false
CONFIG_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE_MODE=true
            shift
            ;;
        --docker-only)
            DOCKER_ONLY=true
            shift
            ;;
        --config-only)
            CONFIG_ONLY=true
            shift
            ;;
        --help)
            echo "Usage: $0 [--force] [--docker-only] [--config-only]"
            echo "  --force       Skip confirmation prompt"
            echo "  --docker-only Clean up only Docker resources"
            echo "  --config-only Clean up only MCP configurations"
            echo "  --help        Show this help message"
            exit 0
            ;;
        *)
            log "ERROR" "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Determine the project root dynamically
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

log "INFO" "Starting MCP server cleanup process..."

# Confirmation prompt (unless force mode)
if [[ "$FORCE_MODE" != true ]]; then
    echo ""
    echo "⚠️  WARNING: This will remove configured MCP servers and clean up Docker resources."
    echo ""
    if [[ "$DOCKER_ONLY" == true ]]; then
        echo "🐳 Docker cleanup mode: Will clean up Docker containers and images only"
    elif [[ "$CONFIG_ONLY" == true ]]; then
        echo "⚙️  Configuration cleanup mode: Will remove MCP server configurations only"
    else
        echo "🧹 Full cleanup mode: Will remove both configurations and Docker resources"
    fi
    echo ""
    echo "Are you sure you want to proceed? (y/N)"
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log "INFO" "Operation cancelled by user."
        exit 1
    fi
fi

# Function to clean up MCP configurations
cleanup_mcp_configs() {
    log "INFO" "Cleaning up MCP server configurations..."
    
    # Check if claude command is available
    if ! command -v claude &> /dev/null; then
        log "WARN" "Claude CLI not available. Skipping MCP server removal."
        return 0
    fi
    
    # Get list of all servers
    local servers
    if ! servers=$(claude mcp list 2>/dev/null | grep -v "No MCP servers" | awk '{print $1}' 2>/dev/null); then
        log "INFO" "No MCP servers found or unable to list servers"
        return 0
    fi
    
    if [[ -z "$servers" ]]; then
        log "INFO" "No MCP servers configured"
        return 0
    fi
    
    # Remove each server
    local removed_count=0
    while IFS= read -r server; do
        if [[ -n "$server" ]]; then
            log "INFO" "Removing server: $server"
            if claude mcp remove "$server" 2>/dev/null; then
                log "SUCCESS" "Removed server: $server"
                ((removed_count++))
            else
                log "WARN" "Failed to remove server: $server"
            fi
        fi
    done <<< "$servers"
    
    log "SUCCESS" "Removed $removed_count MCP server(s)"
}

# Function to clean up Docker resources
cleanup_docker_resources() {
    log "INFO" "Cleaning up Docker resources..."
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        log "WARN" "Docker not available. Skipping Docker cleanup."
        return 0
    fi
    
    if ! docker info > /dev/null 2>&1; then
        log "WARN" "Docker is not running. Skipping Docker cleanup."
        return 0
    fi
    
    # Stop and remove MCP-related containers
    log "INFO" "Stopping MCP-related containers..."
    local containers
    containers=$(docker ps -q --filter ancestor=ghcr.io/github/github-mcp-server --filter ancestor=memory-bank-mcp:local --filter ancestor=mcp/atlassian 2>/dev/null || true)
    
    if [[ -n "$containers" ]]; then
        if docker stop $containers 2>/dev/null; then
            log "SUCCESS" "Stopped MCP containers"
        else
            log "WARN" "Some containers may not have stopped cleanly"
        fi
        
        if docker rm $containers 2>/dev/null; then
            log "SUCCESS" "Removed MCP containers"
        else
            log "WARN" "Some containers may not have been removed"
        fi
    else
        log "INFO" "No running MCP containers found"
    fi
    
    # Remove MCP-related images (with confirmation)
    log "INFO" "Removing MCP-related Docker images..."
    local images
    images=$(docker images -q memory-bank-mcp:local 2>/dev/null || true)
    
    if [[ -n "$images" ]]; then
        if docker rmi $images 2>/dev/null; then
            log "SUCCESS" "Removed MCP Docker images"
        else
            log "WARN" "Some images may not have been removed (they might be in use)"
        fi
    else
        log "INFO" "No local MCP images found"
    fi
    
    # Clean up unused Docker resources
    log "INFO" "Cleaning up unused Docker resources..."
    if docker system prune -f > /dev/null 2>&1; then
        log "SUCCESS" "Cleaned up unused Docker resources"
    else
        log "WARN" "Docker system prune encountered issues"
    fi
}

# Execute cleanup based on mode
if [[ "$CONFIG_ONLY" == true ]]; then
    cleanup_mcp_configs
elif [[ "$DOCKER_ONLY" == true ]]; then
    cleanup_docker_resources
else
    # Full cleanup
    cleanup_mcp_configs
    cleanup_docker_resources
fi

# Clean up data directories (with extra caution)
if [[ "$DOCKER_ONLY" != true ]]; then
    log "INFO" "Cleaning up data directories..."
    if [[ -d "$PROJECT_ROOT/data" ]]; then
        # Only remove if it's clearly our data directory
        if [[ -d "$PROJECT_ROOT/data/memory-bank" ]]; then
            rm -rf "$PROJECT_ROOT/data/memory-bank" 2>/dev/null || log "WARN" "Could not remove memory-bank data directory"
            log "SUCCESS" "Removed memory-bank data directory"
        fi
    fi
fi

log "SUCCESS" "Cleanup process completed!"
log "INFO" "You may need to restart your AI platform to see the changes"
