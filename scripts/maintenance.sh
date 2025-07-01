#!/bin/bash

# Load environment variables
source ~/Documents/claude-mcp-servers/config/config.sh

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
backup_dir=~/Documents/claude-mcp-servers/backups/$(date +%Y%m%d)
mkdir -p "$backup_dir"
claude mcp list > "$backup_dir/mcp-servers-list.txt"
for server in $(claude mcp list | grep -v "No MCP servers" | awk '{print $1}'); do
  claude mcp get "$server" > "$backup_dir/$server-config.json"
done

# Rotate logs
echo "Rotating logs..."
log_dir=~/Documents/claude-mcp-servers/logs
find "$log_dir" -name "*.log" -mtime +30 -delete

echo "✅ Maintenance completed!"
