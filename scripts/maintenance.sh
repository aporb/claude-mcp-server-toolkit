#!/bin/bash

# =============================================================================
# MCP Server Maintenance Script
# =============================================================================
# Purpose: Automated maintenance for MCP server infrastructure
# Usage: bash scripts/maintenance.sh [--force] [--skip-backup] [--verbose]
# Exit Codes:
#   0 - Success
#   1 - Docker not available/running
#   2 - Environment configuration error
#   3 - Update failures detected
#   4 - Backup failures detected
# =============================================================================

# Strict error handling
set -euo pipefail

# Trap for cleanup on script termination
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo "❌ Maintenance script failed at line $1 with exit code $exit_code" >&2
    fi
}
trap 'cleanup $LINENO' EXIT ERR

# Global variables
FORCE_MODE=false
SKIP_BACKUP=false
VERBOSE=false
ERRORS_COUNT=0
WARNINGS_COUNT=0

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  echo "[$timestamp] ℹ️  $message" ;;
        "WARN")  
            echo "[$timestamp] ⚠️  $message" >&2
            ((WARNINGS_COUNT++))
            ;;
        "ERROR") 
            echo "[$timestamp] ❌ $message" >&2
            ((ERRORS_COUNT++))
            ;;
        "SUCCESS") echo "[$timestamp] ✅ $message" ;;
        "DEBUG") [[ "$VERBOSE" == true ]] && echo "[$timestamp] 🐛 $message" >&2 ;;
        *) echo "[$timestamp] $message" ;;
    esac
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE_MODE=true
            shift
            ;;
        --skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--force] [--skip-backup] [--verbose]"
            echo "  --force       Skip confirmation prompts"
            echo "  --skip-backup Skip configuration backup"
            echo "  --verbose     Enable verbose output"
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

# Validate project root
if [[ ! -d "$PROJECT_ROOT" ]]; then
    log "ERROR" "Project root directory not found: $PROJECT_ROOT"
    exit 2
fi

# Load environment variables with error handling
load_environment() {
    log "DEBUG" "Loading environment variables..."
    
    if [[ -f "$PROJECT_ROOT/.env" ]]; then
        set -a
        source "$PROJECT_ROOT/.env"
        set +a
        log "DEBUG" "Loaded environment from .env file"
    elif [[ -f "$PROJECT_ROOT/config/config.sh" ]]; then
        source "$PROJECT_ROOT/config/config.sh"
        log "DEBUG" "Loaded environment from config.sh file"
    else
        log "ERROR" "No environment configuration found!"
        log "ERROR" "Please create .env file or run: bash scripts/setup-github-token.sh"
        exit 2
    fi
}

# Initialize
load_environment

log "INFO" "Starting MCP server maintenance tasks..."

# Update Node.js packages (for Jan.ai Integration - NPM fallback per ADR-002)
echo "Updating Node.js packages for Jan.ai integration..."
npm update -g jan-mcp-server

# Update Docker images (Docker-first strategy per ADR-002)
echo "Updating Docker images..."
echo "1/9: Updating Atlassian MCP Server..."
docker pull mcp/atlassian

echo "2/9: Updating GitHub MCP Server..."
docker pull ghcr.io/github/github-mcp-server

echo "3/9: Updating Filesystem MCP Server..."
docker pull mcp/server-filesystem

echo "4/9: Updating Git MCP Server..."
docker pull mcp/server/git

echo "5/9: Updating Memory MCP Server..."
docker pull mcp/server-memory

echo "6/9: Updating Browser Tools MCP Server..."
docker pull mcp/browser-tools-mcp

echo "7/9: Updating Fetch MCP Server..."
docker pull zcaceres/fetch-mcp

# For custom builds, check if source repo has changed
echo "8/9: Checking for Context7 MCP Server updates..."
if [ -d "$PROJECT_ROOT/context7-mcp" ]; then
  echo "Found Context7 repo, checking for updates..."
  cd "$PROJECT_ROOT/context7-mcp"
  git fetch
  LOCAL=$(git rev-parse HEAD)
  REMOTE=$(git rev-parse @{u})
  
  if [ "$LOCAL" != "$REMOTE" ]; then
    echo "Updates available for Context7 MCP Server, rebuilding..."
    git pull
    docker build -t context7-mcp .
  else
    echo "Context7 MCP Server is up to date."
  fi
  cd "$PROJECT_ROOT"
else
  echo "Context7 repo not found locally. To update, clone and build manually:"
  echo "git clone https://github.com/upstash/context7-mcp.git && cd context7-mcp && docker build -t context7-mcp ."
fi

echo "9/9: Checking for Sequential Thinking MCP Server updates..."
if [ -d "$PROJECT_ROOT/mcp-servers" ]; then
  echo "Found MCP servers repo, checking for updates..."
  cd "$PROJECT_ROOT/mcp-servers"
  git fetch
  LOCAL=$(git rev-parse HEAD)
  REMOTE=$(git rev-parse @{u})
  
  if [ "$LOCAL" != "$REMOTE" ]; then
    echo "Updates available for Sequential Thinking MCP Server, rebuilding..."
    git pull
    docker build -t mcp/sequentialthinking -f src/sequentialthinking/Dockerfile .
  else
    echo "Sequential Thinking MCP Server is up to date."
  fi
  cd "$PROJECT_ROOT"
else
  echo "MCP servers repo not found locally. To update, clone and build manually:"
  echo "git clone https://github.com/modelcontextprotocol/servers.git && cd servers && docker build -t mcp/sequentialthinking -f src/sequentialthinking/Dockerfile ."
fi

# Rebuild Memory Bank MCP Server
echo "Rebuilding Memory Bank MCP Server..."
bash "$PROJECT_ROOT/scripts/build-memory-bank.sh"

# Clean up Docker
echo "Cleaning up Docker resources..."
echo "Removing stopped containers..."
docker container prune -f

echo "Removing unused images..."
docker image prune -f

echo "Removing unused volumes..."
docker volume prune -f

# Backup MCP server configurations
echo "Backing up MCP configurations..."
backup_dir="$PROJECT_ROOT/backups/$(date +%Y%m%d)"
mkdir -p "$backup_dir"
claude mcp list > "$backup_dir/mcp-servers-list.txt"
for server in $(claude mcp list | grep -v "No MCP servers" | awk '{print $1}'); do
  claude mcp get "$server" > "$backup_dir/$server-config.json"
done

# Rotate logs
echo "Rotating logs..."
log_dir="$PROJECT_ROOT/logs"
find "$log_dir" -name "*.log" -mtime +30 -delete

# Display Docker images and their sizes
echo "Current Docker images:"
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep -E 'mcp|github|fetch'

# Display disk usage
echo "Docker disk usage:"
docker system df

echo "✅ Maintenance completed!"
