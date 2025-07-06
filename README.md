# Claude MCP Server Toolkit
## Docker-First Configuration Strategy

This toolkit provides a comprehensive Docker-first solution for managing Claude's Model Context Protocol (MCP) servers, enhancing Claude's capabilities with secure, isolated access to external tools and resources.

## Overview

The Claude MCP Server Toolkit implements a Docker-first strategy (per ADR-002) for enhanced security, isolation, and consistency across deployments. The toolkit supports nine Docker-based MCP servers with NPM fallback for Jan.ai integration.

### Supported MCP Servers

1. **Atlassian MCP**: Confluence and Jira integration
2. **GitHub MCP**: Repository management and code operations
3. **Filesystem MCP**: Local file system operations
4. **Git MCP**: Version control operations
5. **Memory MCP**: Persistent memory storage
6. **Browser Tools MCP**: Web automation and testing
7. **Context7 MCP**: Documentation and knowledge retrieval
8. **Fetch MCP**: Web content fetching
9. **Sequential Thinking MCP**: Advanced reasoning capabilities
10. **Jan.ai Integration**: NPM-based fallback (per ADR-002)

## Directory Structure

```
[PROJECT_ROOT]/
├── README.md                  # Main documentation
├── TROUBLESHOOTING.md         # Comprehensive troubleshooting guide
├── setup.sh                   # Main setup script (Docker-first)
├── .env.template              # Environment variables template
├── config/                    # Configuration files
│   └── config.sh              # Environment variables (secure)
├── data/                      # Persistent data storage
│   ├── memory-bank/           # Memory Bank MCP data
│   └── knowledge-graph/       # Knowledge Graph MCP data
├── logs/                      # Log files
├── product-docs/              # Detailed documentation
│   ├── 01-business-case.md    # Business justification
│   ├── 02-implementation-roadmap.md  # Implementation plan
│   ├── 04-prd.md              # Product requirements
│   ├── 05-trd.md              # Technical requirements
│   ├── 06-user-guide.md       # User documentation
│   ├── 07-data-requirements.md  # Data specifications
│   ├── 08-architecture-decisions.md  # ADRs including Docker-first
│   ├── 09-technical-design.md  # Technical specifications
│   ├── 10-operations-guide.md  # Operations procedures
│   ├── 11-contributing.md     # Contribution guidelines
│   └── 13-jira-templates/     # Project management templates
├── scripts/                   # Utility scripts
│   ├── build-memory-bank.sh   # Build Memory Bank Docker image
│   ├── cleanup.sh             # Remove MCP server configurations
│   ├── github-mcp-connector.sh  # GitHub MCP connector
│   ├── health-check.sh        # Docker-aware health checker
│   ├── maintenance.sh         # Docker image updates and maintenance
│   ├── memory-bank-connector.sh  # Memory Bank connector
│   ├── security-audit.sh      # Docker security audit
│   ├── setup-github-token.sh  # GitHub token validator
│   └── sync-env-to-config.sh  # Environment sync utility
└── vscode-integration/        # VS Code integration
    └── start-servers.sh       # Docker-based server starter
```

## Quick Start

### For All Users

Run the automated setup script:

```bash
bash setup.sh
```

This will:
- Verify Docker is installed and running
- Pull or build required Docker images
- Configure environment variables
- Set secure permissions
- Start necessary Docker containers
- Register MCP servers with Claude
- Perform health checks

### Platform-Specific Configuration

#### Claude Desktop

After running `setup.sh`, edit `~/.config/claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "atlassian": {
      "command": "docker",
      "args": ["run", "--rm", "-e", "CONFLUENCE_URL", "-e", "CONFLUENCE_USERNAME", "-e", "CONFLUENCE_API_TOKEN", "-e", "JIRA_URL", "-e", "JIRA_USERNAME", "-e", "JIRA_API_TOKEN", "mcp/atlassian"],
      "env": {
        "CONFLUENCE_URL": "https://your-domain.atlassian.net/wiki",
        "CONFLUENCE_USERNAME": "your-email@domain.com",
        "CONFLUENCE_API_TOKEN": "your_confluence_token",
        "JIRA_URL": "https://your-domain.atlassian.net",
        "JIRA_USERNAME": "your-email@domain.com",
        "JIRA_API_TOKEN": "your_jira_token"
      }
    },
    "github": {
      "command": "bash",
      "args": ["/path/to/scripts/github-mcp-connector.sh"]
    },
    "filesystem": {
      "command": "docker",
      "args": ["run", "--rm", "-v", "/Users:/mnt/users", "-v", "/tmp:/mnt/tmp", "mcp/server-filesystem", "/mnt/users", "/mnt/tmp"]
    },
    "git": {
      "command": "docker",
      "args": ["run", "--rm", "-v", "/path/to/your/repo:/repo", "mcp/server/git"]
    },
    "memory": {
      "command": "docker",
      "args": ["run", "--rm", "-i", "-v", "/path/to/data/memory:/app/data", "mcp/server-memory"]
    },
    "browser-tools": {
      "command": "docker",
      "args": ["run", "--rm", "-i", "mcp/browser-tools-mcp"]
    },
    "context7": {
      "command": "docker",
      "args": ["run", "--rm", "-i", "context7-mcp"]
    },
    "fetch": {
      "command": "docker",
      "args": ["run", "--rm", "-i", "zcaceres/fetch-mcp"]
    },
    "sequential-thinking": {
      "command": "docker",
      "args": ["run", "--rm", "-i", "mcp/sequentialthinking"]
    },
    "memory-bank": {
      "command": "bash",
      "args": ["/path/to/scripts/memory-bank-connector.sh"]
    },
    "jan-ai": {
      "command": "npx",
      "args": ["-y", "jan-mcp-server"],
      "env": {
        "JAN_API_KEY": "your_jan_api_key"
      }
    }
  }
}
```

