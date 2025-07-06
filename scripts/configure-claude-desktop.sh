#!/bin/bash

# =============================================================================
# Claude MCP Server Toolkit - Claude Desktop Configuration
# Version: 2.0.0
# =============================================================================

# Script configuration
readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors and formatting
readonly NC='\033[0m'
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'

# Unicode symbols
readonly CHECK_MARK="✓"
readonly CROSS_MARK="✗"
readonly WARNING_SIGN="⚠"
readonly INFO_SIGN="ℹ"

# Configuration paths
CONFIG_PATH=""
BACKUP_PATH=""

# Security settings
readonly DEFAULT_PERMISSIONS="600"
readonly MCP_ENABLED_BY_DEFAULT="false"

# Node.js requirements
readonly MIN_NODE_VERSION="14.0.0"
readonly REQUIRED_NPM_PACKAGES=(
    "@modelcontextprotocol/server-filesystem"
    "@browsermcp/mcp"
    "@modelcontextprotocol/server-memory"
    "@modelcontextprotocol/server-git"
    "@upstash/context7-mcp"
    "@modelcontextprotocol/server-sequential-thinking"
)

# MCP server configuration
readonly MCP_SERVERS=(
    "filesystem"
    "browser"
    "memory"
    "git"
    "context7"
    "sequential-thinking"
)

# MCP server permissions (default: disabled)
declare -A MCP_SERVER_ENABLED
for server in "${MCP_SERVERS[@]}"; do
    MCP_SERVER_ENABLED[$server]="$MCP_ENABLED_BY_DEFAULT"
done

# =============================================================================
# Utility Functions
# =============================================================================

check_node_version() {
    if ! command -v node >/dev/null 2>&1; then
        log_message "ERROR" "Node.js is not installed. Please install Node.js from https://nodejs.org"
        return 1
    fi

    local current_version=$(node --version | cut -d 'v' -f 2)
    if ! verify_version "$current_version" "$MIN_NODE_VERSION"; then
        log_message "ERROR" "Node.js version $current_version is below minimum required version $MIN_NODE_VERSION"
        return 1
    fi

    log_message "SUCCESS" "Node.js version $current_version meets requirements"
    return 0
}

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

check_npm_packages() {
    local missing_packages=()
    
    for package in "${REQUIRED_NPM_PACKAGES[@]}"; do
        if ! npm list -g "$package" >/dev/null 2>&1; then
            missing_packages+=("$package")
        fi
    done
    
    if [ ${#missing_packages[@]} -gt 0 ]; then
        log_message "INFO" "Installing required npm packages: ${missing_packages[*]}"
        for package in "${missing_packages[@]}"; do
            if ! npm install -g "$package"; then
                log_message "ERROR" "Failed to install $package"
                return 1
            fi
        done
    fi
    
    log_message "SUCCESS" "All required npm packages are installed"
    return 0
}

print_color() {
    local color="$1"
    shift
    echo -e "${color}$*${NC}"
}

log_message() {
    local level="$1"
    shift
    local message="$*"
    
    case "$level" in
        "SUCCESS") echo -e "${GREEN}${CHECK_MARK} $message${NC}" ;;
        "ERROR") echo -e "${RED}${CROSS_MARK} $message${NC}" ;;
        "WARN") echo -e "${YELLOW}${WARNING_SIGN} $message${NC}" ;;
        "INFO") echo -e "${BLUE}${INFO_SIGN} $message${NC}" ;;
        *) echo "$message" ;;
    esac
}

# =============================================================================
# Configuration Functions
# =============================================================================

