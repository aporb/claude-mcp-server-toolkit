#!/bin/bash

# =============================================================================
# Claude MCP Servers Setup Script
# =============================================================================
# 
# This script initializes the MCP server environment for Claude Code.
# It sets up proper permissions, validates requirements, and provides
# guidance for next steps.
# 
# Updated: 2025-01-01 - Includes fixes for GitHub MCP and Memory Bank issues
# =============================================================================

echo "🚀 Setting up Claude MCP Servers..."
echo "   Updated with GitHub MCP stdio fix and Memory Bank cleanup improvements"
echo ""

# Check requirements
echo "📋 Checking requirements..."

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker Desktop."
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi
echo "✅ Docker is running"

# Check if we have a GitHub MCP container running
GITHUB_CONTAINER=$(docker ps --filter ancestor=ghcr.io/github/github-mcp-server --format "{{.ID}}" | head -n1)
if [ -n "$GITHUB_CONTAINER" ]; then
    echo "✅ Found running GitHub MCP container: $GITHUB_CONTAINER"
    # Update the connector script with the current container ID
    sed -i '' "s/CONTAINER_ID=\".*\"/CONTAINER_ID=\"$GITHUB_CONTAINER\"/" scripts/github-mcp-connector.sh
    echo "✅ Updated github-mcp-connector.sh with current container ID"
else
    echo "⚠️  No GitHub MCP container found. You'll need to start one:"
    echo "   docker run -d -e GITHUB_PERSONAL_ACCESS_TOKEN=your_token ghcr.io/github/github-mcp-server"
fi

# Make scripts executable
echo ""
echo "🔧 Setting up scripts and permissions..."
chmod +x scripts/*.sh vscode-integration/start-servers.sh
echo "✅ Made scripts executable"

# Set secure permissions for config file
if [ -f config/config.sh ]; then
    chmod 600 config/config.sh
    echo "✅ Set secure permissions for config file"
else
    echo "⚠️  config/config.sh not found - you may need to create it"
fi

# Clean up any old memory bank containers
OLD_CONTAINERS=$(docker ps -aq --filter ancestor=memory-bank-mcp:local --filter status=exited 2>/dev/null)
if [ -n "$OLD_CONTAINERS" ]; then
    echo "🧹 Cleaning up old memory bank containers..."
    echo "$OLD_CONTAINERS" | xargs docker rm > /dev/null 2>&1
    echo "✅ Cleaned up old memory bank containers"
fi

# Check if memory bank image exists
if docker image inspect memory-bank-mcp:local >/dev/null 2>&1; then
    echo "✅ Memory Bank Docker image exists"
else
    echo "⚠️  Memory Bank Docker image not found"
    echo "   Run: bash scripts/build-memory-bank.sh"
fi

# Test GitHub connector if container exists
if [ -n "$GITHUB_CONTAINER" ]; then
    echo ""
    echo "🧪 Testing GitHub MCP connector..."
    TEST_RESULT=$(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | timeout 5 bash scripts/github-mcp-connector.sh 2>&1 | head -n1)
    
    if [[ "$TEST_RESULT" == *"GitHub MCP Server running on stdio"* ]]; then
        echo "✅ GitHub MCP connector working correctly"
    else
        echo "❌ GitHub MCP connector test failed"
        echo "   Response: $TEST_RESULT"
        echo "   See TROUBLESHOOTING.md for help"
    fi
fi

# Run health check
echo ""
echo "🔍 Running health check..."
if [ -f scripts/health-check.sh ]; then
    bash scripts/health-check.sh
else
    echo "⚠️  Health check script not found"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "📝 Status Summary:"
if [ -n "$GITHUB_CONTAINER" ]; then
    echo "   ✅ GitHub MCP Server: Ready (container $GITHUB_CONTAINER)"
else
    echo "   ⚠️  GitHub MCP Server: Needs container"
fi

if docker image inspect memory-bank-mcp:local >/dev/null 2>&1; then
    echo "   ✅ Memory Bank MCP: Ready"
else
    echo "   ⚠️  Memory Bank MCP: Needs build"
fi

echo ""
echo "🎯 Next steps:"
echo "1. Edit config/config.sh with your GitHub token and other credentials"

if [ -z "$GITHUB_CONTAINER" ]; then
    echo "2. Start GitHub MCP container:"
    echo "   docker run -d -e GITHUB_PERSONAL_ACCESS_TOKEN=your_token ghcr.io/github/github-mcp-server"
fi

if ! docker image inspect memory-bank-mcp:local >/dev/null 2>&1; then
    echo "3. Build Memory Bank Docker image: bash scripts/build-memory-bank.sh"
fi

echo "4. Configure Claude Code MCP servers (they should work automatically)"
echo "5. Test with: /mcp in Claude Code"
echo ""
echo "📚 Documentation:"
echo "   - README.md - Main documentation"
echo "   - TROUBLESHOOTING.md - Issue resolution guide"
echo ""
echo "🔧 If you have issues:"
echo "   - Check TROUBLESHOOTING.md"
echo "   - Run: bash scripts/health-check.sh"
