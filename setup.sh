#!/bin/bash

# Determine the project root dynamically
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$SCRIPT_DIR"

# =============================================================================
# Claude MCP Servers Setup Script (Docker-First Strategy)
# =============================================================================
# 
# This script initializes the MCP server environment for Docker-first strategy.
# It verifies Docker, pulls/builds images, sets up configurations, and provides
# guidance for next steps.
# 
# Updated: 2025-07-05 - Implements Docker-first strategy per ADR-002
# =============================================================================

echo "🚀 Setting up Claude MCP Servers (Docker-First Strategy)..."
echo "   Implementing Docker-first strategy for enhanced security and consistency"
echo ""

# Section 1: Check prerequisites
echo "📋 Checking prerequisites..."

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

# Check if .env file exists, create from template if needed
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    if [ -f "$PROJECT_ROOT/.env.template" ]; then
        echo "⚠️ .env file not found. Creating from template..."
        cp "$PROJECT_ROOT/.env.template" "$PROJECT_ROOT/.env"
        echo "✅ Created .env file from template"
        echo "⚠️ Please edit $PROJECT_ROOT/.env to add your credentials"
    else
        echo "❌ Neither .env nor .env.template found!"
        echo "   Please create .env file with your credentials"
    fi
else
    echo "✅ Found .env file"
fi

# Create required directories
echo "📁 Creating required directories..."
mkdir -p "$PROJECT_ROOT/logs"
mkdir -p "$PROJECT_ROOT/data/memory-bank"
mkdir -p "$PROJECT_ROOT/data/knowledge-graph"
mkdir -p "$PROJECT_ROOT/config"
echo "✅ Created required directories"

# Section 2: Docker image verification
echo ""
echo "🐳 Verifying Docker images..."

# Check/pull pre-built images
declare -a prebuilt_images=(
    "ghcr.io/github/github-mcp-server"
    "mcp/atlassian"
    "mcp/server-filesystem"
    "mcp/server/git"
    "mcp/server-memory"
    "mcp/browser-tools-mcp"
    "zcaceres/fetch-mcp"
)

for image in "${prebuilt_images[@]}"; do
    if docker image inspect "$image" >/dev/null 2>&1; then
        echo "✅ $image image found"
    else
        echo "⚠️ $image image not found. Pulling..."
        if docker pull "$image"; then
            echo "✅ Successfully pulled $image"
        else
            echo "⚠️ Failed to pull $image. It will be pulled during startup."
        fi
    fi
done

# Check custom build images
echo ""
echo "🔍 Checking custom build images..."

# Context7 MCP
if ! docker image inspect context7-mcp >/dev/null 2>&1; then
    echo "⚠️ Context7 MCP image not found."
    echo "   Run: git clone https://github.com/upstash/context7-mcp.git && cd context7-mcp && docker build -t context7-mcp ."
fi

# Sequential Thinking MCP
if ! docker image inspect mcp/sequentialthinking >/dev/null 2>&1; then
    echo "⚠️ Sequential Thinking MCP image not found."
    echo "   Run: git clone https://github.com/modelcontextprotocol/servers.git && cd servers && docker build -t mcp/sequentialthinking -f src/sequentialthinking/Dockerfile ."
fi

# Memory Bank MCP
if ! docker image inspect memory-bank-mcp:local >/dev/null 2>&1; then
    echo "⚠️ Memory Bank MCP image not found."
    echo "   Run: bash scripts/build-memory-bank.sh"
fi

# Check if GitHub MCP container is running
GITHUB_CONTAINER=$(docker ps --filter ancestor=ghcr.io/github/github-mcp-server --format "{{.ID}}" | head -n1)
if [ -n "$GITHUB_CONTAINER" ]; then
    echo "✅ Found running GitHub MCP container: $GITHUB_CONTAINER"
    # Update the connector script with the current container ID
    sed -i '' "s/CONTAINER_ID=\".*\"/CONTAINER_ID=\"$GITHUB_CONTAINER\"/" "$PROJECT_ROOT/scripts/github-mcp-connector.sh"
    echo "✅ Updated github-mcp-connector.sh with current container ID"
else
    # Start GitHub MCP container if it's not running
    echo "⚠️ No GitHub MCP container found. Starting one..."
    if [ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ] && [ "$GITHUB_PERSONAL_ACCESS_TOKEN" != "your_github_token_here" ]; then
        # Start with token from environment
        CONTAINER_ID=$(docker run -d -e GITHUB_PERSONAL_ACCESS_TOKEN=$GITHUB_PERSONAL_ACCESS_TOKEN ghcr.io/github/github-mcp-server)
        if [ -n "$CONTAINER_ID" ]; then
            echo "✅ Started GitHub MCP container: $CONTAINER_ID"
            # Update the connector script with the current container ID
            sed -i '' "s/CONTAINER_ID=\".*\"/CONTAINER_ID=\"$CONTAINER_ID\"/" "$PROJECT_ROOT/scripts/github-mcp-connector.sh"
            echo "✅ Updated github-mcp-connector.sh with current container ID"
        else
            echo "❌ Failed to start GitHub MCP container"
        fi
    else
        echo "⚠️ No GitHub token found in environment. Please update .env file."
        echo "   Then run: docker run -d -e GITHUB_PERSONAL_ACCESS_TOKEN=your_token ghcr.io/github/github-mcp-server"
    fi