detect_config_path() {
    local paths=(
        "$HOME/.config/claude/claude_desktop_config.json"
        "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
        "$APPDATA/Claude/claude_desktop_config.json"
    )
    
    if [[ -n "$CLAUDE_DESKTOP_CONFIG_PATH" ]]; then
        CONFIG_PATH="${CLAUDE_DESKTOP_CONFIG_PATH/#\~/$HOME}"
        log_message "INFO" "Using custom config path: $CONFIG_PATH"
        return 0
    fi
    
    for path in "${paths[@]}"; do
        local expanded_path="${path/#\~/$HOME}"
        local dir=$(dirname "$expanded_path")
        
        if [[ -f "$expanded_path" ]] || [[ -d "$dir" ]]; then
            CONFIG_PATH="$expanded_path"
            log_message "SUCCESS" "Detected Claude Desktop config path: $CONFIG_PATH"
            return 0
        fi
    done
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        CONFIG_PATH="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
    else
        CONFIG_PATH="$APPDATA/Claude/claude_desktop_config.json"
    fi
    
    log_message "INFO" "Using default config path: $CONFIG_PATH"
    return 0
}

create_config_directory() {
    local config_dir=$(dirname "$CONFIG_PATH")
    
    if [[ ! -d "$config_dir" ]]; then
        if mkdir -p "$config_dir"; then
            log_message "SUCCESS" "Created config directory: $config_dir"
        else
            log_message "ERROR" "Failed to create config directory: $config_dir"
            return 1
        fi
    else
        log_message "INFO" "Config directory exists: $config_dir"
    fi
    
    return 0
}

backup_existing_config() {
    if [[ -f "$CONFIG_PATH" ]]; then
        BACKUP_PATH="${CONFIG_PATH}.backup.$(date +%Y%m%d-%H%M%S)"
        
        if cp "$CONFIG_PATH" "$BACKUP_PATH"; then
            log_message "SUCCESS" "Backed up existing config to: $BACKUP_PATH"
        else
            log_message "ERROR" "Failed to backup existing config"
            return 1
        fi
    fi
    
    return 0
}

load_environment() {
    if [[ -f "$PROJECT_ROOT/.env" ]]; then
        source "$PROJECT_ROOT/.env"
        log_message "SUCCESS" "Loaded environment from .env"
    else
        log_message "WARN" "No .env file found. Some configurations may be incomplete."
    fi
}

generate_mcp_config() {
    local home_dir="${HOME/#\~/$HOME}"
    local desktop_dir="$home_dir/Desktop"
    local downloads_dir="$home_dir/Downloads"
    local documents_dir="$home_dir/Documents"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        CONFIG_DIR="$home_dir/Library/Application Support/Claude"
        LOG_DIR="$home_dir/Library/Logs/Claude"
    else
        CONFIG_DIR="$APPDATA/Claude"
        LOG_DIR="$APPDATA/Claude/logs"
    fi

    local config_json=$(cat << EOF
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "$desktop_dir",
        "$downloads_dir",
        "$documents_dir"
      ]
    },
    "browser": {
      "command": "npx",
      "args": [
        "-y",
        "@browsermcp/mcp"
      ]
    },
    "memory": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-memory"
      ]
    },
    "git": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-git"
      ]
    },
    "context7": {
      "command": "npx",
      "args": [
        "-y",
        "@upstash/context7-mcp@latest"
      ]
    },
    "sequential-thinking": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-sequential-thinking"
      ]
    }
  }
}
EOF
)
    
    config_json=$(envsubst <<< "$config_json")
    config_json=$(echo "$config_json" | jq 'walk(if type == "object" then with_entries(select(.value != "")) else . end)')
    
    echo "$config_json"
}

write_config() {
    local config_content
    config_content=$(generate_mcp_config)
    
    if echo "$config_content" | jq empty 2>/dev/null; then
        echo "$config_content" | jq '.' > "$CONFIG_PATH"
        
        if [[ $? -eq 0 ]]; then
            log_message "SUCCESS" "Claude Desktop configuration written to: $CONFIG_PATH"
            chmod 600 "$CONFIG_PATH"
            log_message "SUCCESS" "Set secure permissions (600) on config file"
            return 0
        else
            log_message "ERROR" "Failed to write configuration file"
            return 1
        fi
    else
        log_message "ERROR" "Generated configuration is not valid JSON"
        return 1
    fi
}

