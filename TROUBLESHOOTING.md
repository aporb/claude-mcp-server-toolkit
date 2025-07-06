# MCP Servers Troubleshooting Guide

This guide provides solutions to common issues encountered with MCP servers in Claude Code.

## Quick Diagnostics

### Check MCP Server Status
```bash
# In Claude Code
/mcp

# Or via command line
claude mcp list
```

### Test Docker Containers
```bash
# List running containers
docker ps

# Check GitHub MCP server specifically
docker ps --filter ancestor=ghcr.io/github/github-mcp-server

# Check memory bank containers
docker ps -a --filter ancestor=memory-bank-mcp:local
```

## GitHub MCP Server Issues

### Problem: ✘ failed status in Claude Code

**Most Common Cause**: Missing `stdio` argument in connector script

**Symptoms**:
- GitHub MCP server shows as failed in `/mcp`
- Works in Cline/VS Code but not Claude Code
- Container is running but not responding

**Solution**:
1. **Verify the connector script has the stdio argument**:
   ```bash
   cat scripts/github-mcp-connector.sh
   # Should show: exec docker exec -i "$CONTAINER_ID" /server/github-mcp-server stdio "$@"
   ```

2. **Test the connector manually**:
   ```bash
   echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | bash scripts/github-mcp-connector.sh
   ```

3. **Expected response** (server is working):
   ```
   GitHub MCP Server running on stdio
   {"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2024-11-05",...}}
   ```

4. **If you get help text instead** (missing stdio):
   ```
   A GitHub MCP server that handles various tools and resources.
   Usage:
   ```

### Problem: Container ID mismatch

**Symptoms**:
- Error: "GitHub MCP container [ID] is not running"
- Container exists but has different ID

**Solution**:
1. **Find the correct container ID**:
   ```bash
   docker ps --filter ancestor=ghcr.io/github/github-mcp-server --format "{{.ID}}"
   ```

2. **Update the connector script**:
   ```bash
   # Automatic update
   CONTAINER_ID=$(docker ps --filter ancestor=ghcr.io/github/github-mcp-server --format "{{.ID}}")
   sed -i '' "s/CONTAINER_ID=\".*\"/CONTAINER_ID=\"$CONTAINER_ID\"/" scripts/github-mcp-connector.sh
   ```

### Problem: No GitHub token or permission denied

**Symptoms**:
- "GITHUB_PERSONAL_ACCESS_TOKEN not set" 
- API permission errors

**Solution**:
1. **Check token in container**:
   ```bash
   docker inspect [CONTAINER_ID] --format='{{range .Config.Env}}{{println .}}{{end}}' | grep GITHUB
   ```

2. **Restart container with token**:
   ```bash
   docker run -d -e GITHUB_PERSONAL_ACCESS_TOKEN=your_token ghcr.io/github/github-mcp-server
   ```

## Memory Bank MCP Server Issues

### Problem: Multiple containers accumulating

**Symptoms**:
- Many exited memory-bank-mcp:local containers in `docker ps -a`
- Performance degradation

**Solution** (FIXED):
1. **Clean up existing containers**:
   ```bash
   docker rm $(docker ps -aq --filter ancestor=memory-bank-mcp:local --filter status=exited)
   ```

2. **The updated connector now uses `--rm` flag** to prevent this issue:
   ```bash
   # New approach in memory-bank-connector.sh
   exec docker run -i --rm memory-bank-mcp:local "$@"
   ```

### Problem: Image not found

**Symptoms**:
- "memory-bank-mcp:local image not found"

**Solution**:
1. **Build the image**:
   ```bash
   bash scripts/build-memory-bank.sh
   ```

2. **Verify image exists**:
   ```bash
   docker images | grep memory-bank-mcp
   ```

## Claude Code vs Cline/VS Code Differences

### Key Differences

| Aspect | Claude Code | Cline/VS Code |
|--------|-------------|---------------|
| **Protocol** | Strict JSON-RPC over stdio | More tolerant |
| **Arguments** | Requires explicit `stdio` argument | May work without |
| **Connection** | New process per request | Persistent connections |
| **Error Handling** | Fails fast on protocol errors | More forgiving |

### Problem: Works in Cline but not Claude Code

**Root Causes**:
1. **Missing stdio argument** - Most common issue
2. **Different environment variables** 
3. **Container lifecycle differences**

**Debugging Steps**:
1. **Test connector script directly**:
   ```bash
   echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | bash scripts/github-mcp-connector.sh
   ```

2. **Compare configurations**:
   - Check Cline configuration in VS Code settings
   - Compare with Claude Code MCP configuration in `.claude.json`

3. **Protocol validation**:
   ```bash
   # Should return JSON, not help text
   echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | timeout 5 bash scripts/github-mcp-connector.sh
   ```

## General MCP Troubleshooting

### Problem: MCP servers not connecting

**Checklist**:
1. **Docker running**: `docker info`
2. **Correct scripts**: Check connector scripts have proper shebang and permissions
3. **Claude Code version**: Ensure latest version with MCP support
4. **Configuration syntax**: Validate JSON in `.claude.json`

### Problem: Permission denied errors

**Solution**:
```bash
# Fix script permissions
chmod +x scripts/*.sh

# Check Claude Code has docker access
docker ps
```

### Problem: Network/connectivity issues

**Symptoms**:
- Timeouts connecting to containers
- Intermittent failures

**Solution**:
1. **Restart Docker**:
   ```bash
   osascript -e 'quit app "Docker"'
   open -a Docker
   ```

2. **Check Docker networks**:
   ```bash
   docker network ls
   docker network inspect bridge
   ```

## Advanced Debugging

### Enable MCP Debug Mode
```bash
# Start Claude Code with MCP debugging
claude --mcp-debug
```

### Manual Protocol Testing
```bash
# Test exact protocol flow
(
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
echo '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'
) | bash scripts/github-mcp-connector.sh
```

### Container Debugging
```bash
# Get detailed container info
docker inspect [CONTAINER_ID]

# Check container logs
docker logs [CONTAINER_ID]

# Interactive shell in container
docker exec -it [CONTAINER_ID] /bin/sh
```

## Logs and Monitoring

### Claude Code Logs
```bash
# Check Claude Code cache/logs
ls -la ~/.cache/claude-cli-nodejs/

# MCP server specific logs
ls -la ~/.cache/claude-cli-nodejs/mcp-logs/
```

### Health Check Script
```bash
bash scripts/health-check.sh
```

## When to Restart Services

**Restart Claude Code**: After configuration changes
**Restart Docker**: Network or container lifecycle issues  
**Rebuild containers**: After image updates or corruption

## Getting Help

1. **Check this troubleshooting guide first**
2. **Run health check**: `bash scripts/health-check.sh`
3. **Check logs**: Review recent log files in logs/ directory
4. **Test manually**: Use protocol testing commands above
5. **Create issue**: Include logs, configuration, and test results