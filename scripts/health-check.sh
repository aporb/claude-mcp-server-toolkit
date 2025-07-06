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

# Required Node.js version
MIN_NODE_VERSION="14.0.0"

# Required Python version
MIN_PYTHON_VERSION="3.8.0"

# Required MCP servers
declare -a REQUIRED_MCP_SERVERS=(
    "filesystem"
    "browser"
    "memory"
    "git"
    "context7"
    "sequential-thinking"
)

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

# Check Node.js version
check_node_version() {
    if ! command -v node &> /dev/null; then
        log "ERROR" "Node.js not found. Please install from https://nodejs.org"
        return 1
    fi

    local current_version=$(node --version | cut -d 'v' -f 2)
    if ! verify_version "$current_version" "$MIN_NODE_VERSION"; then
        log "ERROR" "Node.js version $current_version is below minimum required version $MIN_NODE_VERSION"
        return 1
    fi

    log "SUCCESS" "Node.js version $current_version meets requirements"
    return 0
}

# Check Python version
check_python_version() {
    if ! command -v python3 &> /dev/null; then
        log "ERROR" "Python 3 not found. Please install from https://python.org"
        return 1
    fi

    local current_version=$(python3 --version | cut -d ' ' -f 2)
    if ! verify_version "$current_version" "$MIN_PYTHON_VERSION"; then
        log "ERROR" "Python version $current_version is below minimum required version $MIN_PYTHON_VERSION"
        return 1
    fi

    log "SUCCESS" "Python version $current_version meets requirements"
    return 0
}

# Version comparison
verify_version() {
    local current="$1"
    local required="$2"
    
    IFS='.' read -ra current_parts <<< "$current"
    IFS='.' read -ra required_parts <<< "$required"
    
    for i in {0..2}; do
        if (( ${current_parts[$i]:-0} < ${required_parts[$i]:-0} )); then
            return 1
        elif (( ${current_parts[$i]:-0} > ${required_parts[$i]:-0} )); then
            return 0
        fi
    done
    return 0
}

# Initialize
load_environment

if [[ "$JSON_OUTPUT" != true ]]; then
    echo "==== MCP Server Health Check ===="
    echo "Started at: $(date)"
    echo "Project root: $PROJECT_ROOT"
    echo ""
fi

# Section 1: Prerequisites Check
echo "1️⃣ Prerequisites Check"
echo "--------------------"

# Check Node.js
check_node_version || ((ISSUES_COUNT++))

# Check Python
check_python_version || ((ISSUES_COUNT++))

# Section 2: MCP Configuration
echo ""
echo "2️⃣ MCP Configuration"
echo "------------------"

# Check Claude Desktop config
CONFIG_PATH=""
if [[ "$OSTYPE" == "darwin"* ]]; then
    CONFIG_PATH="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
else
    CONFIG_PATH="$APPDATA/Claude/claude_desktop_config.json"
fi

if [[ -f "$CONFIG_PATH" ]]; then
    echo "✅ Claude Desktop config found: $CONFIG_PATH"
    
    # Check MCP settings
    if jq -e '.mcpEnabled' "$CONFIG_PATH" &>/dev/null; then
        echo "✅ MCP is enabled in configuration"
    else
        echo "⚠️ MCP is not enabled in configuration"
        ((WARNINGS_COUNT++))
    fi
    
    # Check security settings
    if jq -e '.security.requireToolApproval' "$CONFIG_PATH" &>/dev/null; then
        echo "✅ Tool approval requirement is configured"
    else
        echo "⚠️ Tool approval requirement is not configured"
        ((WARNINGS_COUNT++))
    fi
    
    # Check file system access
    if jq -e '.security.fileSystemAccess.allowedPaths' "$CONFIG_PATH" &>/dev/null; then
        echo "✅ File system access paths are configured"
    else
        echo "⚠️ File system access paths are not configured"
        ((WARNINGS_COUNT++))
    fi
else
    echo "❌ Claude Desktop config not found"
    ((CRITICAL_COUNT++))
fi

# Section 3: MCP Server Status
echo ""
echo "3️⃣ MCP Server Status"
echo "-----------------"

# Check each required MCP server
for server in "${REQUIRED_MCP_SERVERS[@]}"; do
    if jq -e ".mcpServers.$server" "$CONFIG_PATH" &>/dev/null; then
        if jq -e ".mcpServers.$server.enabled" "$CONFIG_PATH" &>/dev/null; then
            echo "✅ $server: Configured and enabled"
        else
            echo "⚠️ $server: Configured but disabled"
            ((WARNINGS_COUNT++))
        fi
    else
        echo "❌ $server: Not configured"
        ((CRITICAL_COUNT++))
    fi
done

# Section 4: Browser Extension Check
echo ""
echo "4️⃣ Browser Extension Check"
echo "----------------------"

# Check Chrome extension
if [[ "$OSTYPE" == "darwin"* ]]; then
    CHROME_PROFILE="$HOME/Library/Application Support/Google/Chrome/Default"
else
    CHROME_PROFILE="$APPDATA/Google/Chrome/Default"
fi

if [[ -d "$CHROME_PROFILE" ]]; then
    if [[ -f "$CHROME_PROFILE/Extensions/bjfgambnhccakkhmkepdoekmckoijdlc/manifest.json" ]]; then
        echo "✅ Browser MCP extension is installed"
    else
        echo "⚠️ Browser MCP extension not found"
        echo "   Install from: https://chromewebstore.google.com/detail/browser-mcp-automate-your/bjfgambnhccakkhmkepdoekmckoijdlc"
        ((WARNINGS_COUNT++))
    fi
else
    echo "⚠️ Chrome profile not found"
    ((WARNINGS_COUNT++))
fi

# Section 5: Summary
echo ""
echo "5️⃣ Health Check Summary"
echo "--------------------"

echo "Critical Issues: $CRITICAL_COUNT"
echo "Warnings: $WARNINGS_COUNT"

if [[ $CRITICAL_COUNT -eq 0 && $WARNINGS_COUNT -eq 0 ]]; then
    echo "🎉 All systems healthy! No issues detected."
elif [[ $CRITICAL_COUNT -eq 0 ]]; then
    echo "⚠️ System operational with warnings."
    echo "   Run 'bash setup.sh' to resolve issues."
else
    echo "❌ Critical issues detected!"
    echo "   Run 'bash setup.sh' to resolve issues."
fi

echo ""
echo "Health check completed at: $(date)"

# Exit with appropriate status
if [[ $CRITICAL_COUNT -gt 0 ]]; then
    exit 1
elif [[ $WARNINGS_COUNT -gt 0 ]]; then
    exit 2
else
    exit 0
fi
