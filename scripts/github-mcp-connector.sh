#!/bin/bash

# =============================================================================
# GitHub MCP Connector Script
# =============================================================================
# Purpose: Connects Claude to GitHub MCP Docker container with dynamic discovery
# Usage: Called automatically by Claude's MCP configuration
# Requirements: Docker, GitHub MCP server container, GITHUB_PERSONAL_ACCESS_TOKEN
# Exit Codes:
#   0 - Success
#   1 - Docker not available/running
#   2 - No GitHub MCP container found
#   3 - Container not responding
#   4 - Missing environment variables
# =============================================================================

# Strict error handling
set -euo pipefail

# Trap for cleanup on script termination
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo "❌ GitHub MCP Connector failed at line $1 with exit code $exit_code" >&2
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
        "INFO")  echo "[$timestamp] ℹ️  $message" >&2 ;;
        "WARN")  echo "[$timestamp] ⚠️  $message" >&2 ;;
        "ERROR") echo "[$timestamp] ❌ $message" >&2 ;;
        "DEBUG") [[ "${DEBUG:-}" == "true" ]] && echo "[$timestamp] 🐛 $message" >&2 ;;
        *) echo "[$timestamp] $message" >&2 ;;
    esac
}

# Determine the project root dynamically
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load environment variables if .env exists
if [[ -f "$PROJECT_ROOT/.env" ]]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

# Validate required environment variables
if [[ -z "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]]; then
    log "ERROR" "GITHUB_PERSONAL_ACCESS_TOKEN environment variable is required"
    log "ERROR" "Please set it in $PROJECT_ROOT/.env or your environment"
    exit 4
fi

# Check if Docker is available and running
log "DEBUG" "Checking Docker availability..."
if ! command -v docker &> /dev/null; then
    log "ERROR" "Docker command not found. Please install Docker."
    exit 1
fi

if ! docker info > /dev/null 2>&1; then
    log "ERROR" "Docker is not running. Please start Docker."
    exit 1
fi

# Function to find or start GitHub MCP container
find_or_start_container() {
    local container_id
    
    # First, try to find an existing running container
    container_id=$(docker ps -q --filter ancestor=ghcr.io/github/github-mcp-server --filter status=running | head -n1)
    
    if [[ -n "$container_id" ]]; then
        log "DEBUG" "Found running GitHub MCP container: $container_id"
        echo "$container_id"
        return 0
    fi
    
    # If no running container, try to start a stopped one
    container_id=$(docker ps -aq --filter ancestor=ghcr.io/github/github-mcp-server | head -n1)
    
    if [[ -n "$container_id" ]]; then
        log "DEBUG" "Starting existing GitHub MCP container: $container_id"
        if docker start "$container_id" > /dev/null 2>&1; then
            # Wait a moment for the container to be ready
            sleep 2
            echo "$container_id"
            return 0
        else
            log "WARN" "Failed to start existing container, will create new one"
        fi
    fi
    
    # Create and start a new container
    log "DEBUG" "Creating new GitHub MCP container..."
    if container_id=$(docker run -d --rm \
        -e GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN" \
        ghcr.io/github/github-mcp-server 2>/dev/null); then
        
        # Wait for container to be ready
        sleep 3
        
        # Verify container is running
        if docker ps -q --filter id="$container_id" --filter status=running > /dev/null; then
            log "DEBUG" "Created and started new GitHub MCP container: $container_id"
            echo "$container_id"
            return 0
        else
            log "ERROR" "Container started but is not running properly"
            return 1
        fi
    else
        log "ERROR" "Failed to create GitHub MCP container"
        return 1
    fi
}

# Function to test container connectivity
test_container() {
    local container_id="$1"
    
    # Test if we can execute commands in the container
    if timeout 10 docker exec "$container_id" echo "test" > /dev/null 2>&1; then
        return 0
    else
        log "WARN" "Container $container_id is not responding to exec commands"
        return 1
    fi
}

# Main execution
log "DEBUG" "Starting GitHub MCP connector..."

# Find or start the container
if ! CONTAINER_ID=$(find_or_start_container); then
    log "ERROR" "Could not find or start GitHub MCP container"
    log "ERROR" "Available containers:"
    docker ps --filter ancestor=ghcr.io/github/github-mcp-server --format "table {{.ID}}\t{{.Status}}\t{{.CreatedAt}}" >&2 || true
    exit 2
fi

# Test container connectivity
if ! test_container "$CONTAINER_ID"; then
    log "ERROR" "GitHub MCP container $CONTAINER_ID is not responding"
    exit 3
fi

log "DEBUG" "Connecting to GitHub MCP container: $CONTAINER_ID"

# Connect to the container's stdio interface
# The 'stdio' argument is crucial for MCP protocol communication
exec docker exec -i "$CONTAINER_ID" /server/github-mcp-server stdio "$@"
