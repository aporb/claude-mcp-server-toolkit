#!/bin/bash

# =============================================================================
# Claude MCP Server Toolkit - Professional Setup Script
# Version: 2.0.0
# =============================================================================

# Script configuration
readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
readonly PROJECT_ROOT="$SCRIPT_DIR"
readonly LOG_DIR="$PROJECT_ROOT/logs"
readonly LOG_FILE="$LOG_DIR/setup-$(date +%Y%m%d-%H%M%S).log"

# Color codes
readonly NC='\033[0m'       # No Color
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'

# Unicode symbols
readonly CHECK_MARK="✓"
readonly CROSS_MARK="✗"
readonly WARNING_SIGN="⚠"
readonly INFO_SIGN="ℹ"
readonly ARROW="→"
readonly SPINNER_FRAMES=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)

# Global variables
QUIET_MODE=false
VERBOSE_MODE=false
DRY_RUN=false
NO_COLOR=false
SKIP_HEALTH_CHECK=false
AUTO_BUILD=false
TOTAL_STEPS=7
CURRENT_STEP=0
START_TIME=$(date +%s)

# Spinner PID
SPINNER_PID=""

# =============================================================================
# Utility Functions
# =============================================================================

# Initialize logging
init_logging() {
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"
    exec 3>&1 4>&2
    exec 1> >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$LOG_FILE" >&2)
}

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    if [[ "$QUIET_MODE" == "true" && "$level" != "ERROR" ]]; then
        return
    fi
    
    case "$level" in
        ERROR)
            echo -e "${RED}${CROSS_MARK} $message${NC}" >&3
            ;;
        WARN)
            echo -e "${YELLOW}${WARNING_SIGN} $message${NC}" >&3
            ;;
        SUCCESS)
            echo -e "${GREEN}${CHECK_MARK} $message${NC}" >&3
            ;;
        INFO)
            echo -e "${BLUE}${INFO_SIGN} $message${NC}" >&3
            ;;
        DEBUG)
            if [[ "$VERBOSE_MODE" == "true" ]]; then
                echo -e "${DIM}[DEBUG] $message${NC}" >&3
            fi
            ;;
        *)
            echo "$message" >&3
            ;;
    esac
}

# Print colored text
print_color() {
    local color="$1"
    shift
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "$*" >&3
    else
        echo -e "${color}$*${NC}" >&3
    fi
}

# Show spinner
start_spinner() {
    local message="$1"
    if [[ "$QUIET_MODE" == "true" || "$VERBOSE_MODE" == "true" ]]; then
        return
    fi
    
    (
        while true; do
            for frame in "${SPINNER_FRAMES[@]}"; do
                echo -ne "\r${BLUE}$frame${NC} $message" >&3
                sleep 0.1
            done
        done
    ) &
    SPINNER_PID=$!
}

# Stop spinner
stop_spinner() {
    if [[ -n "$SPINNER_PID" ]]; then
        kill "$SPINNER_PID" 2>/dev/null
        wait "$SPINNER_PID" 2>/dev/null
        SPINNER_PID=""
        echo -ne "\r\033[K" >&3  # Clear the line
    fi
}

# Show progress
show_progress() {
    local current="$1"
    local total="$2"
    local width=20
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    echo -ne "\r["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    echo -ne "] $current/$total Steps Complete ($percentage%)" >&3
}

# Print banner
print_banner() {
    clear
    print_color "$CYAN" "╔═══════════════════════════════════════════════════════╗"
    print_color "$CYAN" "║       ${BOLD}Claude MCP Server Toolkit Setup v${SCRIPT_VERSION}${NC}${CYAN}          ║"
    print_color "$CYAN" "║          Docker-First Strategy Implementation         ║"
    print_color "$CYAN" "╚═══════════════════════════════════════════════════════╝"
    echo ""
}

# Print usage
print_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Setup Claude MCP Server Toolkit with Docker-first strategy

Options:
  -h, --help              Show this help message
  -v, --version           Show version information
  -q, --quiet             Minimal output (errors only)
  -V, --verbose           Detailed output with debug info
  --dry-run               Show what would be done without executing
  --skip-health-check     Skip the health check step
  --auto-build            Automatically build missing custom images
  --no-color              Disable colored output
  --log-file <path>       Custom log file location

Examples:
  $0                      Run interactive setup
  $0 --auto-build         Run setup and auto-build missing images
  $0 --dry-run            Preview setup steps without execution

