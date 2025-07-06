#!/bin/bash

# =============================================================================
# Claude MCP Server Toolkit - VS Code/Cline Configuration
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
TASKS_CONFIG_PATH=""

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

# Detect VS Code/Cline configuration path
detect_config_path() {
    # VS Code/Cline uses workspace-specific configuration
    CONFIG_PATH="$PROJECT_ROOT/.vscode/mcp.json"
    TASKS_CONFIG_PATH="$PROJECT_ROOT/.vscode/tasks.json"
    
    # Check environment variable override
    if [[ -n "$VSCODE_CLINE_CONFIG_PATH" ]]; then
        CONFIG_PATH="${VSCODE_CLINE_CONFIG_PATH/#\~/$HOME}"
        log_message "INFO" "Using custom config path: $CONFIG_PATH"
    else
        log_message "INFO" "Using workspace config path: $CONFIG_PATH"
    fi
    
    return 0
}

# Check if Cline extension is installed
check_cline_extension() {
    if ! command -v code >/dev/null 2>&1; then
        log_message "WARN" "VS Code not found. Install VS Code first."
        return 1
    fi
    
    if ! code --list-extensions 2>/dev/null | grep -q "saoudrizwan.claude-dev"; then
        log_message "WARN" "Cline extension not installed in VS Code."
        log_message "INFO" "Install it from: https://marketplace.visualstudio.com/items?itemName=saoudrizwan.claude-dev"
        return 1
    fi
    
    local version=$(code --list-extensions --show-versions 2>/dev/null | grep "saoudrizwan.claude-dev" | cut -d'@' -f2 || echo "unknown")
    log_message "SUCCESS" "Cline extension found in VS Code (v$version)"
    return 0
}

# Create VS Code configuration directory
create_config_directory() {
    local config_dir=$(dirname "$CONFIG_PATH")
    
    if [[ ! -d "$config_dir" ]]; then
        if mkdir -p "$config_dir"; then
            log_message "SUCCESS" "Created VS Code config directory: $config_dir"
        else
            log_message "ERROR" "Failed to create VS Code config directory: $config_dir"
            return 1
        fi
    else
        log_message "INFO" "VS Code config directory exists: $config_dir"
    fi
    
    return 0
}

# Backup existing configuration
backup_existing_config() {
    if [[ -f "$CONFIG_PATH" ]]; then
        BACKUP_PATH="${CONFIG_PATH}.backup.$(date +%Y%m%d-%H%M%S)"
        
        if cp "$CONFIG_PATH" "$BACKUP_PATH"; then
            log_message "SUCCESS" "Backed up existing MCP config to: $BACKUP_PATH"
        else
            log_message "ERROR" "Failed to backup existing MCP config"
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

# Generate VS Code/Cline MCP configuration
generate_mcp_config() {
    local config_json=$(cat << 'EOF'
{
  "mcpServers": {
    "atlassian": {
      "command": "/Users/aporbanderwala/mcp-servers/mcp-atlassian/.venv/bin/python",
      "args": ["-c", "from mcp_atlassian import main; main()"],
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
        "run", "-i", "--rm", 
        "-e", "GITHUB_PERSONAL_ACCESS_TOKEN",
        "ghcr.io/github/github-mcp-server"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN:-}"
      }
    },
    "filesystem": {
      "command": "npx",
      "args": [
        "-y", "@modelcontextprotocol/server-filesystem",
        "${PROJECT_ROOT}", "${HOME}", "/tmp"
      ]
    },
    "git": {
      "command": "uvx",
      "args": [
        "mcp-server-git", "${PROJECT_ROOT}"
      ]
    },
    "memory": {
      "command": "npx",
      "args": [
        "-y", "@modelcontextprotocol/server-memory"
      ]
    },
    "browser-tools": {
      "command": "npx",
      "args": [
        "@agentdeskai/browser-tools-mcp@latest"
      ]
    },
    "context7": {
      "command": "npx",
      "args": [
        "-y", "@upstash/context7-mcp@latest"
      ]
    },
    "fetch": {
      "command": "node",
      "args": [
        "/Users/aporbanderwala/.mcp-servers/fetch-mcp/dist/index.js"
      ]
    },
    "sequential-thinking": {
      "command": "npx",
      "args": [
        "-y", "@modelcontextprotocol/server-sequential-thinking"
      ]
    }
  }
}
EOF
)
    
    # Substitute environment variables
    config_json=$(envsubst <<< "$config_json")
    
    # Remove empty environment values for cleaner config
    config_json=$(echo "$config_json" | jq 'walk(if type == "object" then with_entries(select(.value != "")) else . end)')
    
    echo "$config_json"
}

