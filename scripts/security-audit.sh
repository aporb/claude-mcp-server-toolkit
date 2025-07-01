#!/bin/bash

echo "Running MCP server security audit..."

# Check for exposed tokens in environment
env | grep -i "token\|key\|secret\|password" | grep -v "TOKEN=[^=]*$" > /dev/null
if [ $? -eq 0 ]; then
  echo "⚠️ Potential exposed secrets in environment variables!"
  echo "Consider using a secrets manager or environment file with restricted permissions."
fi

# Check permissions on config file
if [ -f ~/Documents/claude-mcp-servers/config/config.sh ]; then
  permissions=$(stat -f "%A" ~/Documents/claude-mcp-servers/config/config.sh)
  if [ "$permissions" != "600" ]; then
    echo "⚠️ Configuration file has loose permissions: $permissions"
    echo "Recommended: chmod 600 ~/Documents/claude-mcp-servers/config/config.sh"
  fi
fi

# Check Docker security
if docker info 2>/dev/null | grep -q "rootless: true"; then
  echo "✅ Docker is running in rootless mode (more secure)."
else
  echo "⚠️ Docker is not in rootless mode."
  echo "Consider enabling Docker rootless mode for better security."
fi

# Check for MCP server auto-approval settings
for server in $(claude mcp list | grep -v "No MCP servers" | awk '{print $1}'); do
  auto_approve=$(claude mcp get "$server" | grep -A 20 "autoApprove" | grep -v "^$")
  echo "Server: $server"
  echo "Auto-approve settings:"
  echo "$auto_approve"
  echo "--------------------------"
done

# Check if GitHub token is valid
if [ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ] && [ "$GITHUB_PERSONAL_ACCESS_TOKEN" != "your_github_token_here" ]; then
  echo "Validating GitHub token..."
  if ! curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $GITHUB_PERSONAL_ACCESS_TOKEN" https://api.github.com/user | grep -q "200"; then
    echo "⚠️ GitHub token appears to be invalid or expired!"
  else
    echo "✅ GitHub token is valid."
  fi
fi

echo "Security audit complete!"