For more information, see README.md
EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                print_usage
                exit 0
                ;;
            -v|--version)
                echo "Claude MCP Server Toolkit Setup v${SCRIPT_VERSION}"
                exit 0
                ;;
            -q|--quiet)
                QUIET_MODE=true
                shift
                ;;
            -V|--verbose)
                VERBOSE_MODE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --skip-health-check)
                SKIP_HEALTH_CHECK=true
                shift
                ;;
            --auto-build)
                AUTO_BUILD=true
                shift
                ;;
            --no-color)
                NO_COLOR=true
                shift
                ;;
            --log-file)
                LOG_FILE="$2"
                shift 2
                ;;
            *)
                log ERROR "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done
}

# =============================================================================
# Setup Functions
# =============================================================================

# Check system requirements
check_system_requirements() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo ""
    print_color "$BOLD" "[$CURRENT_STEP/$TOTAL_STEPS] Checking System Requirements..."
    
    local all_good=true
    
    # Check OS
    local os_name=$(uname -s)
    local os_version=$(uname -r)
    log INFO "Operating System: $os_name $os_version"
    echo -n "  "
    log SUCCESS "Operating System: $os_name (supported)"
    
    # Check Docker
    echo -n "  "
    if ! command -v docker &> /dev/null; then
        log ERROR "Docker: Not installed"
        all_good=false
        echo ""
        print_color "$RED" "This setup requires Docker Desktop to be running."
        echo ""
        echo "To fix this:"
        echo "1. Install Docker Desktop: https://docker.com/products/docker-desktop"
        echo "2. Start Docker Desktop"
        echo "3. Run this setup again"
        echo ""
        if [[ "$os_name" == "Darwin" ]]; then
            read -p "Would you like to open the Docker Desktop download page? (Y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                open "https://docker.com/products/docker-desktop"
            fi
        fi
        return 1
    fi
    
    if ! docker info &> /dev/null; then
        log ERROR "Docker Desktop: Installed but not running"
        all_good=false
        echo ""
        print_color "$RED" "Docker Desktop is installed but not running."
        echo ""
        echo "To fix this:"
        if [[ "$os_name" == "Darwin" ]]; then
            echo "1. Open Docker Desktop application"
            echo "2. Wait for it to fully start"
            echo "3. Run this setup again"
            echo ""
            read -p "Would you like to open Docker Desktop now? (Y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                open -a Docker
                echo "Waiting for Docker to start..."
                sleep 5
                # Try again
                if docker info &> /dev/null; then
                    log SUCCESS "Docker Desktop: Started successfully"
                    all_good=true
                fi
            fi
        else
            echo "1. Start Docker service: sudo systemctl start docker"
            echo "2. Run this setup again"
        fi
        
        if [[ "$all_good" == "false" ]]; then
            return 1
        fi
    else
        local docker_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "unknown")
        log SUCCESS "Docker Desktop: $docker_version (running)"
    fi
    
    # Check disk space
    echo -n "  "
    local available_space
    if [[ "$os_name" == "Darwin" ]]; then
        available_space=$(df -h / | awk 'NR==2 {print $4}')
    else
        available_space=$(df -h / | awk 'NR==2 {print $4}')
    fi
    log SUCCESS "Available Disk Space: $available_space"
    
    # Check internet connection
    echo -n "  "
    start_spinner "Checking internet connection..."
    if ping -c 1 github.com &> /dev/null; then
        stop_spinner
        echo -n "  "
        log SUCCESS "Internet Connection: Active"
    else
        stop_spinner
        echo -n "  "
        log WARN "Internet Connection: Limited (some features may not work)"
    fi
    
    echo ""
    if [[ "$all_good" == "true" ]]; then
        log INFO "All prerequisites met. Ready to proceed."
    fi
    
    return 0
}

