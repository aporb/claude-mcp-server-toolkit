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

# Container ID for the running GitHub MCP server
# Update this if you start a new container
CONTAINER_ID="0688b8e5847b"

# Verify the container is running
if ! docker ps --format "table {{.ID}}" | grep -q "$CONTAINER_ID"; then
    echo "Error: GitHub MCP container $CONTAINER_ID is not running" >&2
    echo "Available containers:" >&2
    docker ps --filter ancestor=ghcr.io/github/github-mcp-server --format "table {{.ID}}\t{{.Status}}" >&2
    exit 1
fi

# Connect to the existing container's stdio interface
# The 'stdio' argument is crucial for MCP protocol communication
exec docker exec -i "$CONTAINER_ID" /server/github-mcp-server stdio "$@"
