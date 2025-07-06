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

echo "=== MCP Server Security Audit (Docker-First Strategy) ==="
echo "Started at: $(date)"
echo ""

# Section 1: Environment Security
echo "1️⃣ Environment Security"
echo "----------------------"

# Check for exposed tokens in environment
env | grep -i "token\|key\|secret\|password" | grep -v "TOKEN=[^=]*$" > /dev/null
if [ $? -eq 0 ]; then
  echo "⚠️ Potential exposed secrets in environment variables!"
  echo "Consider using a secrets manager or environment file with restricted permissions."
else
  echo "✅ No exposed secrets detected in environment variables"
fi

# Check permissions on config file
if [ -f "$PROJECT_ROOT/config/config.sh" ]; then
  permissions=$(stat -f "%A" "$PROJECT_ROOT/config/config.sh")
  if [ "$permissions" != "600" ]; then
    echo "⚠️ Configuration file has loose permissions: $permissions"
    echo "Recommended: chmod 600 \"$PROJECT_ROOT/config/config.sh\""
  else
    echo "✅ Configuration file has secure permissions"
  fi
fi

# Check permissions on .env file
if [ -f "$PROJECT_ROOT/.env" ]; then
  permissions=$(stat -f "%A" "$PROJECT_ROOT/.env")
  if [ "$permissions" != "600" ]; then
    echo "⚠️ .env file has loose permissions: $permissions"
    echo "Recommended: chmod 600 \"$PROJECT_ROOT/.env\""
  else
    echo "✅ .env file has secure permissions"
  fi
fi

# Section 2: Docker Security
echo ""
echo "2️⃣ Docker Security"
echo "----------------"

# Check Docker rootless mode
if docker info 2>/dev/null | grep -q "rootless: true"; then
  echo "✅ Docker is running in rootless mode (more secure)"
else
  echo "⚠️ Docker is not in rootless mode"
  echo "Consider enabling Docker rootless mode for better security."
  echo "See: https://docs.docker.com/engine/security/rootless/"
fi

# Check Docker configuration
echo ""
echo "Docker Configuration Security:"
if docker info 2>/dev/null | grep -q "Live Restore Enabled: true"; then
  echo "✅ Docker live restore is enabled (containers stay running if daemon crashes)"
else
  echo "⚠️ Docker live restore is not enabled"
fi

# Check for userns-remap
if docker info 2>/dev/null | grep -q "userns-remap:"; then
  echo "✅ Docker user namespace remapping is enabled (better container isolation)"
else
  echo "⚠️ Docker user namespace remapping is not enabled"
fi

# Check for exposed ports
echo ""
echo "Exposed Container Ports:"
exposed_ports=$(docker ps --format "{{.Names}}: {{.Ports}}" | grep -v "->127.0.0.1")
if [ -n "$exposed_ports" ]; then
  echo "⚠️ Some containers have publicly exposed ports:"
  echo "$exposed_ports"
  echo "Consider restricting to localhost (127.0.0.1) where possible"
else
  echo "✅ No publicly exposed container ports detected"
fi

# Check for running privileged containers
echo ""
echo "Privileged Containers:"
privileged=$(docker ps --format "{{.Names}}" -f "status=running" | xargs -I{} docker inspect {} | grep -A1 CapAdd | grep -E '"ALL"|Privileged.*true' | grep -B1 "true\|ALL" | grep "Name")
if [ -n "$privileged" ]; then
  echo "⚠️ Privileged containers detected:"
  echo "$privileged"
  echo "Privileged containers can access host resources"
else
  echo "✅ No privileged containers detected"
fi

# Check Docker image vulnerability scanning
echo ""
echo "Docker Image Security Scanning:"
if command -v docker-scout &> /dev/null; then
  echo "✅ Docker Scout is installed for image security scanning"
  echo ""
  echo "Recommended scan command:"
  echo "docker scout cves ghcr.io/github/github-mcp-server"
else
  echo "⚠️ Docker Scout not found"
  echo "Install Docker Scout for container vulnerability scanning:"
  echo "https://docs.docker.com/scout/install/"
fi

# Section 3: MCP Server Configuration Security
echo ""
echo "3️⃣ MCP Server Configuration Security"
echo "---------------------------------"

# Check for MCP server auto-approval settings
echo "Auto-approval settings for MCP servers:"
for server in $(claude mcp list 2>/dev/null | grep -v "No MCP servers" | awk '{print $1}'); do
  auto_approve=$(claude mcp get "$server" 2>/dev/null | grep -A 20 "autoApprove" | grep -v "^$")
  echo "Server: $server"
  if echo "$auto_approve" | grep -q "\"autoApprove\": true"; then
    echo "⚠️ Auto-approve enabled (all commands run without approval)"
  else
    echo "✅ Auto-approve disabled or partially restricted"
  fi
  echo "$auto_approve"
  echo "--------------------------"
