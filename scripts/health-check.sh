#!/bin/bash

# Load environment variables
source ~/Documents/claude-mcp-servers/config/config.sh

echo "Checking MCP server configurations..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "⚠️ Docker is not running! Please start Docker before proceeding."
  exit 1
fi

# Check if required directories exist
for dir in ~/Documents/claude-mcp-servers/data/memory-bank ~/Documents/claude-mcp-servers/data/knowledge-graph ~/Documents/claude-mcp-servers/logs; do
  if [ ! -d "$dir" ]; then
    echo "⚠️ Required directory $dir doesn't exist. Creating..."
    mkdir -p "$dir"
  fi
done

# Check environment variables
if [ -z "$GITHUB_PERSONAL_ACCESS_TOKEN" ] || [ "$GITHUB_PERSONAL_ACCESS_TOKEN" == "your_github_token_here" ]; then
  echo "⚠️ GITHUB_PERSONAL_ACCESS_TOKEN is not set or is set to default!"
  echo "Please update ~/Documents/claude-mcp-servers/config/config.sh with your token."
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
  echo "bash ~/Documents/claude-mcp-servers/vscode-integration/start-servers.sh"
else
  echo "✅ Claude has MCP servers configured."
  claude mcp list
fi

echo "✅ Environment checks passed!"
