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

## Global MCP Server Integration

### Configuration Paths

Each platform has specific locations for MCP configuration:

1. **Claude Code**:
   - Linux/macOS: `~/.config/claude-code/mcp.json`
   - Windows: `%APPDATA%/Claude Code/mcp.json`

2. **Claude Desktop**:
   - Linux/macOS: `~/.config/claude/claude_desktop_config.json`
   - Windows: `%APPDATA%/Claude/claude_desktop_config.json`

3. **Cline.bot**:
   - All platforms: `~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`

### Standard Configuration Format

All platforms use a common JSON structure:

```json
{
  "mcpServers": {
    "github": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "-e", "GITHUB_PERSONAL_ACCESS_TOKEN", "ghcr.io/github/github-mcp-server"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "${HOME}/Desktop", "${HOME}/Downloads"]
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    },
    "browser-tools": {
      "command": "npx",
      "args": ["@agentdeskai/browser-tools-mcp@latest"]
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    },
    "puppeteer": {
      "command": "npx",
      "args": ["-y", "puppeteer-mcp-server"]
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    }
  },
  "security": {
    "allowAllMCPToolPermissions": false,
    "requireToolApproval": true,
    "fileSystemAccess": {
      "allowedPaths": ["${HOME}/Desktop", "${HOME}/Downloads", "${HOME}/Documents"],
      "disallowedPaths": ["${HOME}/.ssh", "${HOME}/.config", "${HOME}/.aws"]
    }
  }
}
```

### Global Installation

1. **Install Required Dependencies**:
   ```bash
   # Install Node.js dependencies
   npm install -g @modelcontextprotocol/server-filesystem @modelcontextprotocol/server-memory @agentdeskai/browser-tools-mcp@latest @upstash/context7-mcp@latest puppeteer-mcp-server @modelcontextprotocol/server-sequential-thinking

   # Pull Docker images
   docker pull ghcr.io/github/github-mcp-server
   ```

2. **Configure Environment Variables**:
   Create a `.env` file in your home directory:
   ```bash
   # GitHub integration
   export GITHUB_PERSONAL_ACCESS_TOKEN="your_token_here"

   # Other platform-specific tokens
   export CONFLUENCE_API_TOKEN="your_token_here"
   export JIRA_API_TOKEN="your_token_here"
   ```

3. **Run Configuration Scripts**:
   ```bash
   # Configure all platforms
   bash scripts/configure-claude-code.sh
   bash scripts/configure-claude-desktop.sh
   bash scripts/configure-vscode-cline.sh
   ```

### Security Best Practices

1. **File Permissions**:
   ```bash
   # Set restrictive permissions on config files
   chmod 600 ~/.config/claude-code/mcp.json
   chmod 600 ~/.config/claude/claude_desktop_config.json
   chmod 600 ~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json
   ```

2. **Environment Variables**:
   - Store sensitive tokens in environment variables
   - Use separate tokens for different platforms
   - Regularly rotate tokens
   - Never commit tokens to version control

3. **Access Control**:
   - Configure allowedPaths to limit filesystem access
   - Enable requireToolApproval for sensitive operations
   - Use allowAllMCPToolPermissions=false by default
   - Regularly audit server permissions

### Health Checks

Verify MCP server status across platforms:

```bash
# Check Claude Code servers
claude mcp list

# Check Claude Desktop
bash scripts/health-check.sh

# Check Cline.bot
code --list-extensions | grep claude
```

### Troubleshooting

1. **Server Connection Issues**:
   ```bash
   # Check if servers are running
   ps aux | grep mcp
   docker ps | grep mcp
   ```

2. **Permission Errors**:
   ```bash
   # Fix config file permissions
   chmod 600 ~/.config/claude*/mcp*.json
   ```

3. **Missing Dependencies**:
   ```bash
   # Reinstall Node.js packages
   npm install -g @modelcontextprotocol/server-filesystem @modelcontextprotocol/server-memory

   # Rebuild Docker images
   docker pull ghcr.io/github/github-mcp-server
   ```

