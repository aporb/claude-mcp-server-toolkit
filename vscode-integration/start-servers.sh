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
echo $$ > "$LOCK_FILE"

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

# Verify Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "❌ Docker is not running! Please start Docker before proceeding."
  exit 1
fi

# Check if required Docker images exist, pull if missing
echo "Verifying Docker images..."

# GitHub MCP
if ! docker image inspect ghcr.io/github/github-mcp-server >/dev/null 2>&1; then
  echo "Pulling GitHub MCP Server image..."
  docker pull ghcr.io/github/github-mcp-server
fi

# Filesystem MCP
if ! docker image inspect mcp/server-filesystem >/dev/null 2>&1; then
  echo "Pulling Filesystem MCP Server image..."
  docker pull mcp/server-filesystem
fi

# Git MCP
if ! docker image inspect mcp/server/git >/dev/null 2>&1; then
  echo "Pulling Git MCP Server image..."
  docker pull mcp/server/git
fi

# Memory MCP
if ! docker image inspect mcp/server-memory >/dev/null 2>&1; then
  echo "Pulling Memory MCP Server image..."
  docker pull mcp/server-memory
fi

# Browser Tools MCP
if ! docker image inspect mcp/browser-tools-mcp >/dev/null 2>&1; then
  echo "Pulling Browser Tools MCP Server image..."
  docker pull mcp/browser-tools-mcp
fi

# Fetch MCP
if ! docker image inspect zcaceres/fetch-mcp >/dev/null 2>&1; then
  echo "Pulling Fetch MCP Server image..."
  docker pull zcaceres/fetch-mcp
fi

# Atlassian MCP
if ! docker image inspect mcp/atlassian >/dev/null 2>&1; then
  echo "Pulling Atlassian MCP Server image..."
  docker pull mcp/atlassian
fi

# Context7 MCP (custom build)
if ! docker image inspect context7-mcp >/dev/null 2>&1; then
  echo "⚠️ Context7 MCP image not found."
  echo "Please build it with: git clone https://github.com/upstash/context7-mcp.git && cd context7-mcp && docker build -t context7-mcp ."
fi

# Sequential Thinking MCP (custom build)
if ! docker image inspect mcp/sequentialthinking >/dev/null 2>&1; then
  echo "⚠️ Sequential Thinking MCP image not found."
  echo "Please build it with: git clone https://github.com/modelcontextprotocol/servers.git && cd servers && docker build -t mcp/sequentialthinking -f src/sequentialthinking/Dockerfile ."
fi

# Memory Bank MCP (local build)
if ! docker image inspect memory-bank-mcp:local >/dev/null 2>&1; then
  echo "⚠️ Memory Bank MCP image not found."
  echo "Please build it with: bash scripts/build-memory-bank.sh"
fi

# Create data directories if they don't exist
mkdir -p "$PROJECT_ROOT/data/memory-bank"
mkdir -p "$PROJECT_ROOT/data/knowledge-graph"

# Register MCP servers with Claude
echo "Registering MCP servers with Claude..."

# Atlassian MCP Server
claude mcp remove "atlassian-mcp-server" 2>/dev/null || true
if [ -n "$CONFLUENCE_URL" ] && [ -n "$JIRA_URL" ]; then
  claude mcp add "atlassian-mcp-server" "docker" "run --rm -e CONFLUENCE_URL -e CONFLUENCE_USERNAME -e CONFLUENCE_API_TOKEN -e JIRA_URL -e JIRA_USERNAME -e JIRA_API_TOKEN mcp/atlassian"
fi

# GitHub MCP Server
# First remove any existing configuration
claude mcp remove "github-mcp-server" 2>/dev/null || true
# Add with the connector script that uses the existing container
claude mcp add "github-mcp-server" "bash" "$PROJECT_ROOT/scripts/github-mcp-connector.sh"

# Filesystem MCP Server
claude mcp remove "filesystem-mcp-server" 2>/dev/null || true
claude mcp add "filesystem-mcp-server" "docker" "run --rm -v /Users:/mnt/users -v /tmp:/mnt/tmp mcp/server-filesystem /mnt/users /mnt/tmp"

# Git MCP Server
claude mcp remove "git-mcp-server" 2>/dev/null || true
claude mcp add "git-mcp-server" "docker" "run --rm -v $PROJECT_ROOT:/repo mcp/server/git"

# Memory MCP Server
claude mcp remove "memory-mcp-server" 2>/dev/null || true
claude mcp add "memory-mcp-server" "docker" "run --rm -i -v $PROJECT_ROOT/data/memory:/app/data mcp/server-memory"

# Browser Tools MCP Server
claude mcp remove "browser-tools-mcp-server" 2>/dev/null || true
claude mcp add "browser-tools-mcp-server" "docker" "run --rm -i mcp/browser-tools-mcp"

# Context7 MCP Server
claude mcp remove "context7-mcp-server" 2>/dev/null || true
if docker image inspect context7-mcp >/dev/null 2>&1; then
  claude mcp add "context7-mcp-server" "docker" "run --rm -i context7-mcp"
else
  # Fallback to NPM if image not built
  claude mcp add "context7-mcp-server" "npx" "-y @upstash/context7-mcp@latest"
fi

# Fetch MCP Server
claude mcp remove "fetch-mcp-server" 2>/dev/null || true
claude mcp add "fetch-mcp-server" "docker" "run --rm -i zcaceres/fetch-mcp"

# Sequential Thinking MCP Server
claude mcp remove "sequential-thinking-mcp-server" 2>/dev/null || true
if docker image inspect mcp/sequentialthinking >/dev/null 2>&1; then
  claude mcp add "sequential-thinking-mcp-server" "docker" "run --rm -i mcp/sequentialthinking"
else
  # Fallback to NPM if image not built
  claude mcp add "sequential-thinking-mcp-server" "npx" "-y @modelcontextprotocol/server-sequential-thinking"
fi

# Memory Bank MCP Server
# First remove any existing configuration
claude mcp remove "memory-bank-mcp-server" 2>/dev/null || true
# Add with the connector script that manages container lifecycle
claude mcp add "memory-bank-mcp-server" "bash" "$PROJECT_ROOT/scripts/memory-bank-connector.sh"

# Jan.ai Integration MCP Server (NPM only - per ADR-002)
claude mcp remove "jan-ai-mcp-server" 2>/dev/null || true
if [ -n "$JAN_API_KEY" ]; then
  claude mcp add "jan-ai-mcp-server" "npx" "-y jan-mcp-server"
fi

# List all configured servers
echo "Configured MCP servers:"
claude mcp list

# Keep the script running to maintain the lock
# This prevents multiple instances during VS Code restarts
echo "MCP servers registered. Maintaining session..."
# Tail a log file to keep the process alive but don't fill the terminal
tail -f /dev/null
