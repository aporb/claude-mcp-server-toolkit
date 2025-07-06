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

echo "Running MCP server maintenance tasks..."

# Update Node.js packages
echo "Updating Node.js packages..."
npm update -g @upstash/context7-mcp@latest
npm update -g @agentdeskai/browser-tools-mcp@latest
npm update -g puppeteer-mcp-server
npm update -g knowledgegraph-mcp-server

# Update Docker images
echo "Updating Docker images..."
docker pull ghcr.io/github/github-mcp-server

# Clean up Docker
echo "Cleaning up Docker resources..."
docker container prune -f
docker image prune -f

# Backup MCP server configurations
echo "Backing up MCP configurations..."
backup_dir="$PROJECT_ROOT/backups/$(date +%Y%m%d)"
mkdir -p "$backup_dir"
claude mcp list > "$backup_dir/mcp-servers-list.txt"
for server in $(claude mcp list | grep -v "No MCP servers" | awk '{print $1}'); do
  claude mcp get "$server" > "$backup_dir/$server-config.json"
done

# Rotate logs
echo "Rotating logs..."
log_dir="$PROJECT_ROOT/logs"
find "$log_dir" -name "*.log" -mtime +30 -delete

echo "✅ Maintenance completed!"
