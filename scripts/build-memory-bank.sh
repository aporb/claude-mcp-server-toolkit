#!/bin/bash

# Determine the project root dynamically
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔧 Building Memory Bank MCP Server Docker image..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "❌ Docker is not running! Please start Docker before proceeding."
  exit 1
fi

# Create required data directories
mkdir -p "$PROJECT_ROOT/data/memory-bank"
echo "📁 Created data directory: $PROJECT_ROOT/data/memory-bank"

# Create a temporary directory for building
BUILD_DIR=$(mktemp -d)
echo "📂 Creating build directory: $BUILD_DIR"

# Create Dockerfile with best practices for Memory Bank MCP Server
cat > "$BUILD_DIR/Dockerfile" << 'EOF'
FROM node:18-alpine AS build

# Install dependencies in a separate layer for better caching
WORKDIR /app
RUN npm install -g @modelcontextprotocol/server-memory

# Create a non-root user to run the application
RUN addgroup -S mcp && adduser -S mcp -G mcp

# Use a multi-stage build for a smaller final image
FROM node:18-alpine

# Install only production dependencies
RUN npm install -g @modelcontextprotocol/server-memory --production

# Create app directory with proper ownership
WORKDIR /app
RUN mkdir -p /app/data
RUN chown -R node:node /app

# Set environment variables
ENV MEMORY_FILE_PATH=/app/data/memory.json
ENV NODE_ENV=production

# Use non-root user for security
USER node

# Add container metadata
LABEL org.opencontainers.image.title="Memory Bank MCP Server"
LABEL org.opencontainers.image.description="Docker container for Claude MCP Memory Bank Server"
LABEL org.opencontainers.image.vendor="Claude MCP Server Toolkit"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.created="2025-07-05"

# Health check to verify server is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "try { require('http').request({ method: 'HEAD', path: '/', port: 3000 }, (r) => { process.exit(r.statusCode === 200 ? 0 : 1); }).end(); } catch (e) { process.exit(1); }"

# Expose the server using stdio protocol (no port exposed)
CMD ["npx", "@modelcontextprotocol/server-memory"]
EOF

# Create .dockerignore file for better builds
cat > "$BUILD_DIR/.dockerignore" << 'EOF'
node_modules
npm-debug.log
Dockerfile
.dockerignore
.git
.gitignore
README.md
EOF

# Build the Docker image with buildkit for better efficiency
echo "🏗️ Building Docker image with security and performance optimizations..."
cd "$BUILD_DIR"
DOCKER_BUILDKIT=1 docker build -t memory-bank-mcp:local .

if [ $? -eq 0 ]; then
  echo "✅ Memory Bank MCP Docker image built successfully!"
  
  # Clean up build directory
  rm -rf "$BUILD_DIR"
  
  # Test the image with a simple command
  echo "🧪 Testing the Memory Bank MCP Docker image..."
  if echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | docker run -i --rm memory-bank-mcp:local > /dev/null; then
    echo "✅ Image test successful!"
  else
    echo "⚠️ Image test returned an error. The image was built but may have issues."
  fi
  
  # Add to Claude MCP configuration
  echo "🔄 Adding Memory Bank MCP Server to Claude configuration..."
  
  # First remove any existing configuration
  claude mcp remove "memory-bank-mcp-server" 2>/dev/null || true
  
  # Add with the connector script that manages container lifecycle
  claude mcp add "memory-bank-mcp-server" "bash" "$PROJECT_ROOT/scripts/memory-bank-connector.sh"
  
  if [ $? -eq 0 ]; then
    echo "✅ Memory Bank MCP Server added to Claude configuration!"
    echo "📁 Data will be stored in: $PROJECT_ROOT/data/memory-bank"
    
    # Print image details
    echo ""
    echo "📊 Memory Bank MCP Image Details:"
    docker images --format "Repository: {{.Repository}}, Tag: {{.Tag}}, Size: {{.Size}}" | grep "memory-bank-mcp"
  else
    echo "⚠️ Failed to add Memory Bank MCP Server to Claude configuration."
  fi
else
  echo "❌ Failed to build Memory Bank MCP Docker image."
  rm -rf "$BUILD_DIR"
  exit 1
fi

echo ""
echo "🎉 Memory Bank MCP Server setup complete!"
echo "You can now use the memory bank functionality in Claude."
echo ""
echo "📝 Usage:"
echo "- Memory bank data will persist in $PROJECT_ROOT/data/memory-bank"
echo "- The container runs with non-root user for security"
echo "- Each Claude session gets a fresh container instance"
