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

echo "Checking MCP server configurations..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "⚠️ Docker is not running! Please start Docker before proceeding."
  exit 1
fi

# Check if required directories exist
for dir in "$PROJECT_ROOT/data/memory-bank" "$PROJECT_ROOT/data/knowledge-graph" "$PROJECT_ROOT/logs"; do
  if [ ! -d "$dir" ]; then
    echo "⚠️ Required directory $dir doesn't exist. Creating..."
    mkdir -p "$dir"
  fi
done

# Check environment variables
if [ -z "$GITHUB_PERSONAL_ACCESS_TOKEN" ] || [ "$GITHUB_PERSONAL_ACCESS_TOKEN" == "your_github_token_here" ]; then
  echo "⚠️ GITHUB_PERSONAL_ACCESS_TOKEN is not set or is set to default!"
  echo "Please update $PROJECT_ROOT/.env with your token."
fi

# Check for Node.js and npm
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
  echo "⚠️ Node.js or npm not found. Please install Node.js and npm."
  echo "Run: brew install node"
  exit 1
fi

# Check network connectivity
echo "Checking internet connectivity..."
if ! curl -s --connect-timeout 5 https://api.github.com > /dev/null; then
  echo "⚠️ Internet connectivity issue detected. Check your network connection."
  exit 1
fi

# Check if MCP servers are configured
if claude mcp list 2>/dev/null | grep -q "No MCP servers configured"; then
  echo "⚠️ No MCP servers are currently configured with Claude."
  echo "Run the VS Code integration script to configure them:"
  echo "bash $PROJECT_ROOT/vscode-integration/start-servers.sh"
else
  echo "✅ Claude has MCP servers configured."
  claude mcp list
fi

echo "✅ Environment checks passed!"