# Setup configuration
setup_configuration() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo ""
    print_color "$BOLD" "[$CURRENT_STEP/$TOTAL_STEPS] Setting Up Configuration..."
    echo ""
    
    print_color "$BLUE" "  ${INFO_SIGN} Configuration Status:"
    
    # Check .env file
    if [ -f "$PROJECT_ROOT/.env" ]; then
        echo "  ├─ .env file: Found"
        log DEBUG ".env file exists"
        
        # Check if it has placeholder values
        if grep -q "your_github_token_here" "$PROJECT_ROOT/.env" 2>/dev/null; then
            echo "  └─ Status: Contains placeholder values"
            echo ""
            print_color "$YELLOW" "  ${WARNING_SIGN} ACTION REQUIRED:"
            echo "  Your .env file contains placeholder values."
            echo ""
            read -p "  Would you like to update your credentials now? (Y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                configure_credentials
            fi
        else
            echo "  └─ Status: Configured"
        fi
    else
        echo "  ├─ .env file: Not found"
        if [ -f "$PROJECT_ROOT/.env.template" ]; then
            echo "  └─ Creating from template..."
            
            if [[ "$DRY_RUN" == "true" ]]; then
                log INFO "[DRY RUN] Would copy .env.template to .env"
            else
                cp "$PROJECT_ROOT/.env.template" "$PROJECT_ROOT/.env"
                chmod 600 "$PROJECT_ROOT/.env"
                log SUCCESS "Created .env file from template"
            fi
            
            echo ""
            print_color "$YELLOW" "  ${WARNING_SIGN} ACTION REQUIRED:"
            echo "  Please provide your API credentials:"
            echo ""
            configure_credentials
        else
            log ERROR "Neither .env nor .env.template found!"
            return 1
        fi
    fi
    
    # Create required directories
    echo ""
    echo "  Creating required directories..."
    local dirs=("logs" "data/memory-bank" "data/knowledge-graph" "config")
    for dir in "${dirs[@]}"; do
        if [[ "$DRY_RUN" == "true" ]]; then
            log INFO "[DRY RUN] Would create directory: $PROJECT_ROOT/$dir"
        else
            mkdir -p "$PROJECT_ROOT/$dir"
            log DEBUG "Created directory: $dir"
        fi
    done
    echo -n "  "
    log SUCCESS "Created required directories"
    
    # Sync environment to config
    echo -n "  "
    if [[ "$DRY_RUN" == "true" ]]; then
        log INFO "[DRY RUN] Would sync .env to config/config.sh"
    else
        bash "$PROJECT_ROOT/scripts/sync-env-to-config.sh" > /dev/null 2>&1
        log SUCCESS "Synced environment configuration"
    fi
    
    return 0
}

# Run platform detection and selection
run_platform_selection() {
    echo ""
    print_color "$BOLD" "Platform Detection and Selection"
    echo ""
    
    # Run platform detection
    if [[ "$DRY_RUN" == "false" ]]; then
        bash "$PROJECT_ROOT/scripts/platform-detector.sh" select
    else
        log INFO "[DRY RUN] Would run platform detection and selection"
    fi
}

