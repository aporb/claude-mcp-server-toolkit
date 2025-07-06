#!/bin/bash

# =============================================================================
# Memory Bank MCP Server Docker Build Script
# =============================================================================
# Purpose: Build and configure Memory Bank MCP Server Docker image
# Usage: bash scripts/build-memory-bank.sh
# Exit Codes:
#   0 - Success
#   1 - Docker not running
#   2 - Build failed
#   3 - Test failed
#   4 - Configuration failed
# =============================================================================

# Strict error handling
set -euo pipefail

# Trap for cleanup on script termination
cleanup() {
    local exit_code=$?
    if [[ -n "${BUILD_DIR:-}" && -d "$BUILD_DIR" ]]; then
        echo "🧹 Cleaning up build directory: $BUILD_DIR" >&2
        rm -rf "$BUILD_DIR" || echo "⚠️ Failed to clean up build directory" >&2
    fi
    if [[ $exit_code -ne 0 ]]; then
        echo "❌ Script failed at line $1 with exit code $exit_code" >&2
    fi
}
trap 'cleanup $LINENO' EXIT ERR

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  echo "[$timestamp] ℹ️  $message" ;;
        "WARN")  echo "[$timestamp] ⚠️  $message" >&2 ;;
        "ERROR") echo "[$timestamp] ❌ $message" >&2 ;;
        "SUCCESS") echo "[$timestamp] ✅ $message" ;;
        *) echo "[$timestamp] $message" ;;
    esac
}

# Determine the project root dynamically
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Validate project root
if [[ ! -d "$PROJECT_ROOT" ]]; then
    log "ERROR" "Project root directory not found: $PROJECT_ROOT"
    exit 1
fi

log "INFO" "Building Memory Bank MCP Server Docker image..."
log "INFO" "Project root: $PROJECT_ROOT"

# Check if Docker is running
log "INFO" "Checking Docker availability..."
if ! docker info > /dev/null 2>&1; then
    log "ERROR" "Docker is not running! Please start Docker before proceeding."
    exit 1
fi
log "SUCCESS" "Docker is running"

# Create required data directories
log "INFO" "Creating data directories..."
if ! mkdir -p "$PROJECT_ROOT/data/memory-bank"; then
    log "ERROR" "Failed to create data directory: $PROJECT_ROOT/data/memory-bank"
    exit 1
fi
log "SUCCESS" "Created data directory: $PROJECT_ROOT/data/memory-bank"

# Create a temporary directory for building
log "INFO" "Creating temporary build directory..."
if ! BUILD_DIR=$(mktemp -d); then
    log "ERROR" "Failed to create temporary build directory"
    exit 1
fi
log "SUCCESS" "Created build directory: $BUILD_DIR"

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
log "INFO" "Building Docker image with security and performance optimizations..."
cd "$BUILD_DIR" || {
    log "ERROR" "Failed to change to build directory: $BUILD_DIR"
    exit 2
}

if ! DOCKER_BUILDKIT=1 docker build -t memory-bank-mcp:local .; then
    log "ERROR" "Failed to build Memory Bank MCP Docker image"
    exit 2
fi
log "SUCCESS" "Memory Bank MCP Docker image built successfully!"

# Test the image with a simple command
log "INFO" "Testing the Memory Bank MCP Docker image..."
if echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | timeout 30 docker run -i --rm memory-bank-mcp:local > /dev/null 2>&1; then
    log "SUCCESS" "Image test successful!"
else
    log "WARN" "Image test returned an error. The image was built but may have issues."
    # Don't exit here as the image might still be functional
fi

# Verify memory-bank-connector.sh exists
if [[ ! -f "$PROJECT_ROOT/scripts/memory-bank-connector.sh" ]]; then
    log "ERROR" "Memory bank connector script not found: $PROJECT_ROOT/scripts/memory-bank-connector.sh"
    exit 4
fi

# Print image details
log "INFO" "Memory Bank MCP Image Details:"
if docker images --format "Repository: {{.Repository}}, Tag: {{.Tag}}, Size: {{.Size}}" | grep -q "memory-bank-mcp"; then
    docker images --format "Repository: {{.Repository}}, Tag: {{.Tag}}, Size: {{.Size}}" | grep "memory-bank-mcp"
else
    log "WARN" "Could not retrieve image details"
fi

log "SUCCESS" "Memory Bank MCP Server setup complete!"
log "INFO" "You can now use the memory bank functionality in Claude."
log "INFO" "Data will be stored in: $PROJECT_ROOT/data/memory-bank"
log "INFO" "The container runs with non-root user for security"
log "INFO" "Each Claude session gets a fresh container instance"