fi

# Section 3: Script setup and permissions
echo ""
echo "🔧 Setting up scripts and permissions..."
chmod +x "$PROJECT_ROOT/scripts/"*.sh "$PROJECT_ROOT/vscode-integration/start-servers.sh"
echo "✅ Made scripts executable"

# Generate config/config.sh from .env
bash "$PROJECT_ROOT/scripts/sync-env-to-config.sh"

# Set secure permissions for config file
if [ -f "$PROJECT_ROOT/config/config.sh" ]; then
    chmod 600 "$PROJECT_ROOT/config/config.sh"
    echo "✅ Set secure permissions for config file"
else
    echo "⚠️ config/config.sh not found - may be created during sync-env-to-config.sh"
fi

# Clean up any old containers
echo "🧹 Cleaning up old containers..."
# Memory Bank containers
OLD_CONTAINERS=$(docker ps -aq --filter ancestor=memory-bank-mcp:local --filter status=exited 2>/dev/null)
if [ -n "$OLD_CONTAINERS" ]; then
    echo "$OLD_CONTAINERS" | xargs docker rm > /dev/null 2>&1
    echo "✅ Cleaned up old memory bank containers"
fi

# Any dangling containers from MCP servers
DANGLING_CONTAINERS=$(docker ps -aq --filter status=exited --filter ancestor=mcp 2>/dev/null)
if [ -n "$DANGLING_CONTAINERS" ]; then
    echo "$DANGLING_CONTAINERS" | xargs docker rm > /dev/null 2>&1
    echo "✅ Cleaned up dangling MCP containers"
fi

# Section 4: Build Memory Bank image if missing
if ! docker image inspect memory-bank-mcp:local >/dev/null 2>&1; then
    echo ""
    echo "🏗️ Building Memory Bank Docker image..."
    bash "$PROJECT_ROOT/scripts/build-memory-bank.sh"
else
    echo "✅ Memory Bank Docker image exists"
fi

# Section 5: Test GitHub connector if container exists
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

# Section 6: Run health check
echo ""
echo "🔍 Running health check..."
if [ -f "$PROJECT_ROOT/scripts/health-check.sh" ]; then
    bash "$PROJECT_ROOT/scripts/health-check.sh"
else
    echo "⚠️ Health check script not found"
fi

# Section 7: Status summary and next steps
echo ""
echo "✅ Setup complete!"
echo ""
echo "📝 Status Summary:"

# GitHub MCP status
GITHUB_CONTAINER=$(docker ps --filter ancestor=ghcr.io/github/github-mcp-server --format "{{.ID}}" | head -n1)
if [ -n "$GITHUB_CONTAINER" ]; then
    echo "   ✅ GitHub MCP Server: Ready (container $GITHUB_CONTAINER)"
else
    echo "   ⚠️ GitHub MCP Server: Needs container"
fi

# Memory Bank status
if docker image inspect memory-bank-mcp:local >/dev/null 2>&1; then
    echo "   ✅ Memory Bank MCP: Ready"
else
    echo "   ⚠️ Memory Bank MCP: Needs build"
fi

# Context7 status
if docker image inspect context7-mcp >/dev/null 2>&1; then
    echo "   ✅ Context7 MCP: Ready"
else
    echo "   ⚠️ Context7 MCP: Needs build"
fi

# Sequential Thinking status
if docker image inspect mcp/sequentialthinking >/dev/null 2>&1; then
    echo "   ✅ Sequential Thinking MCP: Ready"
else
    echo "   ⚠️ Sequential Thinking MCP: Needs build"
fi

echo ""
echo "🎯 Next steps:"

# Step 1: Add credentials if needed
if [ ! -f "$PROJECT_ROOT/.env" ] || ! grep -q "GITHUB_PERSONAL_ACCESS_TOKEN" "$PROJECT_ROOT/.env"; then
    echo "1. Edit .env with your GitHub token and other credentials"
fi

# Step 2: Start GitHub container if needed
if [ -z "$GITHUB_CONTAINER" ]; then
    echo "2. Start GitHub MCP container:"
    echo "   docker run -d -e GITHUB_PERSONAL_ACCESS_TOKEN=your_token ghcr.io/github/github-mcp-server"
fi

# Step 3: Build Memory Bank if needed
if ! docker image inspect memory-bank-mcp:local >/dev/null 2>&1; then
    echo "3. Build Memory Bank Docker image: bash scripts/build-memory-bank.sh"
fi

# Step 4: Configure MCP servers
echo "4. Register MCP servers with VS Code integration: bash vscode-integration/start-servers.sh"

# Final info
echo ""
echo "📚 Documentation:"
echo "   - README.md - Main documentation"
echo "   - TROUBLESHOOTING.md - Issue resolution guide"
echo "   - product-docs/ - Detailed documentation"
echo ""
echo "🔧 If you have issues:"
echo "   - Check TROUBLESHOOTING.md"
echo "   - Run: bash scripts/health-check.sh"
echo "   - Run: bash scripts/security-audit.sh"
