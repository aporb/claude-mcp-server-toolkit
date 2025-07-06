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

# =============================================================================
# Utility Functions
# =============================================================================

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

# Detect Claude Desktop configuration path
detect_config_path() {
    local paths=(
        "$HOME/.config/claude/claude_desktop_config.json"
        "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
        "$APPDATA/Claude/claude_desktop_config.json"
    )
    
    # Check environment variable override
    if [[ -n "$CLAUDE_DESKTOP_CONFIG_PATH" ]]; then
        CONFIG_PATH="${CLAUDE_DESKTOP_CONFIG_PATH/#\~/$HOME}"
        log_message "INFO" "Using custom config path: $CONFIG_PATH"
        return 0
    fi
    
    # Auto-detect based on OS
    for path in "${paths[@]}"; do
        local expanded_path="${path/#\~/$HOME}"
        local dir=$(dirname "$expanded_path")
        
        if [[ -f "$expanded_path" ]] || [[ -d "$dir" ]]; then
            CONFIG_PATH="$expanded_path"
            log_message "SUCCESS" "Detected Claude Desktop config path: $CONFIG_PATH"
            return 0
        fi
    done
    
    # Default to the most common path
    if [[ "$OSTYPE" == "darwin"* ]]; then
        CONFIG_PATH="$HOME/.config/claude/claude_desktop_config.json"
    else
        CONFIG_PATH="$HOME/.config/claude/claude_desktop_config.json"
    fi
    
    log_message "INFO" "Using default config path: $CONFIG_PATH"
    return 0
}

# Create configuration directory
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

# Backup existing configuration
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

# Load environment variables
load_environment() {
    if [[ -f "$PROJECT_ROOT/.env" ]]; then
        source "$PROJECT_ROOT/.env"
        log_message "SUCCESS" "Loaded environment from .env"
    else
        log_message "WARN" "No .env file found. Some configurations may be incomplete."
    fi
}

# Generate Claude Desktop MCP configuration
generate_mcp_config() {
    local config_json=$(cat << 'EOF'
{
  "mcpServers": {
    "atlassian": {
      "command": "docker",
      "args": [
        "run", "--rm", 
        "-e", "CONFLUENCE_URL", 
        "-e", "CONFLUENCE_USERNAME", 
        "-e", "CONFLUENCE_API_TOKEN",
        "-e", "JIRA_URL", 
        "-e", "JIRA_USERNAME", 
        "-e", "JIRA_API_TOKEN",
        "ghcr.io/pashpashpash/mcp-atlassian"
      ],
      "env": {
        "CONFLUENCE_URL": "${CONFLUENCE_URL:-}",
        "CONFLUENCE_USERNAME": "${CONFLUENCE_USERNAME:-}",
        "CONFLUENCE_API_TOKEN": "${CONFLUENCE_API_TOKEN:-}",
        "JIRA_URL": "${JIRA_URL:-}",
        "JIRA_USERNAME": "${JIRA_USERNAME:-}",
        "JIRA_API_TOKEN": "${JIRA_API_TOKEN:-}"
      }
    },
    "github": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "-e", "GITHUB_PERSONAL_ACCESS_TOKEN",
        "ghcr.io/github/github-mcp-server"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN:-}"
      }
    },
    "filesystem": {
      "command": "docker",
      "args": [
        "run", "--rm",
        "-v", "${HOME}:/mnt/home",
        "-v", "/tmp:/mnt/tmp",
        "npx", "-y", "@modelcontextprotocol/server-filesystem",
        "/mnt/home", "/mnt/tmp"
      ]
    },
    "git": {
      "command": "docker",
      "args": [
        "run", "--rm",
        "-v", "${PROJECT_ROOT}:/repo",
        "uvx", "mcp-server-git", "/repo"
      ]
    },
    "memory": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "-v", "${PROJECT_ROOT}/data/memory:/app/data",
        "npx", "-y", "@modelcontextprotocol/server-memory"
      ]
    },
    "browser-tools": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "npx", "@agentdeskai/browser-tools-mcp@latest"
      ]
    },
    "context7": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "npx", "-y", "@upstash/context7-mcp@latest"
      ]
    },
    "fetch": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "node", "/app/dist/index.js"
      ]
    },
    "sequential-thinking": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "npx", "-y", "@modelcontextprotocol/server-sequential-thinking"
      ]
    }
  }
}
EOF
)
    
    # Substitute environment variables
    config_json=$(envsubst <<< "$config_json")
    
    # Remove empty environment values
    config_json=$(echo "$config_json" | jq 'walk(if type == "object" then with_entries(select(.value != "")) else . end)')
    
    echo "$config_json"
}

# Write configuration file
write_config() {
    local config_content
    config_content=$(generate_mcp_config)
    
    if echo "$config_content" | jq empty 2>/dev/null; then
        echo "$config_content" | jq '.' > "$CONFIG_PATH"
        
        if [[ $? -eq 0 ]]; then
            log_message "SUCCESS" "Claude Desktop configuration written to: $CONFIG_PATH"
            
            # Set appropriate permissions
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

# Validate configuration
validate_config() {
    if [[ ! -f "$CONFIG_PATH" ]]; then
        log_message "ERROR" "Configuration file not found: $CONFIG_PATH"
        return 1
    fi
    
    # Validate JSON syntax
    if ! jq empty "$CONFIG_PATH" 2>/dev/null; then
        log_message "ERROR" "Configuration file contains invalid JSON"
        return 1
    fi
    
    # Check for required MCP servers
    local required_servers=("github" "filesystem" "memory")
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
    
    # Validate environment variables
    local missing_env=()
    
    if [[ -z "$GITHUB_PERSONAL_ACCESS_TOKEN" || "$GITHUB_PERSONAL_ACCESS_TOKEN" == "your_github_token_here" ]]; then
        missing_env+=("GITHUB_PERSONAL_ACCESS_TOKEN")
    fi
    
    if [[ ${#missing_env[@]} -gt 0 ]]; then
        log_message "WARN" "Missing environment variables: ${missing_env[*]}"
        log_message "INFO" "Update $PROJECT_ROOT/.env with your credentials"
    else
        log_message "SUCCESS" "Environment variables configured"
    fi
    
    return 0
}

# Show configuration summary
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
    
    # Count configured MCP servers
    if [[ -f "$CONFIG_PATH" ]]; then
        local server_count=$(jq '.mcpServers | keys | length' "$CONFIG_PATH" 2>/dev/null || echo "0")
        echo "  • MCP servers: $server_count configured"
        
        # List configured servers
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

# =============================================================================
# Main Execution
# =============================================================================

main() {
    print_color "$CYAN" "╔═══════════════════════════════════════════════════════╗"
    print_color "$CYAN" "║        Claude Desktop MCP Configuration v$SCRIPT_VERSION          ║"
    print_color "$CYAN" "╚═══════════════════════════════════════════════════════╝"
    echo ""
    
    # Load environment
    load_environment
    
    # Detect configuration path
    if ! detect_config_path; then
        exit 1
    fi
    
    # Create configuration directory
    if ! create_config_directory; then
        exit 1
    fi
    
    # Backup existing configuration
    if ! backup_existing_config; then
        exit 1
    fi
    
    # Write new configuration
    if ! write_config; then
        exit 1
    fi
    
    # Validate configuration
    validate_config
    
    # Show summary
    show_summary
    
    log_message "SUCCESS" "Claude Desktop configuration completed successfully!"
}

# Parse command line arguments
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