validate_config() {
    if [[ ! -f "$CONFIG_PATH" ]]; then
        log_message "ERROR" "Configuration file not found: $CONFIG_PATH"
        return 1
    fi
    
    if ! jq empty "$CONFIG_PATH" 2>/dev/null; then
        log_message "ERROR" "Configuration file contains invalid JSON"
        return 1
    fi
    
    local required_servers=("filesystem")
    local missing_servers=()
    
    for server in "${required_servers[@]}"; do
        if ! jq -e ".mcpServers.${server}" "$CONFIG_PATH" >/dev/null; then
            missing_servers+=("$server")
        fi
    done
    
    if [[ ${#missing_servers[@]} -gt 0 ]]; then
        log_message "WARN" "Missing MCP servers: ${missing_servers[*]}"
    else
        log_message "SUCCESS" "All required MCP servers configured"
    fi
    
    return 0
}

enable_mcp_server() {
    local server="$1"
    if [[ " ${MCP_SERVERS[@]} " =~ " ${server} " ]]; then
        MCP_SERVER_ENABLED[$server]="true"
        log_message "SUCCESS" "Enabled MCP server: $server"
        return 0
    else
        log_message "ERROR" "Unknown MCP server: $server"
        return 1
    fi
}

show_summary() {
    echo ""
    print_color "$CYAN" "╔═══════════════════════════════════════════════════════╗"
    print_color "$CYAN" "║           Claude Desktop Configuration                ║"
    print_color "$CYAN" "╚═══════════════════════════════════════════════════════╝"
    echo ""
    
    log_message "INFO" "Configuration Summary:"
    echo "  • Config file: $CONFIG_PATH"
    
    if [[ -n "$BACKUP_PATH" ]]; then
        echo "  • Backup file: $BACKUP_PATH"
    fi
    
    if [[ -f "$CONFIG_PATH" ]]; then
        local server_count=$(jq '.mcpServers | keys | length' "$CONFIG_PATH" 2>/dev/null || echo "0")
        echo "  • MCP servers: $server_count configured"
        
        local servers=$(jq -r '.mcpServers | keys[]' "$CONFIG_PATH" 2>/dev/null)
        if [[ -n "$servers" ]]; then
            echo "  • Available servers:"
            while IFS= read -r server; do
                echo "    - $server"
            done <<< "$servers"
        fi
    fi
    
    echo ""
    log_message "INFO" "Next Steps:"
    echo "  1. Restart Claude Desktop to load the new configuration"
    echo "  2. Verify MCP servers are working in Claude Desktop"
    echo "  3. Update environment variables in $PROJECT_ROOT/.env if needed"
    echo ""
}

main() {
    print_color "$CYAN" "╔═══════════════════════════════════════════════════════╗"
    print_color "$CYAN" "║        Claude Desktop MCP Configuration v$SCRIPT_VERSION          ║"
    print_color "$CYAN" "╚═══════════════════════════════════════════════════════╝"
    echo ""
    
    if ! check_node_version; then
        exit 1
    fi

    if ! check_npm_packages; then
        exit 1
    fi
    
    load_environment
    
    if ! detect_config_path; then
        exit 1
    fi
    
    if ! create_config_directory; then
        exit 1
    fi
    
    if ! backup_existing_config; then
        exit 1
    fi
    
    if ! write_config; then
        exit 1
    fi
    
    validate_config
    show_summary
    
    log_message "SUCCESS" "Claude Desktop configuration completed successfully!"
}

case "${1:-configure}" in
    "configure")
        main
        ;;
    "validate")
        load_environment
        detect_config_path
        validate_config
        ;;
    "help"|"--help")
        echo "Usage: $0 [configure|validate|help]"
        echo ""
        echo "Commands:"
        echo "  configure - Generate Claude Desktop MCP configuration (default)"
        echo "  validate  - Validate existing configuration"
        echo "  help      - Show this help message"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information."
        exit 1
        ;;
esac
