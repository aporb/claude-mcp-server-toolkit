#!/bin/bash

# =============================================================================
# Memory Bank MCP Connector Script
# =============================================================================
# Purpose: Runs Memory Bank MCP server in a clean Docker container with persistence
# Usage: Called automatically by Claude's MCP configuration
# Requirements: Docker, memory-bank-mcp:local Docker image
# Exit Codes:
#   0 - Success
#   1 - Docker not available/running
#   2 - Memory Bank image not found
#   3 - Container failed to start
#   4 - Data directory issues
# =============================================================================

# Strict error handling
set -euo pipefail

# Trap for cleanup on script termination
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo "❌ Memory Bank MCP Connector failed at line $1 with exit code $exit_code" >&2
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

# Validate project root
if [[ ! -d "$PROJECT_ROOT" ]]; then
    log "ERROR" "Project root directory not found: $PROJECT_ROOT"
    exit 1
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

# Verify the Docker image exists
log "DEBUG" "Checking for memory-bank-mcp:local image..."
if ! docker image inspect memory-bank-mcp:local >/dev/null 2>&1; then
    log "ERROR" "memory-bank-mcp:local image not found"
    log "ERROR" "Please run: bash \"$PROJECT_ROOT/scripts/build-memory-bank.sh\""
    
    # Show available memory bank images for debugging
    local available_images
    if available_images=$(docker images --filter reference=memory-bank-mcp --format "{{.Repository}}:{{.Tag}}" 2>/dev/null); then
        if [[ -n "$available_images" ]]; then
            log "INFO" "Available memory-bank images:"
            echo "$available_images" | while read -r image; do
                log "INFO" "  - $image"
            done
        fi
    fi
    exit 2
fi

# Ensure data directory exists with proper permissions
DATA_DIR="$PROJECT_ROOT/data/memory-bank"
log "DEBUG" "Ensuring data directory exists: $DATA_DIR"

if ! mkdir -p "$DATA_DIR"; then
    log "ERROR" "Failed to create data directory: $DATA_DIR"
    exit 4
fi

# Set proper permissions for the data directory
if ! chmod 755 "$DATA_DIR"; then
    log "WARN" "Could not set permissions on data directory"
fi

# Validate data directory is accessible
if [[ ! -w "$DATA_DIR" ]]; then
    log "ERROR" "Data directory is not writable: $DATA_DIR"
    exit 4
fi

log "DEBUG" "Starting Memory Bank MCP container with persistent data..."

# Run a fresh container with automatic cleanup and persistent data
# -i: Interactive mode for stdio communication
# --rm: Remove container when it exits (prevents accumulation)
# -v: Mount data directory for persistence
# --user: Run as current user to avoid permission issues
exec docker run -i --rm \
    -v "$DATA_DIR:/app/data" \
    --user "$(id -u):$(id -g)" \
    memory-bank-mcp:local "$@"
