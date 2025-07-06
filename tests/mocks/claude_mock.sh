#!/bin/bash

# =============================================================================
# Mock for the 'claude' command-line interface
# =============================================================================
#
# This script simulates the behavior of the `claude mcp` command for testing
# purposes. It allows us to test our scripts without needing a live Claude
# environment. It can be configured to simulate different scenarios by setting
# environment variables before calling it.
#
# Supported Commands:
#   - claude mcp list
#   - claude mcp add <name> <command> <args...>
#   - claude mcp remove <name>
#   - claude mcp get <name>
#
# Environment Variables for Configuration:
#   - CLAUDE_MOCK_LIST_OUTPUT: Controls the output of `claude mcp list`.
#   - CLAUDE_MOCK_ADD_EXIT_CODE: Sets the exit code for `claude mcp add`.
#   - CLAUDE_MOCK_REMOVE_EXIT_CODE: Sets the exit code for `claude mcp remove`.
# =============================================================================

# Default exit codes
ADD_EXIT_CODE=${CLAUDE_MOCK_ADD_EXIT_CODE:-0}
REMOVE_EXIT_CODE=${CLAUDE_MOCK_REMOVE_EXIT_CODE:-0}

# Main command logic
if [ "$1" == "mcp" ]; then
    case "$2" in
        "list")
            if [ -n "$CLAUDE_MOCK_LIST_OUTPUT" ]; then
                echo -e "$CLAUDE_MOCK_LIST_OUTPUT"
            else
                # Default behavior: return a sample list
                echo "github-mcp-server      bash /path/to/github-mcp-connector.sh"
                echo "memory-bank-mcp-server bash /path/to/memory-bank-connector.sh"
            fi
            exit 0
            ;;
        "add")
            echo "Mocked: claude mcp add $@" >&2
            exit "$ADD_EXIT_CODE"
            ;;
        "remove")
            echo "Mocked: claude mcp remove $@" >&2
            exit "$REMOVE_EXIT_CODE"
            ;;
        "get")
            # Return a sample JSON for the 'get' command
            echo '{
                "name": "'$3'",
                "command": "mock_command",
                "autoApprove": true
            }'
            exit 0
            ;;
        *)
            echo "Mock Error: Unknown mcp command '$2'" >&2
            exit 1
            ;;
    esac
fi

echo "Mock Error: Unknown claude command '$1'" >&2
exit 1