done

# Section 4: Credential Security
echo ""
echo "4️⃣ Credential Security"
echo "--------------------"

# Check if GitHub token is valid
if [ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ] && [ "$GITHUB_PERSONAL_ACCESS_TOKEN" != "your_github_token_here" ]; then
  echo "Validating GitHub token..."
  response_code=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $GITHUB_PERSONAL_ACCESS_TOKEN" https://api.github.com/user)
  if [ "$response_code" != "200" ]; then
    echo "⚠️ GitHub token appears to be invalid or expired! Response code: $response_code"
  else
    echo "✅ GitHub token is valid"
    
    # Check token permissions
    token_info=$(curl -s -H "Authorization: token $GITHUB_PERSONAL_ACCESS_TOKEN" https://api.github.com/user)
    
    if echo "$token_info" | grep -q "\"plan\""; then
      # This is likely a personal token with broad access
      echo "⚠️ GitHub token appears to have broad account access"
      echo "Consider using a fine-grained token with minimal scope"
    fi
  fi
else
  echo "⚠️ GitHub token not set or set to default"
fi

# Check if Confluence token is valid (if set)
if [ -n "$CONFLUENCE_API_TOKEN" ] && [ "$CONFLUENCE_API_TOKEN" != "your_confluence_token_here" ]; then
  echo "✅ Confluence API token is set"
else
  echo "⚠️ Confluence API token not set or set to default"
fi

# Check if Jira token is valid (if set)
if [ -n "$JIRA_API_TOKEN" ] && [ "$JIRA_API_TOKEN" != "your_jira_token_here" ]; then
  echo "✅ Jira API token is set"
else
  echo "⚠️ Jira API token not set or set to default"
fi

# Section 5: File System Security
echo ""
echo "5️⃣ File System Security"
echo "---------------------"

# Check if any script files have overly permissive permissions
echo "Script file permissions:"
for script in "$PROJECT_ROOT/scripts/"*.sh "$PROJECT_ROOT/vscode-integration/"*.sh; do
  if [ -f "$script" ]; then
    permissions=$(stat -f "%A" "$script")
    if [[ "$permissions" == *"7"* ]] || [[ "$permissions" == *"2"* ]] || [[ "$permissions" == *"5"* ]]; then
      echo "⚠️ $script has potentially insecure permissions: $permissions"
    else
      echo "✅ $script has appropriate permissions: $permissions"
    fi
  fi
done

# Check if data directories have appropriate permissions
echo ""
echo "Data directory permissions:"
for dir in "$PROJECT_ROOT/data" "$PROJECT_ROOT/data/memory-bank" "$PROJECT_ROOT/logs"; do
  if [ -d "$dir" ]; then
    permissions=$(stat -f "%A" "$dir")
    if [[ "$permissions" == *"7"* ]] || [[ "$permissions" == *"2"* ]] || [[ "$permissions" == *"5"* ]]; then
      echo "⚠️ $dir has potentially insecure permissions: $permissions"
    else
      echo "✅ $dir has appropriate permissions: $permissions"
    fi
  fi
done

# Section 6: Docker Volume Security
echo ""
echo "6️⃣ Docker Volume Security"
echo "----------------------"

# Check Docker volume permissions
echo "Docker volume security:"
docker_volumes=$(docker volume ls -q)
if [ -n "$docker_volumes" ]; then
  echo "Docker volumes present: $docker_volumes"
  echo "⚠️ Consider regular review and cleanup of unused volumes"
  echo "   Command: docker volume prune"
else
  echo "✅ No Docker volumes present"
fi

# Check for unencrypted sensitive data in Docker volumes
echo ""
echo "Note: Docker volumes may contain sensitive data"
echo "Recommendation: Consider encrypting volumes with sensitive data"
echo "See: https://docs.docker.com/engine/security/"

# Section 7: Security Summary
echo ""
echo "7️⃣ Security Audit Summary"
echo "----------------------"

echo "✅ Checks passed:"
echo "   - Script executed securely"

echo ""
echo "⚠️ Key security considerations:"
echo "1. Keep Docker updated to latest version"
echo "2. Regularly update all Docker images"
echo "3. Use Docker Scout to scan for vulnerabilities"
echo "4. Ensure all credential files (.env, config.sh) have 600 permissions"
echo "5. Monitor container logs for suspicious activity"
echo "6. Consider enabling Docker rootless mode"

echo ""
echo "Security audit completed at: $(date)"