# Generate VS Code tasks configuration
generate_tasks_config() {
    local tasks_json=$(cat << 'EOF'
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Start MCP Servers",
            "type": "shell",
            "command": "bash",
            "args": ["${workspaceFolder}/vscode-integration/start-servers.sh"],
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared",
                "showReuseMessage": true,
                "clear": false
            },
            "problemMatcher": [],
            "detail": "Start all MCP servers for Claude integration"
        },
        {
            "label": "Health Check MCP",
            "type": "shell",
            "command": "bash",
            "args": ["${workspaceFolder}/scripts/health-check.sh"],
            "group": "test",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            },
            "problemMatcher": [],
            "detail": "Run health check on all MCP servers"
        },
        {
            "label": "Setup MCP Environment",
            "type": "shell",
            "command": "bash",
            "args": ["${workspaceFolder}/setup.sh"],
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": true,
                "panel": "shared"
            },
            "problemMatcher": [],
            "detail": "Run the complete MCP environment setup"
        },
        {
            "label": "Stop MCP Servers",
            "type": "shell",
            "command": "bash",
            "args": ["${workspaceFolder}/scripts/cleanup.sh"],
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            },
            "problemMatcher": [],
            "detail": "Stop all running MCP server containers"
        }
    ]
}
EOF
)
    
    echo "$tasks_json"
}

# Write configuration files
write_config() {
    # Write MCP configuration
    local mcp_config_content
    mcp_config_content=$(generate_mcp_config)
    
    if echo "$mcp_config_content" | jq empty 2>/dev/null; then
        echo "$mcp_config_content" | jq '.' > "$CONFIG_PATH"
        
        if [[ $? -eq 0 ]]; then
            log_message "SUCCESS" "VS Code MCP configuration written to: $CONFIG_PATH"
            chmod 644 "$CONFIG_PATH"
        else
            log_message "ERROR" "Failed to write MCP configuration file"
            return 1
        fi
    else
        log_message "ERROR" "Generated MCP configuration is not valid JSON"
        return 1
    fi
    
    # Write or update tasks configuration
    local tasks_config_content
    tasks_config_content=$(generate_tasks_config)
    
    if [[ -f "$TASKS_CONFIG_PATH" ]]; then
        # Backup existing tasks.json
        cp "$TASKS_CONFIG_PATH" "${TASKS_CONFIG_PATH}.backup.$(date +%Y%m%d-%H%M%S)"
        log_message "INFO" "Backed up existing tasks.json"
        
        # Merge with existing tasks (basic approach - replace our tasks)
        local existing_tasks=$(jq '.tasks // []' "$TASKS_CONFIG_PATH")
        local our_task_labels=("Start MCP Servers" "Health Check MCP" "Setup MCP Environment" "Stop MCP Servers")
        
        # Remove our existing tasks from the current file
        for label in "${our_task_labels[@]}"; do
            existing_tasks=$(echo "$existing_tasks" | jq --arg label "$label" 'map(select(.label != $label))')
        done
        
        # Add our new tasks
        local our_tasks=$(echo "$tasks_config_content" | jq '.tasks')
        local merged_tasks=$(echo "$existing_tasks $our_tasks" | jq -s 'add')
        
        # Create final tasks.json
        echo '{"version": "2.0.0"}' | jq --argjson tasks "$merged_tasks" '.tasks = $tasks' > "$TASKS_CONFIG_PATH"
    else
        # Create new tasks.json
        echo "$tasks_config_content" | jq '.' > "$TASKS_CONFIG_PATH"
    fi
    
    if [[ $? -eq 0 ]]; then
        log_message "SUCCESS" "VS Code tasks configuration written to: $TASKS_CONFIG_PATH"
        chmod 644 "$TASKS_CONFIG_PATH"
    else
        log_message "ERROR" "Failed to write tasks configuration file"
        return 1
    fi
    
    return 0
}

