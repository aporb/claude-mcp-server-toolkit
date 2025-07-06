# Claude MCP Servers Configuration

This directory contains the configuration and management scripts for Claude's Model Context Protocol (MCP) servers.

## Overview

MCP servers enhance Claude's capabilities by providing access to external tools and resources. This setup includes:

- **GitHub MCP Server**: Integration with GitHub repositories
- **Context7 MCP Server**: Semantic memory capabilities
- **Browser Tools MCP Server**: Web interaction tools
- **Puppeteer MCP Server**: Automated browser control
- **Memory Bank MCP Server**: Persistent memory storage
- **Knowledge Graph MCP Server**: Structured knowledge representation

## Directory Structure

```
[PROJECT_ROOT]/
├── README.md                # Main documentation
├── product-docs/            # Product & project management documents
├── config/                  # Configuration files
│   └── config.sh            # Environment variables
├── data/                    # Persistent data storage
│   ├── memory-bank/         # Memory Bank MCP data
│   └── knowledge-graph/     # Knowledge Graph MCP data
├── logs/                    # Log files
├── scripts/                 # Utility scripts
│   ├── health-check.sh      # Server health check
│   ├── security-audit.sh    # Security audit script
│   ├── maintenance.sh       # Maintenance tasks
│   └── cleanup.sh           # Cleanup script
└── vscode-integration/      # VS Code integration files
    └── start-servers.sh     # VS Code startup script
```

## Quick Start

1. **Set environment variables**:
   Copy `.env.template` to `.env` and edit with your credentials:
   ```bash
   cp .env.template .env
   nano .env
   ```
   The `config/config.sh` file will be generated automatically by `setup.sh`.

2. **Make scripts executable**:
   ```bash
   chmod +x scripts/*.sh vscode-integration/start-servers.sh
   ```

3. **Set secure permissions for the config file**:
   ```bash
   chmod 600 config/config.sh
   ```

4. **Build the Memory Bank Docker image**:
   ```bash
   bash scripts/build-memory-bank.sh
   ```

5. **Start MCP servers**:
   ```bash
   bash vscode-integration/start-servers.sh
   ```

Alternatively, you can run the setup script which will handle steps 2-3:
```bash
bash setup.sh
```

## VS Code Integration

### Automatic Setup

