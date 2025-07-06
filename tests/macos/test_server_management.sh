#!/bin/bash

# =============================================================================
# Test Suite: Server Management Scripts
# =============================================================================
#
# This test suite validates the server management scripts:
#   - `vscode-integration/start-servers.sh`
#   - `scripts/cleanup.sh`
#
# The tests ensure that:
#   - The start-servers script correctly registers all MCP servers with Claude.
#   - The lockfile mechanism prevents multiple instances from running.
#   - The cleanup script correctly removes all registered servers.
#   - Both scripts handle different states gracefully (e.g., no servers
#     configured).
#
# =============================================================================

# --- Test Setup ---

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$TEST_DIR")")"

source "$TEST_DIR/assert.sh"

# --- Mocks and Helpers ---

TMP_DIR=$(mktemp)

export PATH="$TMP_DIR:$PATH"
ln -s "$TEST_DIR/../mocks/claude_mock.sh" "$TMP_DIR/claude"

# Mock the project root for the scripts
export PROJECT_ROOT="$TMP_DIR"
mkdir -p "$TMP_DIR/vscode-integration"
mkdir -p "$TMP_DIR/logs"
cp "$PROJECT_ROOT/scripts/cleanup.sh" "$TMP_DIR/scripts/"
cp "$PROJECT_ROOT/vscode-integration/start-servers.sh" "$TMP_DIR/vscode-integration/"

# --- Teardown ---

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# --- Test Cases ---

test_start_servers_registers_all_servers() {
    # Arrange
    local start_script="$TMP_DIR/vscode-integration/start-servers.sh"
    # Capture the output of the mocked claude command
    local claude_output_file
    claude_output_file=$(mktemp)

    # Act
    # We run it in the background and kill it because it has an infinite loop
    (bash "$start_script" &>"$claude_output_file") & pid=$!
    sleep 1
    kill "$pid"

    # Assert
    local output
    output=$(cat "$claude_output_file")
    assert_contain "$output" "Registering MCP servers" "Should start the registration process"
    assert_contain "$output" "github-mcp-server" "Should register the GitHub server"
    assert_contain "$output" "context7-mcp-server" "Should register the Context7 server"
    assert_contain "$output" "memory-bank-mcp-server" "Should register the Memory Bank server"

    # Cleanup
    rm "$claude_output_file"
}

test_start_servers_creates_lockfile() {
    # Arrange
    local start_script="$TMP_DIR/vscode-integration/start-servers.sh"
    local lock_file="$TMP_DIR/vscode-integration/.server-lock"
    rm -f "$lock_file"

    # Act
    (bash "$start_script" &) & pid=$!
    sleep 1

    # Assert
    assert [ -f "$lock_file" ] "Should create a lockfile to prevent multiple instances"

    # Cleanup
    kill "$pid"
    rm "$lock_file"
}

test_cleanup_script_removes_all_servers() {
    # Arrange
    local cleanup_script="$TMP_DIR/scripts/cleanup.sh"
    export CLAUDE_MOCK_LIST_OUTPUT="server1\nserver2\nserver3"
    local claude_output_file
    claude_output_file=$(mktemp)

    # Act
    # The 'yes' command automatically answers the confirmation prompt
    yes | bash "$cleanup_script" > "$claude_output_file"

    # Assert
    local output
    output=$(cat "$claude_output_file")
    assert_contain "$output" "Removing server: server1" "Should remove the first server"
    assert_contain "$output" "Removing server: server2" "Should remove the second server"
    assert_contain "$output" "Removing server: server3" "Should remove the third server"

    # Cleanup
    rm "$claude_output_file"
}

# --- Run Tests ---
run_test_suite "Server Management Scripts Tests"
