#!/bin/bash

# =============================================================================
# Claude MCP Server Toolkit - Platform Detection Script
# Version: 2.0.0
# =============================================================================

# Script configuration
readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors and formatting
readonly NC='\033[0m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'

# Unicode symbols
readonly CHECK_MARK="✓"
readonly CROSS_MARK="✗"
readonly INFO_SIGN="ℹ"

# Platform detection results
# Using associative arrays for platform data
PLATFORM_DETECTED=()
PLATFORM_PATHS=()
PLATFORM_VERSIONS=()

# Initialize arrays with default values
init_platform_arrays() {
    local platforms=("claude_desktop" "claude_code" "vscode_cline" "gemini" "jan")
    for platform in "${platforms[@]}"; do
        PLATFORM_DETECTED[$platform]="false"
        PLATFORM_PATHS[$platform]=""
        PLATFORM_VERSIONS[$platform]="unknown"
    done
}

# Helper function to set platform data
set_platform_data() {
    local platform="$1"
    local detected="$2"
    local path="$3"
    local version="$4"
    
    PLATFORM_DETECTED[$platform]="$detected"
    PLATFORM_PATHS[$platform]="$path"
    PLATFORM_VERSIONS[$platform]="$version"
}

# =============================================================================
# Detection Functions
# =============================================================================

# Print colored output
print_color() {
    local color="$1"
    shift
    echo -e "${color}$*${NC}"
}