Create a `.vscode/tasks.json` file in your project directory:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Start MCP Servers",
      "type": "shell",
      "command": "bash ${workspaceFolder}/vscode-integration/start-servers.sh",
      "isBackground": true,
      "problemMatcher": [],
      "presentation": {
        "reveal": "never",
        "panel": "dedicated",
        "showReuseMessage": false
      },
      "runOptions": {
        "runOn": "folderOpen"
      }
    }
  ]
}
```

This will automatically start the MCP servers when VS Code opens.

### How It Works

The VS Code integration:
1. Uses a lockfile mechanism to prevent duplicate server instances
2. Ensures proper cleanup when VS Code closes
3. Maintains server registration across VS Code restarts
4. Logs all activities for troubleshooting

## Available MCP Servers

### GitHub MCP Server
- **Purpose**: Interact with GitHub repositories
- **Status**: ✅ **WORKING** - Fixed with proper stdio argument
- **Configuration**: Uses Docker container connector script
- **Requirements**: Docker, GitHub Personal Access Token
- **Connection Method**: 
  - Uses existing Docker container `ghcr.io/github/github-mcp-server`
  - Connector script: `scripts/github-mcp-connector.sh`
  - Container ID: Auto-detected running container

### Context7 MCP Server
- **Purpose**: Semantic memory capabilities
- **Command**: 
  ```bash
  claude mcp add "context7-mcp-server" "npx" "@upstash/context7-mcp@latest"
  ```
- **Requirements**: Node.js, npm

### Browser Tools MCP Server
- **Purpose**: Web interaction tools
- **Command**: 
  ```bash
  claude mcp add "browser-tools-mcp-server" "npx" "@agentdeskai/browser-tools-mcp@latest"
  ```
- **Requirements**: Node.js, npm

### Puppeteer MCP Server
- **Purpose**: Automated browser control
- **Command**: 
  ```bash
  claude mcp add "puppeteer-mcp-server" "npx" "puppeteer-mcp-server"
  ```
- **Requirements**: Node.js, npm

### Memory Bank MCP Server
- **Purpose**: Persistent memory storage  
- **Status**: ✅ **WORKING** - Fixed to prevent multiple containers
- **Configuration**: Uses Docker connector script with --rm flag
- **Requirements**: Docker, memory-bank-mcp:local Docker image
- **Connection Method**:
  - Uses `docker run -i --rm` for clean single-use containers
  - Connector script: `scripts/memory-bank-connector.sh`
  - Build image: `bash scripts/build-memory-bank.sh`

### Knowledge Graph MCP Server
- **Status**: Currently unavailable (package not found in npm registry)
- **Purpose**: Structured knowledge representation
- **Note**: This server is disabled until a working package is available

## Security Considerations

This setup includes several security features:

1. **Environment Variable Protection**:
   - Sensitive data stored in a protected config file
   - Recommended permissions: `chmod 600 config/config.sh`

2. **Lockfile Mechanism**:
   - Prevents duplicate server instances
   - Ensures proper cleanup on termination

3. **Security Audit Script**:
   - Checks for exposed secrets
   - Verifies proper file permissions
   - Validates tokens
   - Reviews auto-approval settings

Run the security audit with:
```bash
bash scripts/security-audit.sh
```

## Maintenance

The maintenance script handles:
- Updating Docker images
- Updating Node.js packages
- Cleaning up Docker resources
- Backing up MCP configurations
- Log rotation

Run maintenance with:
```bash
bash scripts/maintenance.sh
```

## Troubleshooting

### Quick Fixes for Common Issues

#### GitHub MCP Server Connection Failed
**Symptoms**: `✘ failed` status for github-mcp-server in Claude Code

**Solution**:
1. Check if Docker container is running:
   ```bash
   docker ps | grep github-mcp-server
   ```
2. Update container ID in connector script:
   ```bash
   # Find container ID
   CONTAINER_ID=$(docker ps --filter ancestor=ghcr.io/github/github-mcp-server --format "{{.ID}}")
   # Update script
   sed -i '' "s/CONTAINER_ID=\".*\"/CONTAINER_ID=\"$CONTAINER_ID\"/" scripts/github-mcp-connector.sh
   ```
3. Test the connector:
   ```bash
   echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | bash scripts/github-mcp-connector.sh
   ```

#### Memory Bank Multiple Containers Issue
**Symptoms**: Multiple `memory-bank-mcp:local` containers in `docker ps -a`

**Solution**:
1. Clean up old containers:
   ```bash
   docker rm $(docker ps -aq --filter ancestor=memory-bank-mcp:local --filter status=exited)
   ```
2. The updated connector script now uses `--rm` flag to prevent this issue

### General Troubleshooting

If you encounter other issues:

1. **Check the health of your setup**:
   ```bash
   bash scripts/health-check.sh
   ```

2. **Review logs**:
   ```bash
   cat logs/startup.log
   ```

3. **Verify MCP server registration**:
   ```bash
   claude mcp list
   ```

4. **Check for stale lockfiles**:
   ```bash
   ls -la vscode-integration/.server-lock
   ```

5. **Restart the servers**:
   ```bash
   bash scripts/cleanup.sh
   bash vscode-integration/start-servers.sh
   ```

### Claude Code vs Cline Differences

If MCP servers work in Cline/VS Code but not Claude Code:
- **Check stdio argument**: Ensure connector scripts pass `stdio` argument to MCP servers
- **Verify JSON-RPC protocol**: Test with manual JSON-RPC messages
- **Container method**: Claude Code may require different connection approach than VS Code extensions

## Cleanup

To remove all MCP server configurations:
```bash
bash scripts/cleanup.sh
```

## Requirements

- **Docker**: For GitHub MCP Server and Memory Bank MCP Server
- **Node.js and npm**: For Context7, Browser Tools, Puppeteer, and Knowledge Graph MCP servers
- **curl**: For health checks and network connectivity tests
- **VS Code**: For automated startup integration

## Configuration

### GitHub Token Setup

1. Go to GitHub Settings > Developer settings > Personal access tokens
2. Generate a new token with appropriate permissions
3. Update `.env` with your token:
   ```bash
   export GITHUB_PERSONAL_ACCESS_TOKEN="your_actual_token_here"
   ```

### Memory Bank Setup

The Memory Bank MCP server stores data in `data/memory-bank/`. This directory is automatically created and mounted into the Docker container.

### Knowledge Graph Setup

The Knowledge Graph MCP server uses a SQLite database stored in `data/knowledge-graph/kg.db`.

## Common Issues

### Docker Not Running
If you see "Docker is not running" errors:
```bash
# Start Docker Desktop
open -a Docker
```

### Permission Denied
If you get permission errors:
```bash
chmod +x scripts/*.sh vscode-integration/start-servers.sh
chmod 600 config/config.sh
```

### Node.js Not Found
If Node.js is not installed:
```bash
brew install node
```

### MCP Servers Not Registering
Check if Claude CLI is properly installed and configured:
```bash
claude mcp list
```

## Support

For issues with specific MCP servers, refer to their respective documentation:
- [GitHub MCP Server](https://github.com/github/github-mcp-server)
- [Context7 MCP Server](https://github.com/upstash/context7)
- [Browser Tools MCP](https://github.com/AgentDeskAI/browser-tools-mcp)
- [Puppeteer MCP Server](https://github.com/puppeteer/puppeteer)