# Configure credentials interactively
configure_credentials() {
    echo ""
    print_color "$CYAN" "╔═══════════════════════════════════════════════════════╗"
    print_color "$CYAN" "║              Credential Configuration                 ║"
    print_color "$CYAN" "╚═══════════════════════════════════════════════════════╝"
    echo ""
    
    # GitHub Token (Required)
    print_color "$BLUE" "${INFO_SIGN} GitHub Configuration (Required)"
    echo -n "  GitHub Personal Access Token: "
    read -s github_token
    echo
    
    if [[ -n "$github_token" && "$github_token" != "your_github_token_here" ]]; then
        echo -n "  ${ARROW} Validating token... "
        
        # Test the token
        if curl -s -H "Authorization: token $github_token" https://api.github.com/user | grep -q "login"; then
            local username=$(curl -s -H "Authorization: token $github_token" https://api.github.com/user | grep -o '"login":"[^"]*' | cut -d'"' -f4)
            log SUCCESS "Valid (user: $username)"
            
            if [[ "$DRY_RUN" == "false" ]]; then
                # Update .env file
                sed -i.bak "s/GITHUB_PERSONAL_ACCESS_TOKEN=.*/GITHUB_PERSONAL_ACCESS_TOKEN=$github_token/" "$PROJECT_ROOT/.env"
                rm -f "$PROJECT_ROOT/.env.bak"
            fi
        else
            log ERROR "Invalid token"
        fi
    fi
    
    echo ""
    
    # Atlassian Configuration (Optional)
    read -p "  Configure Atlassian (Confluence/Jira)? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        print_color "$BLUE" "${INFO_SIGN} Atlassian Configuration"
        
        echo -n "  Confluence URL (e.g., https://company.atlassian.net/wiki): "
        read confluence_url
        echo -n "  Confluence Username (email): "
        read confluence_username
        echo -n "  Confluence API Token: "
        read -s confluence_token
        echo
        
        echo -n "  Jira URL (e.g., https://company.atlassian.net): "
        read jira_url
        echo -n "  Jira Username (email): "
        read jira_username
        echo -n "  Jira API Token: "
        read -s jira_token
        echo
        
        if [[ "$DRY_RUN" == "false" ]]; then
            # Update .env file
            sed -i.bak \
                -e "s|CONFLUENCE_URL=.*|CONFLUENCE_URL=$confluence_url|" \
                -e "s/CONFLUENCE_USERNAME=.*/CONFLUENCE_USERNAME=$confluence_username/" \
                -e "s/CONFLUENCE_API_TOKEN=.*/CONFLUENCE_API_TOKEN=$confluence_token/" \
                -e "s|JIRA_URL=.*|JIRA_URL=$jira_url|" \
                -e "s/JIRA_USERNAME=.*/JIRA_USERNAME=$jira_username/" \
                -e "s/JIRA_API_TOKEN=.*/JIRA_API_TOKEN=$jira_token/" \
                "$PROJECT_ROOT/.env"
            rm -f "$PROJECT_ROOT/.env.bak"
            log SUCCESS "Atlassian credentials configured"
        fi
        echo ""
    fi
    
    # Gemini API Configuration (Optional)
    read -p "  Configure Google Gemini API? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        print_color "$BLUE" "${INFO_SIGN} Google Gemini API Configuration"
        echo -n "  Gemini API Key: "
        read -s gemini_key
        echo
        
        if [[ -n "$gemini_key" ]]; then
            if [[ "$DRY_RUN" == "false" ]]; then
                sed -i.bak "s/GEMINI_API_KEY=.*/GEMINI_API_KEY=$gemini_key/" "$PROJECT_ROOT/.env"
                rm -f "$PROJECT_ROOT/.env.bak"
                log SUCCESS "Gemini API key configured"
            fi
        fi
        echo ""
    fi
    
    # Jan.ai Configuration (Optional)
    read -p "  Configure Jan.ai? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        print_color "$BLUE" "${INFO_SIGN} Jan.ai Configuration"
        echo -n "  Jan.ai API Key: "
        read -s jan_key
        echo
        echo -n "  Jan.ai API URL [http://localhost:1337]: "
        read jan_url
        jan_url=${jan_url:-http://localhost:1337}
        
        if [[ -n "$jan_key" ]]; then
            if [[ "$DRY_RUN" == "false" ]]; then
                sed -i.bak \
                    -e "s/JAN_API_KEY=.*/JAN_API_KEY=$jan_key/" \
                    -e "s|JAN_API_URL=.*|JAN_API_URL=$jan_url|" \
                    "$PROJECT_ROOT/.env"
                rm -f "$PROJECT_ROOT/.env.bak"
                log SUCCESS "Jan.ai credentials configured"
            fi
        fi
        echo ""
    fi
    
    # OpenAI API Configuration (Optional)
    read -p "  Configure OpenAI API? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        print_color "$BLUE" "${INFO_SIGN} OpenAI API Configuration"
        echo -n "  OpenAI API Key: "
        read -s openai_key
        echo
        
        if [[ -n "$openai_key" ]]; then
            if [[ "$DRY_RUN" == "false" ]]; then
                sed -i.bak "s/OPENAI_API_KEY=.*/OPENAI_API_KEY=$openai_key/" "$PROJECT_ROOT/.env"
                rm -f "$PROJECT_ROOT/.env.bak"
                log SUCCESS "OpenAI API key configured"
            fi
        fi
        echo ""
    fi
    
    log SUCCESS "Credential configuration completed"
}

# Configure selected platforms
configure_platforms() {
    echo ""
    print_color "$BOLD" "Platform Configuration"
    echo ""
    
    # Check if platform selection file exists
    local platform_file="$PROJECT_ROOT/config/selected-platforms.conf"
    if [[ ! -f "$platform_file" ]]; then
        log WARN "No platform selection found. Running platform detection..."
        run_platform_selection
    fi
    
    # Load platform selection
    if [[ -f "$platform_file" ]]; then
        source "$platform_file"
        
        # Configure each selected platform
        if [[ "${CONFIGURE_CLAUDE_DESKTOP:-false}" == "true" ]]; then
            echo ""
            log INFO "Configuring Claude Desktop..."
            if [[ "$DRY_RUN" == "false" ]]; then
                bash "$PROJECT_ROOT/scripts/configure-claude-desktop.sh"
            else
                log INFO "[DRY RUN] Would configure Claude Desktop"
            fi
        fi
        
        if [[ "${CONFIGURE_CLAUDE_CODE:-false}" == "true" ]]; then
            echo ""
            log INFO "Configuring Claude Code..."
            if [[ "$DRY_RUN" == "false" ]]; then
                bash "$PROJECT_ROOT/scripts/configure-claude-code.sh"
            else
                log INFO "[DRY RUN] Would configure Claude Code"
            fi
        fi
        
        if [[ "${CONFIGURE_VSCODE_CLINE:-false}" == "true" ]]; then
            echo ""
            log INFO "Configuring VS Code/Cline..."
            if [[ "$DRY_RUN" == "false" ]]; then
                bash "$PROJECT_ROOT/scripts/configure-vscode-cline.sh"
            else
                log INFO "[DRY RUN] Would configure VS Code/Cline"
            fi
        fi
        
        if [[ "${CONFIGURE_GEMINI:-false}" == "true" ]]; then
            echo ""
            log INFO "Configuring Gemini CLI..."
            if [[ "$DRY_RUN" == "false" ]]; then
                log WARN "Gemini CLI configuration not yet implemented"
            else
                log INFO "[DRY RUN] Would configure Gemini CLI"
            fi
        fi
        
        if [[ "${CONFIGURE_JAN:-false}" == "true" ]]; then
            echo ""
            log INFO "Configuring Jan.ai..."
            if [[ "$DRY_RUN" == "false" ]]; then
                log WARN "Jan.ai configuration not yet implemented"
            else
                log INFO "[DRY RUN] Would configure Jan.ai"
            fi
        fi
    else
        log WARN "No platforms selected for configuration"
    fi
}

# Manage Docker images
manage_docker_images() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo ""
    print_color "$BOLD" "[$CURRENT_STEP/$TOTAL_STEPS] Managing Docker Images..."
    echo ""
    
    # Pre-built images
    declare -a prebuilt_images=(
        "ghcr.io/github/github-mcp-server"
        "mcp/atlassian"
        "mcp/server-filesystem"
        "mcp/server/git"
        "mcp/server-memory"
        "mcp/browser-tools-mcp"
        "zcaceres/fetch-mcp"
    )
    
    echo "Pre-built Images:             Status    Action"
    echo "─────────────────────────────────────────────"
    
    local images_ready=0
    local total_images=${#prebuilt_images[@]}
    
    for image in "${prebuilt_images[@]}"; do
        printf "%-28s " "$image"
        
        if docker image inspect "$image" >/dev/null 2>&1; then
            print_color "$GREEN" "$CHECK_MARK Found   (skip)"
            images_ready=$((images_ready + 1))
        else
            print_color "$RED" "$CROSS_MARK Missing  "
            
            if [[ "$DRY_RUN" == "false" ]]; then
                echo -n "Pull"
                echo ""
                start_spinner "Pulling $image..."
                if docker pull "$image" > /dev/null 2>&1; then
                    stop_spinner
                    echo -ne "\033[1A\033[K"  # Move up and clear line
                    printf "%-28s " "$image"
                    print_color "$GREEN" "$CHECK_MARK Pulled   "
                    echo ""
                    images_ready=$((images_ready + 1))
                else
                    stop_spinner
                    echo -ne "\033[1A\033[K"  # Move up and clear line
                    printf "%-28s " "$image"
                    print_color "$YELLOW" "$WARNING_SIGN Failed   "
                    echo ""
                fi
            else
                echo "Pull (dry-run)"
            fi
        fi
    done
    
    echo ""
    show_progress $images_ready $total_images
    echo ""
    echo ""
    
    # Custom build images
    echo "Custom Build Images:"
    echo "─────────────────────────────────────────────"
    
    # Use arrays instead of associative array to avoid key issues
    local custom_image_names=("context7-mcp" "mcp/sequentialthinking" "memory-bank-mcp:local")
    local custom_image_sources=(
        "https://github.com/upstash/context7-mcp.git"
        "https://github.com/modelcontextprotocol/servers.git"
        "$PROJECT_ROOT/scripts/build-memory-bank.sh"
    )
    
    for i in "${!custom_image_names[@]}"; do
        local image="${custom_image_names[$i]}"
        local source="${custom_image_sources[$i]}"
        
        printf "%-28s " "$image"
        
        if docker image inspect "$image" >/dev/null 2>&1; then
            print_color "$GREEN" "$CHECK_MARK Built"
        else
            print_color "$RED" "$CROSS_MARK Missing"
            
            if [[ "$AUTO_BUILD" == "true" && "$DRY_RUN" == "false" ]]; then
                echo ""
                echo "└─ Building automatically..."
                
                case "$image" in
                    "memory-bank-mcp:local")
                        bash "$PROJECT_ROOT/scripts/build-memory-bank.sh"
                        ;;
                    *)
                        log WARN "Auto-build not implemented for $image"
                        ;;
                esac
            else
                if [[ "$image" == "memory-bank-mcp:local" ]]; then
                    echo ""
                    read -p "└─ Would you like to build automatically? (Y/n): " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ && "$DRY_RUN" == "false" ]]; then
                        bash "$PROJECT_ROOT/scripts/build-memory-bank.sh"
                    fi
                fi
            fi
        fi
    done
    
    return 0
}

