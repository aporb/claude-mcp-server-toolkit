#!/bin/bash

echo "WARNING: This will remove all configured MCP servers."
echo "Are you sure you want to proceed? (y/N)"
read -r response

if [[ ! "$response" =~ ^[Yy]$ ]]; then
  echo "Operation cancelled."
  exit 0
fi

# Get list of all servers
servers=$(claude mcp list | grep -v "No MCP servers" | awk '{print $1}')

# Remove each server
for server in $servers; do
  echo "Removing server: $server"
  claude mcp remove "$server"
done

echo "✅ All MCP servers removed!"
