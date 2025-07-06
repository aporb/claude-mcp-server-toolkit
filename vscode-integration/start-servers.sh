#!/bin/bash

# Determine the project root dynamically
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load environment variables
# Try .env file first, then fall back to config.sh
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
elif [ -f "$PROJECT_ROOT/config/config.sh" ]; then
    source "$PROJECT_ROOT/config/config.sh"
else
    echo "❌ No environment configuration found!"
    echo "Please create .env file or run: bash scripts/setup-github-token.sh"
    exit 1
fi

# Create a lockfile to prevent multiple instances
LOCK_FILE="$PROJECT_ROOT/vscode-integration/.server-lock"
if [ -f "$LOCK_FILE" ]; then
  PID=$(cat "$LOCK_FILE")
  if ps -p $PID > /dev/null; then
    echo "MCP servers already running with PID $PID"
    exit 0
  fi
  echo "Stale lock file found, removing..."
  rm "$LOCK_FILE"
fi

# Create the lock file with current PID
echo $ > "$LOCK_FILE"

# Function to clean up on exit
cleanup() {
  echo "Cleaning up..."
  rm -f "$LOCK_FILE"
  exit 0
}

# Register cleanup on script exit
trap cleanup EXIT INT TERM

# Log start time
mkdir -p "$PROJECT_ROOT/logs"
echo "Starting MCP servers at $(date)" >> "$PROJECT_ROOT/logs/startup.log"

# Register MCP servers with Claude
echo "Registering MCP servers with Claude..."

# GitHub MCP Server
# First remove any existing configuration
claude mcp remove "github-mcp-server" 2>/dev/null || true
# Add with the connector script that uses the existing container
claude mcp add "github-mcp-server" "bash" "$PROJECT_ROOT/scripts/github-mcp-connector.sh"

# Context7 MCP Server
claude mcp add "context7-mcp-server" "npx" "@upstash/context7-mcp@latest"

# Browser Tools MCP Server
claude mcp add "browser-tools-mcp-server" "npx" "@agentdeskai/browser-tools-mcp@latest"

# Puppeteer MCP Server
claude mcp add "puppeteer-mcp-server" "npx" "puppeteer-mcp-server"

# Memory Bank MCP Server
# First remove any existing configuration
claude mcp remove "memory-bank-mcp-server" 2>/dev/null || true
# Add with the connector script that manages container lifecycle
claude mcp add "memory-bank-mcp-server" "bash" "$PROJECT_ROOT/scripts/memory-bank-connector.sh"

# Knowledge Graph MCP Server - Disabled (package not available)
# claude mcp add "knowledgegraph-mcp-server" "npx" "knowledgegraph-mcp-server"

# List all configured servers
echo "Configured MCP servers:"
claude mcp list

# Keep the script running to maintain the lock
# This prevents multiple instances during VS Code restarts
echo "MCP servers registered. Maintaining session..."
# Tail a log file to keep the process alive but don't fill the terminal
tail -f /dev/null
