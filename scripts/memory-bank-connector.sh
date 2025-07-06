#!/bin/bash

# Determine the project root dynamically
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# =============================================================================
# Memory Bank MCP Connector Script
# =============================================================================
# 
# Purpose: Runs Memory Bank MCP server in a clean Docker container
# Usage: Called automatically by Claude Code's MCP configuration
# Requirements: Docker, memory-bank-mcp:local Docker image
# 
# This script:
# 1. Verifies the memory-bank-mcp:local Docker image exists
# 2. Runs a fresh container with --rm flag for automatic cleanup
# 3. Uses -i flag for interactive stdio communication
# 
# Benefits of this approach:
# - Prevents accumulation of multiple containers
# - Each connection gets a fresh, clean environment
# - Automatic cleanup when connection closes
# 
# Build the image with: bash "$PROJECT_ROOT/scripts/build-memory-bank.sh"
# =============================================================================

# Verify the Docker image exists
if ! docker image inspect memory-bank-mcp:local >/dev/null 2>&1; then
    echo "Error: memory-bank-mcp:local image not found" >&2
    echo "Please run: bash \"$PROJECT_ROOT/scripts/build-memory-bank.sh\"" >&2
    echo "Available images:" >&2
    docker images --filter reference=memory-bank-mcp >&2
    exit 1
fi

# Run a fresh container with automatic cleanup
# -i: Interactive mode for stdio communication
# --rm: Remove container when it exits (prevents accumulation)
exec docker run -i --rm memory-bank-mcp:local "$@"