# Create VS Code workspace settings
create_workspace_settings() {
    local settings_path="$PROJECT_ROOT/.vscode/settings.json"
    local cline_settings=$(cat << 'EOF'
{
    "claude-dev.mcpEnabled": true,
    "claude-dev.mcpConfigPath": ".vscode/mcp.json",
    "claude-dev.autoStartMcpServers": true,
    "claude-dev.showMcpLogs": false,
    "files.exclude": {
        "**/.git": true,
        "**/node_modules": true,
        "**/.DS_Store": true,
        "**/logs": true
    },
    "search.exclude": {
        "**/node_modules": true,
        "**/logs": true,
        "**/.git": true
    }
}
EOF
)
    
    if [[ -f "$settings_path" ]]; then
        # Merge with existing settings
        local existing_settings=$(cat "$settings_path")
        local merged_settings=$(echo "$existing_settings $cline_settings" | jq -s '.[0] * .[1]')
        echo "$merged_settings" | jq '.' > "$settings_path"
        log_message "SUCCESS" "Updated VS Code workspace settings"
    else
        # Create new settings
        echo "$cline_settings" | jq '.' > "$settings_path"
        log_message "SUCCESS" "Created VS Code workspace settings"
    fi
}

# Validate configuration
validate_config() {
    if [[ ! -f "$CONFIG_PATH" ]]; then
        log_message "ERROR" "MCP configuration file not found: $CONFIG_PATH"
        return 1
    fi
    
    # Validate JSON syntax
    if ! jq empty "$CONFIG_PATH" 2>/dev/null; then
        log_message "ERROR" "MCP configuration file contains invalid JSON"
        return 1
    fi
    
    if [[ ! -f "$TASKS_CONFIG_PATH" ]]; then
        log_message "ERROR" "Tasks configuration file not found: $TASKS_CONFIG_PATH"
        return 1
    fi
    
    if ! jq empty "$TASKS_CONFIG_PATH" 2>/dev/null; then
        log_message "ERROR" "Tasks configuration file contains invalid JSON"
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
    print_color "$CYAN" "║            VS Code/Cline Configuration                ║"
    print_color "$CYAN" "╚═══════════════════════════════════════════════════════╝"
    echo ""
    
    log_message "INFO" "Configuration Summary:"
    echo "  • MCP config: $CONFIG_PATH"
    echo "  • Tasks config: $TASKS_CONFIG_PATH"
    echo "  • Workspace settings: $PROJECT_ROOT/.vscode/settings.json"
    
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
    
    # Count VS Code tasks
    if [[ -f "$TASKS_CONFIG_PATH" ]]; then
        local task_count=$(jq '.tasks | length' "$TASKS_CONFIG_PATH" 2>/dev/null || echo "0")
        echo "  • VS Code tasks: $task_count configured"
    fi
    
    echo ""
    log_message "INFO" "Next Steps:"
    echo "  1. Open this workspace in VS Code: code ."
    echo "  2. Install the Cline extension if not already installed"
    echo "  3. Use Ctrl+Shift+P -> 'Tasks: Run Task' -> 'Start MCP Servers'"
    echo "  4. Verify MCP servers are working in the Cline extension"
    echo "  5. Use 'Health Check MCP' task to validate setup"
    echo ""
    
    log_message "INFO" "VS Code Tasks Available:"
    echo "  • Start MCP Servers - Launch all MCP server containers"
    echo "  • Health Check MCP - Validate all services are running"
    echo "  • Setup MCP Environment - Run complete environment setup"
    echo "  • Stop MCP Servers - Clean shutdown of all containers"
    echo ""
    
    log_message "INFO" "Cline Extension Setup:"
    echo "  • Extension ID: saoudrizwan.claude-dev"
    echo "  • Marketplace: https://marketplace.visualstudio.com/items?itemName=saoudrizwan.claude-dev"
    echo "  • Documentation: https://github.com/saoudrizwan/claude-dev"
    echo ""
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    print_color "$CYAN" "╔═══════════════════════════════════════════════════════╗"
    print_color "$CYAN" "║        VS Code/Cline MCP Configuration v$SCRIPT_VERSION          ║"
    print_color "$CYAN" "╚═══════════════════════════════════════════════════════╝"
    echo ""
    
    # Check for Cline extension
    check_cline_extension
    
    # Load environment
    load_environment
    
    # Detect configuration path
    detect_config_path
    
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
    
    # Create workspace settings
    create_workspace_settings
    
    # Validate configuration
    validate_config
    
    # Show summary
    show_summary
    
    log_message "SUCCESS" "VS Code/Cline configuration completed successfully!"
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
    "check")
        check_cline_extension
        ;;
    "help"|"--help")
        echo "Usage: $0 [configure|validate|check|help]"
        echo ""
        echo "Commands:"
        echo "  configure - Generate VS Code/Cline MCP configuration (default)"
        echo "  validate  - Validate existing configuration"
        echo "  check     - Check if Cline extension is installed"
        echo "  help      - Show this help message"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information."
        exit 1
        ;;
esac