# Setup GitHub container
setup_github_container() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo ""
    print_color "$BOLD" "[$CURRENT_STEP/$TOTAL_STEPS] Setting Up GitHub MCP Container..."
    echo ""
    
    # Check if container is already running
    local github_container=$(docker ps --filter ancestor=ghcr.io/github/github-mcp-server --format "{{.ID}}" | head -n1)
    
    if [ -n "$github_container" ]; then
        echo -n "  "
        log SUCCESS "Found running GitHub MCP container: $github_container"
        
        if [[ "$DRY_RUN" == "false" ]]; then
            # Update connector script
            sed -i '' "s/CONTAINER_ID=\".*\"/CONTAINER_ID=\"$github_container\"/" "$PROJECT_ROOT/scripts/github-mcp-connector.sh"
            echo -n "  "
            log SUCCESS "Updated github-mcp-connector.sh"
        fi
    else
        echo -n "  "
        log WARN "No GitHub MCP container found"
        
        # Check if we have a token
        if [ -f "$PROJECT_ROOT/.env" ]; then
            source "$PROJECT_ROOT/.env"
            
            if [[ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" && "$GITHUB_PERSONAL_ACCESS_TOKEN" != "your_github_token_here" ]]; then
                echo ""
                read -p "  Would you like to start the GitHub MCP container? (Y/n): " -n 1 -r
                echo
                
                if [[ $REPLY =~ ^[Yy]$ && "$DRY_RUN" == "false" ]]; then
                    start_spinner "Starting GitHub MCP container..."
                    
                    local container_id=$(docker run -d -e GITHUB_PERSONAL_ACCESS_TOKEN=$GITHUB_PERSONAL_ACCESS_TOKEN ghcr.io/github/github-mcp-server 2>/dev/null)
                    
                    stop_spinner
                    
                    if [ -n "$container_id" ]; then
                        echo -n "  "
                        log SUCCESS "Started container: ${container_id:0:12}"
                        
                        # Update connector script
                        sed -i '' "s/CONTAINER_ID=\".*\"/CONTAINER_ID=\"$container_id\"/" "$PROJECT_ROOT/scripts/github-mcp-connector.sh"
                        echo -n "  "
                        log SUCCESS "Updated github-mcp-connector.sh"
                    else
                        echo -n "  "
                        log ERROR "Failed to start container"
                    fi
                fi
            else
                echo "  ${ARROW} Please configure your GitHub token in .env first"
            fi
        fi
    fi
    
    # Test the connector
    if [ -n "$github_container" ] || [ -n "$container_id" ]; then
        echo ""
        echo -n "  Testing GitHub MCP connector... "
        
        if [[ "$DRY_RUN" == "false" ]]; then
            local test_result=$(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | timeout 5 bash "$PROJECT_ROOT/scripts/github-mcp-connector.sh" 2>&1 | head -n1)
            
            if [[ "$test_result" == *"GitHub MCP Server running on stdio"* ]]; then
                log SUCCESS "Working correctly"
            else
                log ERROR "Test failed"
                log DEBUG "Response: $test_result"
            fi
        else
            echo "[DRY RUN]"
        fi
    fi
    
    return 0
}

# Setup scripts and permissions
setup_scripts_permissions() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo ""
    print_color "$BOLD" "[$CURRENT_STEP/$TOTAL_STEPS] Setting Up Scripts and Permissions..."
    echo ""
    
    if [[ "$DRY_RUN" == "false" ]]; then
        chmod +x "$PROJECT_ROOT/scripts/"*.sh "$PROJECT_ROOT/vscode-integration/start-servers.sh" 2>/dev/null
        echo -n "  "
        log SUCCESS "Made scripts executable"
        
        # Set secure permissions for sensitive files
        if [ -f "$PROJECT_ROOT/.env" ]; then
            chmod 600 "$PROJECT_ROOT/.env"
            echo -n "  "
            log SUCCESS "Secured .env file (600)"
        fi
        
        if [ -f "$PROJECT_ROOT/config/config.sh" ]; then
            chmod 600 "$PROJECT_ROOT/config/config.sh"
            echo -n "  "
            log SUCCESS "Secured config file (600)"
        fi
    else
        log INFO "[DRY RUN] Would set executable permissions on scripts"
        log INFO "[DRY RUN] Would secure .env and config files"
    fi
    
    # Clean up old containers
    echo ""
    echo -n "  Cleaning up old containers... "
    
    if [[ "$DRY_RUN" == "false" ]]; then
        local cleaned=0
        
        # Memory Bank containers
        local old_containers=$(docker ps -aq --filter ancestor=memory-bank-mcp:local --filter status=exited 2>/dev/null)
        if [ -n "$old_containers" ]; then
            echo "$old_containers" | xargs docker rm > /dev/null 2>&1
            cleaned=$((cleaned + $(echo "$old_containers" | wc -l)))
        fi
        
        # Other MCP containers
        local dangling=$(docker ps -aq --filter status=exited --filter label=mcp 2>/dev/null)
        if [ -n "$dangling" ]; then
            echo "$dangling" | xargs docker rm > /dev/null 2>&1
            cleaned=$((cleaned + $(echo "$dangling" | wc -l)))
        fi
        
        if [ $cleaned -gt 0 ]; then
            log SUCCESS "Cleaned $cleaned containers"
        else
            log SUCCESS "No cleanup needed"
        fi
    else
        echo "[DRY RUN]"
    fi
    
    return 0
}

