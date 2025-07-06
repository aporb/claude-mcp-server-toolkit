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

echo "Running MCP server security audit..."

# Check for exposed tokens in environment
env | grep -i "token\|key\|secret\|password" | grep -v "TOKEN=[^=]*$" > /dev/null
if [ $? -eq 0 ]; then
  echo "⚠️ Potential exposed secrets in environment variables!"
  echo "Consider using a secrets manager or environment file with restricted permissions."
fi

# Check permissions on config file
if [ -f "$PROJECT_ROOT/config/config.sh" ]; then
  permissions=$(stat -f "%A" "$PROJECT_ROOT/config/config.sh")
  if [ "$permissions" != "600" ]; then
    echo "⚠️ Configuration file has loose permissions: $permissions"
    echo "Recommended: chmod 600 "$PROJECT_ROOT/config/config.sh""
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