Replace `/path/to/` with the actual path to your toolkit installation.

#### Claude Code

After running `setup.sh`, create or edit `~/.config/claude-code/mcp.json` with similar Docker-based configuration as above.

#### VS Code/Cline Integration

The setup script automatically configures VS Code integration with a `.vscode/tasks.json` file that calls `vscode-integration/start-servers.sh` on folder open.

### Environment Variables

Create `.env` from the template and add your credentials:

```bash
cp .env.template .env
nano .env
```

Required variables:
- `GITHUB_PERSONAL_ACCESS_TOKEN`: For GitHub MCP server
- Additional tokens for other services as needed

## Docker Image Management

### Pre-built Images

The toolkit uses these Docker images pulled directly from registries:

```bash
docker pull ghcr.io/github/github-mcp-server
docker pull mcp/atlassian
docker pull mcp/server-filesystem
docker pull mcp/server/git
docker pull mcp/server-memory
docker pull mcp/browser-tools-mcp
docker pull zcaceres/fetch-mcp
```

### Custom Build Images

Some MCP servers require custom builds:

1. **Context7 MCP**:
   ```bash
   git clone https://github.com/upstash/context7-mcp.git
   cd context7-mcp
   docker build -t context7-mcp .
   ```

2. **Sequential Thinking MCP**:
   ```bash
   git clone https://github.com/modelcontextprotocol/servers.git
   cd servers
   docker build -t mcp/sequentialthinking -f src/sequentialthinking/Dockerfile .
   ```

3. **Memory Bank MCP** (automated build script):
   ```bash
   bash scripts/build-memory-bank.sh
   ```

## Security Features

This toolkit includes comprehensive security features:

1. **Container Isolation**: Each MCP server runs in its own Docker container
2. **Non-Root Users**: Containers run with least privilege
3. **Volume Security**: Proper permissions for mounted volumes
4. **Token Management**: Secure handling of API tokens
5. **Regular Security Audits**: `scripts/security-audit.sh`
6. **Secure File Permissions**: 600 permissions for sensitive files

## Maintenance

Regular maintenance tasks are automated:

```bash
bash scripts/maintenance.sh
```

This script:
- Updates all Docker images
- Rebuilds custom images from source
- Cleans up unused containers and images
- Performs system health checks
- Rotates logs and backups

## Health Monitoring

Monitor the health of your Docker-based MCP setup:

```bash
bash scripts/health-check.sh
```

This provides detailed status on:
- Docker engine health
- Container status
- Image availability
- Network connectivity
- Configuration validity
- Resource usage

## Troubleshooting

For common issues and solutions, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

Quick fixes for common issues:

### Docker Not Running
```bash
# Start Docker Desktop
open -a Docker
```

### GitHub MCP Container Issues
```bash
# Update container ID in connector script
CONTAINER_ID=$(docker ps --filter ancestor=ghcr.io/github/github-mcp-server --format "{{.ID}}")
sed -i '' "s/CONTAINER_ID=\".*\"/CONTAINER_ID=\"$CONTAINER_ID\"/" scripts/github-mcp-connector.sh
```

### Docker Image Pull Failures
```bash
# Try explicit registry
docker pull docker.io/library/node:18-alpine
```

### Cleaning Up Old Containers
```bash
docker container prune -f
```

## Documentation

For detailed documentation, see the `product-docs/` directory:

- **User Guide**: `product-docs/06-user-guide.md`
- **Operations Guide**: `product-docs/10-operations-guide.md`
- **Architecture Decisions**: `product-docs/08-architecture-decisions.md`
- **Technical Requirements**: `product-docs/05-trd.md`

## Requirements

- **Docker**: Version 20.10.0 or higher
- **Docker Desktop**: For macOS/Windows users
- **Node.js and npm**: Version 16+ (for Jan.ai integration)
- **Git**: For cloning repositories
- **Bash**: For scripts
- **Claude Desktop, Claude Code, or VS Code/Cline**: Target AI platform

## License

See the LICENSE file for details.