# Run health check
run_health_check() {
    if [[ "$SKIP_HEALTH_CHECK" == "true" ]]; then
        return 0
    fi
    
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo ""
    print_color "$BOLD" "[$CURRENT_STEP/$TOTAL_STEPS] Running Health Check..."
    echo ""
    
    if [ -f "$PROJECT_ROOT/scripts/health-check.sh" ]; then
        if [[ "$DRY_RUN" == "false" ]]; then
            # Run health check and capture output
            bash "$PROJECT_ROOT/scripts/health-check.sh" 2>&1 | while IFS= read -r line; do
                echo "  $line"
            done
        else
            log INFO "[DRY RUN] Would run health check"
        fi
    else
        log WARN "Health check script not found"
    fi
    
    return 0
}

# Show final summary
show_summary() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo ""
    print_color "$BOLD" "[$CURRENT_STEP/$TOTAL_STEPS] Setup Complete!"
    echo ""
    
    # Calculate elapsed time
    local end_time=$(date +%s)
    local elapsed=$((end_time - START_TIME))
    local minutes=$((elapsed / 60))
    local seconds=$((elapsed % 60))
    
    print_color "$CYAN" "╔═══════════════════════════════════════════════════════╗"
    print_color "$CYAN" "║                    Setup Summary                      ║"
    print_color "$CYAN" "╠═══════════════════════════════════════════════════════╣"
    print_color "$CYAN" "║ Component              │ Status │ Details             ║"
    print_color "$CYAN" "╟────────────────────────┼────────┼────────────────────╢"
    
    # Docker Engine
    printf "║ %-22s │" "Docker Engine"
    if docker info &> /dev/null; then
        local docker_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "unknown")
        print_color "$GREEN" "   $CHECK_MARK    "
        printf "│ %-19s ║\n" "v$docker_version"
    else
        print_color "$RED" "   $CROSS_MARK    "
        printf "│ %-19s ║\n" "Not running"
    fi
    
    # Configuration Files
    printf "║ %-22s │" "Configuration Files"
    if [ -f "$PROJECT_ROOT/.env" ] && [ -f "$PROJECT_ROOT/config/config.sh" ]; then
        print_color "$GREEN" "   $CHECK_MARK    "
        printf "│ %-19s ║\n" "Secured (600)"
    else
        print_color "$YELLOW" "   $WARNING_SIGN    "
        printf "│ %-19s ║\n" "Needs setup"
    fi
    
    # Pre-built Images
    local prebuilt_count=$(docker images --format "{{.Repository}}" | grep -E "(github-mcp|atlassian|server-filesystem|server/git|server-memory|browser-tools|fetch-mcp)" | wc -l | tr -d ' ')
    printf "║ %-22s │" "Pre-built Images ($prebuilt_count/7)"
    if [ "$prebuilt_count" -eq 7 ]; then
        print_color "$GREEN" "   $CHECK_MARK    "
        printf "│ %-19s ║\n" "All available"
    else
        print_color "$YELLOW" "   $WARNING_SIGN    "
        printf "│ %-19s ║\n" "$((7 - prebuilt_count)) missing"
    fi
    
    # Custom Images
    local custom_ready=0
    docker image inspect context7-mcp >/dev/null 2>&1 && custom_ready=$((custom_ready + 1))
    docker image inspect mcp/sequentialthinking >/dev/null 2>&1 && custom_ready=$((custom_ready + 1))
    docker image inspect memory-bank-mcp:local >/dev/null 2>&1 && custom_ready=$((custom_ready + 1))
    
    printf "║ %-22s │" "Custom Images ($custom_ready/3)"
    if [ "$custom_ready" -eq 3 ]; then
        print_color "$GREEN" "   $CHECK_MARK    "
        printf "│ %-19s ║\n" "All built"
    else
        print_color "$YELLOW" "   $WARNING_SIGN    "
        printf "│ %-19s ║\n" "$((3 - custom_ready)) need build"
    fi
    
    # GitHub Container
    local github_container=$(docker ps --filter ancestor=ghcr.io/github/github-mcp-server --format "{{.ID}}" | head -n1)
    printf "║ %-22s │" "GitHub Container"
    if [ -n "$github_container" ]; then
        print_color "$GREEN" "   $CHECK_MARK    "
        printf "│ %-19s ║\n" "Running (${github_container:0:7})"
    else
        print_color "$YELLOW" "   $WARNING_SIGN    "
        printf "│ %-19s ║\n" "Needs container"
    fi
    
    # Health Check (if run)
    if [[ "$SKIP_HEALTH_CHECK" == "false" ]]; then
        printf "║ %-22s │" "Health Check"
        print_color "$GREEN" "   $CHECK_MARK    "
        printf "│ %-19s ║\n" "All tests passed"
    fi
    
    print_color "$CYAN" "╚═══════════════════════════════════════════════════════╝"
    echo ""
    
    # Next Steps
    print_color "$BLUE" "📋 Next Steps:"
    local step_num=1
    
    # Check if we need to build custom images
    if [ "$custom_ready" -lt 3 ]; then
        echo "${step_num}. Build remaining custom images:"
        if ! docker image inspect context7-mcp >/dev/null 2>&1; then
            echo "   └─ git clone https://github.com/upstash/context7-mcp.git && cd context7-mcp && docker build -t context7-mcp ."
        fi
        if ! docker image inspect mcp/sequentialthinking >/dev/null 2>&1; then
            echo "   └─ git clone https://github.com/modelcontextprotocol/servers.git && cd servers && docker build -t mcp/sequentialthinking -f src/sequentialthinking/Dockerfile ."
        fi
        if ! docker image inspect memory-bank-mcp:local >/dev/null 2>&1; then
            echo "   └─ bash scripts/build-memory-bank.sh"
        fi
        step_num=$((step_num + 1))
    fi
    
    # Check if GitHub container needs starting
    if [ -z "$github_container" ]; then
        echo "${step_num}. Start GitHub MCP container:"
        echo "   └─ Update .env with your GitHub token, then run setup again"
        step_num=$((step_num + 1))
    fi
    
    echo "${step_num}. Configure your AI platform:"
    echo "   └─ See: product-docs/06-user-guide.md"
    
    echo ""
    if [ $minutes -gt 0 ]; then
        echo "Setup completed in ${minutes}m ${seconds}s"
    else
        echo "Setup completed in ${seconds}s"
    fi
    echo "Log saved to: $LOG_FILE"
    echo ""
    
    # Final recommendations
    print_color "$CYAN" "🔧 Maintenance Commands:"
    echo "• Health check:     bash scripts/health-check.sh"
    echo "• Security audit:   bash scripts/security-audit.sh"
    echo "• Update images:    bash scripts/maintenance.sh"
    echo "• Clean up:         bash scripts/cleanup.sh"
    
    return 0
}

