#!/bin/bash

# =============================================================================
# MCP Server Health Check Script
# =============================================================================
# Purpose: Comprehensive health check for MCP server infrastructure
# Usage: bash scripts/health-check.sh [--verbose] [--json] [--fix]
# Exit Codes:
#   0 - All systems healthy
#   1 - Critical issues detected
#   2 - Warning issues detected
#   3 - Configuration errors
#   4 - Network connectivity issues
# =============================================================================

# Strict error handling
set -euo pipefail

# Trap for cleanup on script termination
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 && $exit_code -ne 2 ]]; then
        echo "❌ Health check failed at line $1 with exit code $exit_code" >&2
    fi
}
trap 'cleanup $LINENO' EXIT ERR

# Global variables
VERBOSE=false
JSON_OUTPUT=false
AUTO_FIX=false
ISSUES_COUNT=0
WARNINGS_COUNT=0
CRITICAL_COUNT=0

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  
            echo "[$timestamp] ℹ️  $message"
            [[ "$VERBOSE" == true ]] && echo "[$timestamp] ℹ️  $message" >&2
            ;;
        "WARN")  
            echo "[$timestamp] ⚠️  $message" >&2
            ((WARNINGS_COUNT++))
            ;;
        "ERROR") 
            echo "[$timestamp] ❌ $message" >&2
            ((CRITICAL_COUNT++))
            ;;
        "SUCCESS") 
            echo "[$timestamp] ✅ $message"
            ;;
        "DEBUG") 
            [[ "$VERBOSE" == true ]] && echo "[$timestamp] 🐛 $message" >&2
            ;;
        *) echo "[$timestamp] $message" ;;
    esac
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --fix)
            AUTO_FIX=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--verbose] [--json] [--fix]"
            echo "  --verbose  Enable verbose output"
            echo "  --json     Output results in JSON format"
            echo "  --fix      Automatically fix issues where possible"
            echo "  --help     Show this help message"
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
    exit 3
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
        exit 3
    fi
}

# Initialize
load_environment

if [[ "$JSON_OUTPUT" != true ]]; then
    echo "==== MCP Server Health Check (Multi-Platform Strategy) ===="
    echo "Started at: $(date)"
    echo "Project root: $PROJECT_ROOT"
    echo ""
fi

# Function to check Docker health
check_docker_health() {
    log "INFO" "Checking Docker Engine health..."
    
    # Check if Docker command exists
    if ! command -v docker &> /dev/null; then
        log "ERROR" "Docker command not found. Please install Docker."
        return 1
    fi
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        log "ERROR" "Docker is not running! Please start Docker before proceeding."
        if [[ "$AUTO_FIX" == true ]]; then
            log "INFO" "Attempting to start Docker..."
            if command -v open &> /dev/null; then
                open -a Docker 2>/dev/null || log "WARN" "Could not auto-start Docker Desktop"
            fi
        fi
        return 1
    fi
    
    local docker_version
    if docker_version=$(docker --version 2>/dev/null); then
        log "SUCCESS" "Docker is running: $docker_version"
    else
        log "WARN" "Docker is running but version check failed"
    fi
    
    # Check Docker system health
    log "DEBUG" "Checking Docker system health..."
    if docker info | grep -E "Containers:|Running:|Paused:|Stopped:|Images:" > /dev/null 2>&1; then
        if [[ "$VERBOSE" == true ]]; then
            echo "Docker System Health:"
            docker info | grep -E "Containers:|Running:|Paused:|Stopped:|Images:"
        fi
        log "SUCCESS" "Docker system health check passed"
    else
        log "WARN" "Could not retrieve Docker system information"
    fi
    
    return 0
}

# Section 2: Required Docker Images
echo ""
echo "2️⃣ Docker Images Verification"
echo "----------------------------"

# Define required images
declare -a required_images=(
  "ghcr.io/github/github-mcp-server"
  "mcp/atlassian"
  "mcp/server-filesystem"
  "mcp/server/git"
  "mcp/server-memory"
  "mcp/browser-tools-mcp"
  "zcaceres/fetch-mcp"
)

# Check custom build images
declare -a custom_images=(
  "context7-mcp"
  "mcp/sequentialthinking"
  "memory-bank-mcp:local"
)

# Check required images
for image in "${required_images[@]}"; do
  if docker image inspect "$image" > /dev/null 2>&1; then
    echo "✅ $image: Available"
  else
    echo "❌ $image: Missing (will be pulled during startup)"
  fi
done

# Check custom build images
echo ""
echo "Custom Build Images:"
for image in "${custom_images[@]}"; do
  if docker image inspect "$image" > /dev/null 2>&1; then
    echo "✅ $image: Available"
  else
    echo "❌ $image: Missing (requires build)"
  fi
done

# Section 3: Running Docker Containers
echo ""
echo "3️⃣ Docker Container Status"
echo "-------------------------"

# Check for running MCP containers
echo "Running MCP Containers:"
docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}" | grep -E 'mcp|github'

# Check for GitHub MCP container specifically
GITHUB_CONTAINER=$(docker ps --filter ancestor=ghcr.io/github/github-mcp-server --format "{{.ID}}" | head -n1)
if [ -n "$GITHUB_CONTAINER" ]; then
  echo "✅ GitHub MCP container running: $GITHUB_CONTAINER"
  
  # Verify it's properly referenced in the connector script
  SCRIPT_CONTAINER_ID=$(grep "CONTAINER_ID=" "$PROJECT_ROOT/scripts/github-mcp-connector.sh" | cut -d'"' -f2)
  if [ "$SCRIPT_CONTAINER_ID" != "$GITHUB_CONTAINER" ]; then
    echo "⚠️ Container ID mismatch in github-mcp-connector.sh"
    echo "   Script has: $SCRIPT_CONTAINER_ID"
    echo "   Current container: $GITHUB_CONTAINER"
    echo "   Run: bash scripts/setup.sh to update"
  else
    echo "✅ Connector script references correct container ID"
  fi