# Detect Claude Desktop
detect_claude_desktop() {
    local config_paths=(
        "$HOME/Library/Application Support/Claude/claude_desktop_config.json"  # macOS
        "$HOME/.config/claude/claude_desktop_config.json"                      # Linux
        "$APPDATA/Claude/claude_desktop_config.json"                          # Windows
    )
    
    local app_paths=(
        "/Applications/Claude.app"                                            # macOS
        "$HOME/.local/share/Claude"                                          # Linux
        "$LOCALAPPDATA/Programs/Claude"                                      # Windows
    )
    
    local detected="false"
    local config_path=""
    local version="unknown"
    
    # Check for Claude Desktop installation
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS detection
        if [ -d "${app_paths[0]}" ]; then
            detected="true"
            version=$(defaults read "${app_paths[0]}/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "unknown")
            
            # Check for config file
            if [ -f "${config_paths[0]}" ]; then
                config_path="${config_paths[0]}"
            elif [ -f "${config_paths[1]}" ]; then
                config_path="${config_paths[1]}"
            fi
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux detection
        if [ -d "${app_paths[1]}" ] || command -v claude-desktop >/dev/null 2>&1; then
            detected="true"
            version=$(claude-desktop --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
            
            if [ -f "${config_paths[1]}" ]; then
                config_path="${config_paths[1]}"
            fi
        fi
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        # Windows detection
        if [ -d "${app_paths[2]}" ]; then
            detected="true"
            
            if [ -f "${config_paths[2]}" ]; then
                config_path="${config_paths[2]}"
            fi
            
            # Try to get version from Windows registry
            version=$(reg query "HKCU\Software\Claude" /v "Version" 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
        fi
    fi
    
    set_platform_data "claude_desktop" "$detected" "$config_path" "$version"
    [ "$detected" = "true" ]
    return $?
}

# Detect Claude Code (VS Code extension)
detect_claude_code() {
    local config_path="$HOME/.config/claude-code/mcp.json"
    
    # Check for Claude Code extension
    if command -v code >/dev/null 2>&1; then
        # Check if Claude extension is installed
        if code --list-extensions 2>/dev/null | grep -q "anthropic.claude"; then
            PLATFORM_DETECTED["claude_code"]="true"
            PLATFORM_PATHS["claude_code"]="$config_path"
            
            # Try to get extension version
            local version=$(code --list-extensions --show-versions 2>/dev/null | grep "anthropic.claude" | cut -d'@' -f2 || echo "unknown")
            PLATFORM_VERSIONS["claude_code"]="$version"
            return 0
        fi
    fi
    
    PLATFORM_DETECTED["claude_code"]="false"
    return 1
}

# Detect VS Code with Cline extension
detect_vscode_cline() {
    local workspace_config="$PROJECT_ROOT/.vscode/mcp.json"
    
    # Check for VS Code
    if command -v code >/dev/null 2>&1; then
        # Check if Cline extension is installed
        if code --list-extensions 2>/dev/null | grep -q "saoudrizwan.claude-dev"; then
            PLATFORM_DETECTED["vscode_cline"]="true"
            PLATFORM_PATHS["vscode_cline"]="$workspace_config"
            
            # Try to get extension version
            local version=$(code --list-extensions --show-versions 2>/dev/null | grep "saoudrizwan.claude-dev" | cut -d'@' -f2 || echo "unknown")
            PLATFORM_VERSIONS["vscode_cline"]="$version"
            return 0
        fi
    fi
    
    PLATFORM_DETECTED["vscode_cline"]="false"
    return 1
}

# Detect Gemini CLI
detect_gemini() {
    local config_path="$HOME/.gemini/settings.json"
    
    # Check for Gemini CLI installation
    if command -v gemini >/dev/null 2>&1; then
        PLATFORM_DETECTED["gemini"]="true"
        PLATFORM_PATHS["gemini"]="$config_path"
        
        # Try to get version
        local version=$(gemini --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
        PLATFORM_VERSIONS["gemini"]="$version"
        return 0
    fi
    
    PLATFORM_DETECTED["gemini"]="false"
    return 1
}

# Detect Jan.ai
detect_jan() {
    local config_paths=(
        "$HOME/.jan/settings.json"
        "$HOME/Library/Application Support/Jan/settings.json"
        "$APPDATA/Jan/settings.json"
    )
    
    # Check for Jan.ai installation
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -d "/Applications/Jan.app" ]; then
            PLATFORM_DETECTED["jan"]="true"
            for path in "${config_paths[@]}"; do
                if [ -f "$path" ]; then
                    PLATFORM_PATHS["jan"]="$path"
                    break
                fi
            done
            [ -z "${PLATFORM_PATHS["jan"]}" ] && PLATFORM_PATHS["jan"]="${config_paths[1]}"
            
            # Try to get version
            local version=$(defaults read "/Applications/Jan.app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "unknown")
            PLATFORM_VERSIONS["jan"]="$version"
            return 0
        fi
    elif command -v jan >/dev/null 2>&1; then
        PLATFORM_DETECTED["jan"]="true"
        PLATFORM_PATHS["jan"]="${config_paths[0]}"
        
        # Try to get version
        local version=$(jan --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
        PLATFORM_VERSIONS["jan"]="$version"
        return 0
    fi
    
    PLATFORM_DETECTED["jan"]="false"
    return 1
}

# =============================================================================
# Main Detection Logic
# =============================================================================

# Run all platform detections
detect_all_platforms() {
    # Initialize platform arrays
    init_platform_arrays
    
    print_color "$CYAN" "╔═══════════════════════════════════════════════════════╗"
    print_color "$CYAN" "║          AI Platform Detection v$SCRIPT_VERSION                ║"
    print_color "$CYAN" "╚═══════════════════════════════════════════════════════╝"
    echo ""
    
    print_color "$BLUE" "${INFO_SIGN} Scanning for installed AI platforms..."
    echo ""
    
    # Platform detection
    local platforms=("claude_desktop" "claude_code" "vscode_cline" "gemini" "jan")
    local detect_functions=("detect_claude_desktop" "detect_claude_code" "detect_vscode_cline" "detect_gemini" "detect_jan")
    local platform_names=("Claude Desktop" "Claude Code" "VS Code/Cline" "Gemini CLI" "Jan.ai")
    
    for i in "${!platforms[@]}"; do
        local platform="${platforms[$i]}"
        local detect_func="${detect_functions[$i]}"
        local platform_name="${platform_names[$i]}"
        
        printf "%-20s " "$platform_name:"
        
        if $detect_func; then
            print_color "$GREEN" "${CHECK_MARK} Found (v${PLATFORM_VERSIONS[$platform]})"
            echo "                     Config: ${PLATFORM_PATHS[$platform]}"
        else
            print_color "$DIM" "${CROSS_MARK} Not found"
        fi
        echo ""
    done
}

# Generate platform selection data for setup script
generate_platform_data() {
    cat << EOF
# Platform Detection Results
# Generated: $(date)

EOF
    
    for platform in claude_desktop claude_code vscode_cline gemini jan; do
        echo "DETECTED_${platform^^}=${PLATFORM_DETECTED[$platform]:-false}"
        echo "PATH_${platform^^}=${PLATFORM_PATHS[$platform]:-}"
        echo "VERSION_${platform^^}=${PLATFORM_VERSIONS[$platform]:-unknown}"
        echo ""
    done
}

# Interactive platform selection
interactive_selection() {
    local -a selected_platforms=()
    
    print_color "$BLUE" "${INFO_SIGN} Select platforms to configure:"
    echo ""
    
    for platform in claude_desktop claude_code vscode_cline gemini jan; do
        local platform_name=""
        case $platform in
            claude_desktop) platform_name="Claude Desktop" ;;
            claude_code) platform_name="Claude Code" ;;
            vscode_cline) platform_name="VS Code/Cline" ;;
            gemini) platform_name="Gemini CLI" ;;
            jan) platform_name="Jan.ai" ;;
        esac
        
        local status="Not found"
        local default="n"
        
        if [[ "${PLATFORM_DETECTED[$platform]}" == "true" ]]; then
            status="Found (v${PLATFORM_VERSIONS[$platform]})"
            default="y"
        fi
        
        echo -n "$platform_name [$status] - Configure? (Y/n) [$default]: "
        read -r response
        response=${response:-$default}
        
        if [[ $response =~ ^[Yy]$ ]]; then
            selected_platforms+=("$platform")
        fi
    done
    
    echo ""
    if [ ${#selected_platforms[@]} -gt 0 ]; then
        print_color "$GREEN" "${CHECK_MARK} Selected platforms: ${selected_platforms[*]}"
        
        # Save selection to file
        {
            echo "# Selected platforms for configuration"
            echo "# Generated: $(date)"
            echo ""
            for platform in "${selected_platforms[@]}"; do
                echo "CONFIGURE_${platform^^}=true"
            done
        } > "$PROJECT_ROOT/config/selected-platforms.conf"
        
        return 0
    else
        print_color "$YELLOW" "No platforms selected for configuration."
        return 1
    fi
}

# =============================================================================
# Main Execution
# =============================================================================

# Parse command line arguments
case "${1:-detect}" in
    "detect")
        detect_all_platforms
        ;;
    "data")
        detect_all_platforms > /dev/null 2>&1
        generate_platform_data
        ;;
    "select")
        detect_all_platforms
        interactive_selection
        ;;
    "help"|"--help")
        echo "Usage: $0 [detect|data|select|help]"
        echo ""
        echo "Commands:"
        echo "  detect  - Display detected platforms (default)"
        echo "  data    - Generate platform data for scripts"
        echo "  select  - Interactive platform selection"
        echo "  help    - Show this help message"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information."
        exit 1
        ;;
esac