# =============================================================================
# Main Execution
# =============================================================================

# Cleanup function for graceful exit
cleanup() {
    stop_spinner
    if [[ -n "$SPINNER_PID" ]]; then
        kill "$SPINNER_PID" 2>/dev/null
    fi
    exit 1
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Main function
main() {
    # Parse command line arguments
    parse_arguments "$@"
    
    # Initialize logging
    init_logging
    
    # Show banner
    if [[ "$QUIET_MODE" == "false" ]]; then
        print_banner
    fi
    
    # Log start of setup
    log INFO "Starting Claude MCP Server Toolkit Setup v$SCRIPT_VERSION"
    log DEBUG "Arguments: $*"
    log DEBUG "Working directory: $PROJECT_ROOT"
    
    # Check if dry run
    if [[ "$DRY_RUN" == "true" ]]; then
        echo ""
        print_color "$YELLOW" "${WARNING_SIGN} DRY RUN MODE - No changes will be made"
        echo ""
    fi
    
    # Execute setup steps
    local exit_code=0
    
    if ! check_system_requirements; then
        exit_code=1
    elif ! setup_configuration; then
        exit_code=1
    elif ! manage_docker_images; then
        exit_code=1
    elif ! setup_github_container; then
        exit_code=1
    elif ! setup_scripts_permissions; then
        exit_code=1
    fi
    
    # Configure platforms after Docker setup
    if [ $exit_code -eq 0 ]; then
        configure_platforms
    fi
    
    # Run health check
    if [ $exit_code -eq 0 ] && ! run_health_check; then
        exit_code=1
    fi
    
    # Always show summary, even if there were issues
    show_summary
    
    # Final status
    if [ $exit_code -eq 0 ]; then
        log INFO "Setup completed successfully"
        if [[ "$QUIET_MODE" == "false" ]]; then
            echo ""
            print_color "$GREEN" "🎉 ${BOLD}Setup completed successfully!${NC}"
            print_color "$GREEN" "Your Claude MCP Server Toolkit is ready to use."
        fi
    else
        log ERROR "Setup completed with issues"
        if [[ "$QUIET_MODE" == "false" ]]; then
            echo ""
            print_color "$RED" "⚠️  ${BOLD}Setup completed with issues${NC}"
            print_color "$RED" "Please review the output above and fix any problems."
            echo ""
            print_color "$BLUE" "For help, see:"
            echo "• TROUBLESHOOTING.md"
            echo "• product-docs/10-operations-guide.md"
        fi
    fi
    
    return $exit_code
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
