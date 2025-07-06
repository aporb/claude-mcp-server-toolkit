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

# Create a temporary directory for building
BUILD_DIR=$(mktemp -d)
echo "Creating build directory: $BUILD_DIR"

# Create Dockerfile for Memory Bank MCP Server
cat > "$BUILD_DIR/Dockerfile" << 'EOF'
FROM node:18-alpine

# Install dependencies
RUN npm install -g @modelcontextprotocol/server-memory

# Create app directory
WORKDIR /app

# Create memory bank directory
RUN mkdir -p /mnt/memory_bank

# Set environment variables
ENV MEMORY_FILE_PATH=/mnt/memory_bank/memory.json

# Expose the server
CMD ["npx", "@modelcontextprotocol/server-memory"]
EOF

# Create package.json
cat > "$BUILD_DIR/package.json" << 'EOF'
{
  "name": "memory-bank-mcp",
  "version": "1.0.0",
  "description": "Memory Bank MCP Server",
  "dependencies": {
    "@modelcontextprotocol/server-memory": "latest"
  }
}
EOF

# Build the Docker image
echo "Building Docker image..."
cd "$BUILD_DIR"
docker build -t memory-bank-mcp:local .

if [ $? -eq 0 ]; then
  # Clean up build directory
  rm -rf "$BUILD_DIR"
else
  echo "❌ Failed to build Memory Bank MCP Docker image."
  rm -rf "$BUILD_DIR"
  exit 1
fi

echo ""
echo "Memory Bank MCP Server setup complete!"
echo "You can now use the memory bank functionality in Claude."