4. **Log Analysis**:
   ```bash
   # View server logs
   cat ~/.config/claude/logs/mcp-servers.log
   ```

### Cross-Platform Compatibility

1. **Path Formatting**:
   - Use ${HOME} for user home directory
   - Use forward slashes (/) even on Windows
   - Use environment variables for system paths

2. **Server Commands**:
   - Use npx for Node.js servers
   - Use docker run --rm for containerized servers
   - Set appropriate environment variables

3. **Configuration Sync**:
   - Use scripts/sync-env-to-config.sh to sync settings
   - Maintain consistent security settings
   - Keep server versions aligned

## Global MCP Configuration

The MCP servers can be configured globally across different platforms to ensure consistent capabilities:

### Claude Code Global Configuration

1. **Location**: `~/.config/claude-code/mcp.json` (Linux/macOS) or `%APPDATA%/Claude Code/mcp.json` (Windows)
2. **Configuration**:
   ```bash
   bash scripts/configure-claude-code.sh
   ```
   This will set up MCP servers globally for all Claude Code workspaces.

### Claude Desktop Configuration

1. **Location**: 
   - Linux/macOS: `~/.config/claude/claude_desktop_config.json`
   - Windows: `%APPDATA%/Claude/claude_desktop_config.json`
2. **Configuration**:
   ```bash
   bash scripts/configure-claude-desktop.sh
   ```
   This enables MCP capabilities in the Claude Desktop application.

### Cline.bot Global Configuration

1. **Location**: `~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`
2. **Configuration**:
   ```bash
   bash scripts/configure-vscode-cline.sh
   ```
   This sets up global MCP settings for all VS Code workspaces using Cline.

### Common Configuration Options

All platforms support these core MCP servers:

1. **GitHub Integration**:
   ```json
   {
     "github": {
       "command": "docker",
       "args": ["run", "-i", "--rm", "-e", "GITHUB_PERSONAL_ACCESS_TOKEN", "ghcr.io/github/github-mcp-server"],
       "env": {
         "GITHUB_PERSONAL_ACCESS_TOKEN": "your_token_here"
       }
     }
   }
   ```

2. **Filesystem Access**:
   ```json
   {
     "filesystem": {
       "command": "npx",
       "args": ["-y", "@modelcontextprotocol/server-filesystem", "path1", "path2"]
     }
   }
   ```

3. **Memory Management**:
   ```json
   {
     "memory": {
       "command": "npx",
       "args": ["-y", "@modelcontextprotocol/server-memory"]
     }
   }
   ```

### Security Considerations

When configuring MCPs globally:

1. **File Permissions**:
   - Config files should have 600 permissions (user read/write only)
   - Environment files should be secured similarly

2. **Token Management**:
   - Store tokens in environment variables
   - Use separate tokens for different platforms if needed
   - Regularly rotate tokens

3. **Access Control**:
   - Limit filesystem access to necessary directories
   - Configure allowlists for external API access
   - Enable tool approval requirements where needed


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

1.  **Set environment variables**:
   Copy `.env.template` to `.env` and edit with your credentials. The `GITHUB_PERSONAL_ACCESS_TOKEN` is required.
   ```bash
   cp .env.template .env
   nano .env
   ```

2.  **Run the setup script**:
   This will check requirements, set permissions, and prepare the environment.
   ```bash
   bash setup.sh
   ```

3.  **Build the Memory Bank Docker image**:
   ```bash
   bash scripts/build-memory-bank.sh
   ```

4.  **Start MCP servers**:
   This command will register all the MCP servers with Claude. It's designed to be run in the background, for example, as a VS Code task.
   ```bash
   bash vscode-integration/start-servers.sh
   ```

## Testing

This project includes a comprehensive test suite to ensure the reliability and correctness of the scripts. The suite includes unit, integration, and end-to-end tests.

To run all tests, execute the following command from the project root:
```bash
bash tests/run_tests.sh
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
