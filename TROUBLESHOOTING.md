# Troubleshooting Guide
## Claude MCP Servers (Docker-First Strategy)

This document provides solutions for common issues encountered when setting up and using the Claude MCP Server Toolkit with the Docker-first strategy.

## Claude Desktop MCP Issues

### MCP Server Not Showing in Claude Desktop

**Prerequisites:**
- NodeJS installed (download from [nodejs.org](https://nodejs.org))
- Python installed (download from [python.org](https://python.org))
- MCP enabled in Settings > MCP Servers
- "Allow All MCP Tool Permission" switch turned ON

### MCP Server Connection Issues

**Symptoms:**
- MCP slider icon missing in Claude Desktop
- Tools not appearing after clicking the slider icon
- "No MCP servers available" message

**Solutions:**
1. Check Claude Desktop configuration:
   ```bash
   # macOS
   cat ~/Library/Application\ Support/Claude/claude_desktop_config.json
   # Windows
   type "%APPDATA%\Claude\claude_desktop_config.json"
   ```

2. Verify Node.js installation:
   ```bash
   node --version  # Should be 14.0.0 or higher
   npm --version   # Should be installed
   ```

3. Check filesystem server installation:
   ```bash
   npx -y @modelcontextprotocol/server-filesystem --version
   ```

4. Run configuration script:
   ```bash
   ./scripts/configure-claude-desktop.sh
   ```

### MCP Security Considerations

**Important Security Notes:**
- Each MCP server must be enabled individually for security
- Tool permissions should be granted selectively
- File system access is restricted to allowed directories only
- Sensitive directories (.ssh, .aws, etc.) are blocked by default
- All MCP servers are disabled by default for security

### Browser MCP Setup

**Requirements:**
1. Chrome-based browser (Chrome, Brave, Edge, etc.)
2. Browser MCP Extension installed
3. Extension enabled for private windows
4. Model with tool calling capabilities enabled

**Setup Steps:**
1. Install Browser MCP:
   ```bash
   npm install -g @browsermcp/mcp
   ```
2. Configure in Claude Desktop:
   ```bash
   ./scripts/configure-claude-desktop.sh
   ```
3. Install browser extension from Chrome Web Store
4. Enable extension for private windows
5. Connect extension to Browser MCP server

### Configuration File Issues

**Symptoms:**
- "Invalid configuration" error in Claude Desktop
- Configuration changes not taking effect
- Permission denied errors

**Solutions:**
1. Fix configuration file permissions:
   ```bash
   # macOS
   chmod 600 ~/Library/Application\ Support/Claude/claude_desktop_config.json
   # Windows
   icacls "%APPDATA%\Claude\claude_desktop_config.json" /inheritance:r /grant:r "%USERNAME%:F"
   ```

2. Validate configuration JSON:
   ```bash
   # macOS
   jq '.' ~/Library/Application\ Support/Claude/claude_desktop_config.json
   # Windows
   type "%APPDATA%\Claude\claude_desktop_config.json" | jq '.'
   ```

3. Reset configuration:
   ```bash
   ./scripts/configure-claude-desktop.sh --reset
   ```

### Filesystem Access Issues

**Symptoms:**
- "Permission denied" when accessing files
- Cannot read/write files in specified directories
- Missing directories in file operations

**Solutions:**
1. Verify directory permissions:
   ```bash
   # Check Desktop permissions
   ls -la ~/Desktop
   # Check Downloads permissions
   ls -la ~/Downloads
   ```

2. Update allowed directories:
   ```bash
   ./scripts/configure-claude-desktop.sh configure
   ```

3. Check Claude Desktop logs:
   ```bash
   # macOS
   tail -f ~/Library/Logs/Claude/mcp*.log
   # Windows
   type "%APPDATA%\Claude\logs\mcp*.log"
   ```

### Node.js Package Issues

**Symptoms:**
- "Cannot find module" errors
- NPM package installation failures
- Version compatibility issues

**Solutions:**
1. Reinstall filesystem server globally:
   ```bash
   npm uninstall -g @modelcontextprotocol/server-filesystem
   npm install -g @modelcontextprotocol/server-filesystem
   ```

2. Clear NPM cache:
   ```bash
   npm cache clean --force
   ```

3. Check for global package conflicts:
   ```bash
   npm ls -g @modelcontextprotocol/server-filesystem
   ```

### Claude Desktop Update Issues

**Symptoms:**
- MCP features stop working after Claude Desktop update
- Configuration reset after update
- Version mismatch errors

**Solutions:**
1. Check Claude Desktop version:
   ```bash
   # Click Claude menu > About Claude
   # Or check app version in Activity Monitor/Task Manager
   ```

2. Reconfigure after update:
   ```bash
   ./scripts/configure-claude-desktop.sh
   ```

3. Clear Claude Desktop cache:
   ```bash
   # macOS
   rm -rf ~/Library/Application\ Support/Claude/Cache/*
   # Windows
   del /s /q "%APPDATA%\Claude\Cache\*"
   ```

4. Verify MCP server versions match Claude Desktop requirements:
   ```bash
   npm info @modelcontextprotocol/server-filesystem version
   ```


## Table of Contents

1. [Claude Desktop MCP Issues](#claude-desktop-mcp-issues)
2. [Docker-Related Issues](#docker-related-issues)
3. [GitHub MCP Server Issues](#github-mcp-server-issues)
4. [Memory Bank MCP Issues](#memory-bank-mcp-issues)
4. [Custom Build Images Issues](#custom-build-images-issues)
5. [Environment and Configuration Issues](#environment-and-configuration-issues)
6. [MCP Server Registration Issues](#mcp-server-registration-issues)
7. [Performance Issues](#performance-issues)
8. [Platform-Specific Issues](#platform-specific-issues)
9. [Advanced Troubleshooting](#advanced-troubleshooting)

---

## Docker-Related Issues

### Docker Not Running

**Symptoms:**
- "Docker is not running" error message
- `docker: Cannot connect to the Docker daemon` error

**Solutions:**
1. Open Docker Desktop application
2. Verify Docker service is running: `docker info`
3. Restart Docker: 
   ```bash
   # macOS/Linux
   killall Docker && open -a Docker
   
   # Windows
   Restart-Service docker
   ```

### Docker Image Pull Failures

**Symptoms:**
- "Failed to pull image" error
- Network timeout errors

**Solutions:**
1. Check internet connection
2. Verify Docker Hub is accessible: `curl -s https://registry.hub.docker.com/v2/`
3. Try with explicit registry: 
   ```bash
   docker pull docker.io/library/node:18-alpine
   ```
4. Use alternative network:
   ```bash
   # Try using a different DNS
   sudo networksetup -setdnsservers Wi-Fi 8.8.8.8 8.8.4.4
   ```

### Docker Image Build Failures

**Symptoms:**
- "Build failed" error during `build-memory-bank.sh` or custom image builds
- Error in Docker build logs

**Solutions:**
1. Check for available disk space: `docker system df`
2. Clean up Docker resources: `docker system prune -f`
3. Verify Dockerfile syntax
4. Build with verbose output: 
   ```bash
   DOCKER_BUILDKIT=0 docker build -t memory-bank-mcp:local .
   ```
5. Try disabling BuildKit if issues persist:
   ```bash
   DOCKER_BUILDKIT=0 docker build -t memory-bank-mcp:local .
   ```

### Docker Permission Issues

**Symptoms:**
- "Permission denied" errors
- Cannot access mounted volumes

**Solutions:**
1. Check user permissions for Docker: `groups | grep docker`
2. Fix volume permissions:
   ```bash
   sudo chown -R $(whoami) data/memory-bank
   ```
3. Restart Docker with proper permissions:
   ```bash
   sudo systemctl restart docker
   ```

---

## GitHub MCP Server Issues

### GitHub Container Not Starting

**Symptoms:**
- "Failed to start GitHub MCP container" error
- No container ID returned

**Solutions:**
1. Verify GitHub token is set in `.env` file
2. Check token validity using `scripts/setup-github-token.sh`
3. Start container manually with debugging:
   ```bash
   docker run --name github-mcp -e GITHUB_PERSONAL_ACCESS_TOKEN=your_token -it ghcr.io/github/github-mcp-server
   ```
4. Check Docker logs:
   ```bash
   docker logs $(docker ps -q --filter ancestor=ghcr.io/github/github-mcp-server)
   ```

### GitHub MCP Connector Failure

**Symptoms:**
- "GitHub MCP connector test failed" error
- No response from connector script

**Solutions:**
1. Check container ID in `scripts/github-mcp-connector.sh`
2. Update container ID manually:
   ```bash
   # Get current container ID
   CONTAINER_ID=$(docker ps --filter ancestor=ghcr.io/github/github-mcp-server --format "{{.ID}}")
   
   # Update script
   sed -i '' "s/CONTAINER_ID=\".*\"/CONTAINER_ID=\"$CONTAINER_ID\"/" scripts/github-mcp-connector.sh
   ```
3. Restart container:
   ```bash
   docker restart $CONTAINER_ID
   ```
4. Test connector directly:
   ```bash
   echo '{"jsonrpc":"2.0","id":1,"method":"initialize"}' | bash scripts/github-mcp-connector.sh
   ```

### GitHub API Authentication Issues

**Symptoms:**
- "Authentication failed" errors
- 401 Unauthorized responses

**Solutions:**
1. Verify token has not expired in GitHub settings
2. Check token permissions (needs repo access)
3. Create a new token: [GitHub Token Settings](https://github.com/settings/tokens)
4. Update token in `.env` and run `scripts/sync-env-to-config.sh`

---

## Memory Bank MCP Issues

### Memory Bank Image Build Failure

**Symptoms:**
- Error during `build-memory-bank.sh`
- Node.js related errors

**Solutions:**
1. Check Node.js version: `node --version` (should be 16+)
2. Manually build with debugging:
   ```bash
   # Create Dockerfile
   cat > Dockerfile << 'EOF'
   FROM node:18-alpine
   RUN npm install -g @modelcontextprotocol/server-memory
   WORKDIR /app
   CMD ["npx", "@modelcontextprotocol/server-memory"]
   EOF
   
   # Build
   docker build -t memory-bank-mcp:local .
   ```
3. Check npm registry access: `curl -s https://registry.npmjs.org/`

### Memory Bank Data Persistence Issues

**Symptoms:**
- Data not persisting between sessions
- "Memory file not found" errors

**Solutions:**
1. Verify data directory exists: `mkdir -p data/memory-bank`
2. Check permissions: `chmod 755 data/memory-bank`
3. Test volume mounting:
   ```bash
   docker run --rm -i -v "$(pwd)/data/memory-bank:/app/data" memory-bank-mcp:local
   ```
4. Create test file in volume:
   ```bash
   echo '{"test": true}' > data/memory-bank/test.json
   ```

### Memory Bank Connection Errors

**Symptoms:**
- Timeout when connecting to Memory Bank MCP
- Claude returns "Server unavailable" errors

**Solutions:**
1. Verify image exists: `docker images | grep memory-bank-mcp`
2. Test connector script directly:
   ```bash
   echo '{"jsonrpc":"2.0","id":1,"method":"initialize"}' | bash scripts/memory-bank-connector.sh
   ```
3. Rebuild image: `bash scripts/build-memory-bank.sh`
4. Check logs: `scripts/memory-bank-connector.sh 2>&1 | tee memory-bank-debug.log`

---

## Custom Build Images Issues

### Context7 MCP Build Issues

**Symptoms:**
- Context7 image not available
- Build errors from Context7 repository

**Solutions:**
1. Clone repository and build manually:
   ```bash
   git clone https://github.com/upstash/context7-mcp.git
   cd context7-mcp
   docker build -t context7-mcp .
   ```
2. Check for image with alternate tags:
   ```bash
   docker images | grep context7
   ```
3. Fall back to NPM version temporarily:
   ```bash
   claude mcp add "context7-mcp-server" "npx" "-y @upstash/context7-mcp@latest"
   ```

### Sequential Thinking MCP Build Issues

**Symptoms:**
- Sequential Thinking image not available
- Build errors from MCP servers repository

**Solutions:**
1. Clone repository and build manually:
   ```bash
   git clone https://github.com/modelcontextprotocol/servers.git
   cd servers
   docker build -t mcp/sequentialthinking -f src/sequentialthinking/Dockerfile .
   ```
2. Check for image with alternate tags:
   ```bash
   docker images | grep sequentialthinking
   ```
3. Fall back to NPM version temporarily:
   ```bash
   claude mcp add "sequential-thinking-mcp-server" "npx" "-y @modelcontextprotocol/server-sequential-thinking"
   ```

---

## Environment and Configuration Issues

### Missing Environment Variables

**Symptoms:**
- "No environment configuration found" error
- Services failing due to missing credentials

**Solutions:**
1. Create `.env` from template:
   ```bash
   cp .env.template .env
   ```
2. Add required credentials to `.env`
3. Run: `bash scripts/sync-env-to-config.sh`
4. Verify config: `cat config/config.sh | grep -v PASSWORD | grep -v TOKEN`

### Configuration File Permission Issues

**Symptoms:**
- "Permission denied" when accessing config
- Security warnings about loose permissions

**Solutions:**
1. Set correct permissions:
   ```bash
   chmod 600 .env config/config.sh
   ```
2. Check current permissions:
   ```bash
   ls -la .env config/config.sh
   ```
3. Verify ownership:
   ```bash
   chown $(whoami) .env config/config.sh
   ```

---

## MCP Server Registration Issues

### Claude MCP Commands Not Found

**Symptoms:**
- "claude: command not found" error
- "mcp: unknown command" error

**Solutions:**
1. Verify Claude CLI is installed: `which claude`
2. Check Claude version: `claude --version`
3. Reinstall Claude CLI if needed
4. Restart terminal or source profile: `source ~/.bash_profile`

### MCP Server Registration Failures

**Symptoms:**
- "Failed to add MCP server" error
- Server not appearing in `claude mcp list`

**Solutions:**
1. Remove and re-add server:
   ```bash
   claude mcp remove "github-mcp-server"
   claude mcp add "github-mcp-server" "bash" "scripts/github-mcp-connector.sh"
   ```
2. Verify Claude configuration location:
   ```bash
   ls -la ~/.config/claude
   ```
3. Reset all servers and start fresh:
   ```bash
   claude mcp clear
   bash vscode-integration/start-servers.sh
   ```

---

## Performance Issues

### Slow Docker Operations

**Symptoms:**
- Docker commands taking too long
- Image pulls timing out

**Solutions:**
1. Check Docker resource allocation (CPU/Memory)
2. Clean up unused resources:
   ```bash
   docker system prune -f
   ```
3. Check disk space: `df -h`
4. Increase Docker resource limits in Docker Desktop settings

### High CPU/Memory Usage

**Symptoms:**
- System slowdowns when running MCP servers
- Docker Desktop showing high resource usage

**Solutions:**
1. Monitor container resources:
   ```bash
   docker stats
   ```
2. Limit container resources:
   ```bash
   docker run --memory=512m --cpus=1 -d -e GITHUB_PERSONAL_ACCESS_TOKEN=token ghcr.io/github/github-mcp-server
   ```
3. Stop unnecessary containers:
   ```bash
   docker ps -q | xargs docker stop
   ```

---

## Platform-Specific Issues

### macOS-Specific Issues

**Symptoms:**
- `sed` command errors on macOS
- Permission issues with Docker Desktop

**Solutions:**
1. Use compatible `sed` syntax:
   ```bash
   sed -i '' "s/pattern/replacement/" file
   ```
2. Allow Docker Desktop in System Preferences > Security & Privacy
3. Check for macOS file permission issues:
   ```bash
   ls -la@ data/memory-bank  # Look for extended attributes
   ```

### Windows-Specific Issues

**Symptoms:**
- Path separator issues
- WSL integration problems

**Solutions:**
1. Use WSL2 for Docker Desktop
2. Convert paths properly:
   ```bash
   # In WSL
   wslpath -a "C:\path\to\folder"
   ```
3. Check Docker Desktop WSL integration settings
4. Run scripts with proper interpreter:
   ```bash
   bash -c "./scripts/setup.sh"
   ```

### Linux-Specific Issues

**Symptoms:**
- Permission denied for Docker socket
- Container runtime issues

**Solutions:**
1. Add user to docker group:
   ```bash
   sudo usermod -aG docker $USER
   newgrp docker  # Apply group changes
   ```
2. Fix Docker socket permissions:
   ```bash
   sudo chmod 666 /var/run/docker.sock
   ```
3. Check SELinux/AppArmor settings if containers can't access files

---

## Advanced Troubleshooting

### Enabling Debug Logs

For more detailed troubleshooting:

```bash
# Enable Docker debug
export DOCKER_DEBUG=1

# Run setup with debug output
bash -x setup.sh

# Debug Claude MCP communication
claude --debug mcp list

# Log connector script output
bash scripts/github-mcp-connector.sh 2>&1 | tee github-debug.log
```

### Verifying MCP Protocol Communication

Test raw MCP protocol communication:

```bash
# Initialize GitHub MCP Server
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | bash scripts/github-mcp-connector.sh

# Initialize Memory Bank MCP Server
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | docker run -i --rm memory-bank-mcp:local
```

### Reset Everything and Start Fresh

If all else fails:

```bash
# Stop all Docker containers
docker ps -qa | xargs docker stop

# Remove all containers
docker ps -qa | xargs docker rm

# Remove MCP images
docker images "mcp/*" -q | xargs docker rmi -f
docker images "memory-bank-mcp" -q | xargs docker rmi -f
docker images "context7-mcp" -q | xargs docker rmi -f

# Remove Claude MCP configurations
claude mcp clear

# Start fresh setup
bash setup.sh
```

---

If issues persist after trying these solutions, please:

1. Run the health check: `bash scripts/health-check.sh`
2. Run the security audit: `bash scripts/security-audit.sh`
3. Check the logs in the `logs/` directory
4. Create a GitHub issue with the output of these commands