else
  echo "⚠️ No GitHub MCP container running"
fi

# Section 4: Environment and Config
echo ""
echo "4️⃣ Environment and Configuration"
echo "------------------------------"

# Check if required directories exist
for dir in "$PROJECT_ROOT/data/memory-bank" "$PROJECT_ROOT/data/knowledge-graph" "$PROJECT_ROOT/logs"; do
  if [ -d "$dir" ]; then
    permissions=$(stat -f "%A" "$dir")
    echo "✅ Directory $dir exists (permissions: $permissions)"
  else
    echo "⚠️ Required directory $dir doesn't exist. Creating..."
    mkdir -p "$dir"
  fi
done

# Check environment variables
if [ -z "$GITHUB_PERSONAL_ACCESS_TOKEN" ] || [ "$GITHUB_PERSONAL_ACCESS_TOKEN" == "your_github_token_here" ]; then
  echo "⚠️ GITHUB_PERSONAL_ACCESS_TOKEN is not set or is set to default!"
  echo "Please update $PROJECT_ROOT/.env with your token."
else
  echo "✅ GITHUB_PERSONAL_ACCESS_TOKEN is set"
fi

# Check config file permissions
if [ -f "$PROJECT_ROOT/config/config.sh" ]; then
  permissions=$(stat -f "%A" "$PROJECT_ROOT/config/config.sh")
  if [ "$permissions" != "600" ]; then
    echo "⚠️ config.sh has loose permissions: $permissions (should be 600)"
  else
    echo "✅ config.sh has correct permissions"
  fi
fi

# Section 5: Network Connectivity
echo ""
echo "5️⃣ Network Connectivity"
echo "---------------------"

# Check internet connectivity
echo "Testing internet connectivity..."
if ! curl -s --connect-timeout 5 https://api.github.com > /dev/null; then
  echo "⚠️ Internet connectivity issue detected. Check your network connection."
  exit 1
else
  echo "✅ Internet connection working"
fi

# Docker Hub connectivity
echo "Testing Docker Hub connectivity..."
if ! curl -s --connect-timeout 5 https://registry.hub.docker.com/v2/ > /dev/null; then
  echo "⚠️ Docker Hub connectivity issue detected. Pull operations may fail."
else
  echo "✅ Docker Hub connection working"
fi

# GitHub API connectivity
echo "Testing GitHub API connectivity..."
if [ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ] && [ "$GITHUB_PERSONAL_ACCESS_TOKEN" != "your_github_token_here" ]; then
  if ! curl -s --connect-timeout 5 -H "Authorization: token $GITHUB_PERSONAL_ACCESS_TOKEN" https://api.github.com/user > /dev/null; then
    echo "⚠️ GitHub API connectivity issue detected. Check your token and network."
  else
    echo "✅ GitHub API connection working"
  fi
fi

# Section 6: MCP Configuration
echo ""
echo "6️⃣ MCP Server Configuration"
echo "-------------------------"

# Check if MCP servers are configured
if claude mcp list 2>/dev/null | grep -q "No MCP servers configured"; then
  echo "⚠️ No MCP servers are currently configured with Claude."
  echo "Run the VS Code integration script to configure them:"
  echo "bash $PROJECT_ROOT/vscode-integration/start-servers.sh"
else
  echo "✅ Claude has MCP servers configured:"
  claude mcp list
fi

# Section 7: Summary and Recommendations
echo ""
echo "7️⃣ Health Check Summary"
echo "---------------------"

# Count of actual issues
ISSUES=0

# Docker not running would have exited earlier
echo "✅ Docker Engine: Running"

# Check for missing images
MISSING_IMAGES=0
for image in "${required_images[@]}" "${custom_images[@]}"; do
  if ! docker image inspect "$image" > /dev/null 2>&1; then
    MISSING_IMAGES=$((MISSING_IMAGES+1))
  fi
done

if [ $MISSING_IMAGES -gt 0 ]; then
  echo "⚠️ Docker Images: $MISSING_IMAGES missing"
  ISSUES=$((ISSUES+1))
else
  echo "✅ Docker Images: All available"
fi

# Check for GitHub container
if [ -z "$GITHUB_CONTAINER" ]; then
  echo "⚠️ GitHub Container: Not running"
  ISSUES=$((ISSUES+1))
else
  echo "✅ GitHub Container: Running"
fi

# Check for MCP configuration
if claude mcp list 2>/dev/null | grep -q "No MCP servers configured"; then
  echo "⚠️ MCP Configuration: Not configured"
  ISSUES=$((ISSUES+1))
else
  echo "✅ MCP Configuration: Configured"
fi

# Check environment variables
if [ -z "$GITHUB_PERSONAL_ACCESS_TOKEN" ] || [ "$GITHUB_PERSONAL_ACCESS_TOKEN" == "your_github_token_here" ]; then
  echo "⚠️ Environment: Missing GitHub token"
  ISSUES=$((ISSUES+1))
else
  echo "✅ Environment: Configured"
fi

echo ""
if [ $ISSUES -eq 0 ]; then
  echo "🎉 All systems healthy! No issues detected."
else
  echo "⚠️ $ISSUES issue(s) detected. See detailed output above."
  echo "   Run 'bash setup.sh' to resolve common issues."
fi

echo ""
echo "Health check completed at: $(date)"
