#!/bin/bash

# Determine the project root dynamically
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# =============================================================================
# GitHub MCP Connector Script
# =============================================================================
# 
# Purpose: Connects Claude Code to an existing GitHub MCP Docker container
# Usage: Called automatically by Claude Code's MCP configuration
# Requirements: Docker, running github-mcp-server container
# 
# This script:
# 1. Verifies the GitHub MCP container is running
# 2. Connects to the container using docker exec
# 3. Passes the 'stdio' argument for proper MCP protocol communication
# 
# Troubleshooting:
# - If container ID changes, update CONTAINER_ID below
# - Test with: echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | bash "$PROJECT_ROOT/scripts/github-mcp-connector.sh"
# =============================================================================

# Find the running container ID dynamically
CONTAINER_ID=$(docker ps --filter ancestor=ghcr.io/github/github-mcp-server --format "{{.ID}}" | head -n1)

# Verify a container was found and is running
if [ -z "$CONTAINER_ID" ] || ! docker ps --format "{{.ID}}" | grep -q "^$CONTAINER_ID$"; then
    echo "Error: No running GitHub MCP container found." >&2
    echo "Please start one with: docker run -d -e GITHUB_PERSONAL_ACCESS_TOKEN=your_token ghcr.io/github/github-mcp-server" >&2
    exit 1
fi

# Connect to the existing container's stdio interface
# The 'stdio' argument is crucial for MCP protocol communication
exec docker exec -i "$CONTAINER_ID" /server/github-mcp-server stdio "$@"
