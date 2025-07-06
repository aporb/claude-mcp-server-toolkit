#!/bin/bash

# =============================================================================
# Test Suite: setup.sh
# =============================================================================
#
# This test suite validates the functionality of the main `setup.sh` script.
# It uses mock versions of `docker` and `claude` to isolate the script
# and test its logic in a controlled environment.
#
# The tests cover:
#   - Requirement checks (e.g., Docker running).
#   - Correct permission setting for scripts and config files.
#   - Dynamic detection and handling of the GitHub MCP container.
#   - Proper execution of sub-scripts like `sync-env-to-config.sh`.
#
# =============================================================================

# --- Test Setup ---

# Get the directory of the currently executing script
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$TEST_DIR")")"

# Source the assertion library
source "$TEST_DIR/assert.sh"

# Path to the script being tested
SETUP_SCRIPT="$PROJECT_ROOT/setup.sh"

# --- Mocks and Helpers ---

# Create a temporary directory for mock files
TMP_DIR=$(mktemp -d)

# Mock config and script files
export PATH="$TMP_DIR:$PATH"
cp -r "$PROJECT_ROOT/scripts" "$TMP_DIR/"
cp "$PROJECT_ROOT/.env.template" "$TMP_DIR/.env"

# Mock external commands
ln -s "$TEST_DIR/../mocks/docker_mock.sh" "$TMP_DIR/docker"
ln -s "$TEST_DIR/../mocks/claude_mock.sh" "$TMP_DIR/claude"

# --- Teardown ---

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# --- Test Cases ---

test_setup_exits_if_docker_not_running() {
    # Arrange: Configure docker mock to simulate Docker not running
    export DOCKER_MOCK_INFO_EXIT_CODE=1

    # Act: Run the setup script
    local output
    output=$(bash "$SETUP_SCRIPT" 2>&1)
    local exit_code=$?

    # Assert
    assert_equals 1 "$exit_code" "Script should exit with code 1 if Docker is not running"
    assert_contain "$output" "Docker is not running" "Script should output an error message"

    # Cleanup
    unset DOCKER_MOCK_INFO_EXIT_CODE
}

test_setup_succeeds_with_running_container() {
    # Arrange: Simulate a running container
    export DOCKER_MOCK_PS_OUTPUT="0688b8e5847b"

    # Act
    local output
    output=$(bash "$SETUP_SCRIPT" 2>&1)
    local exit_code=$?

    # Assert
    assert_equals 0 "$exit_code" "Script should succeed when container is running"
    assert_contain "$output" "Found running GitHub MCP container" "Should detect the running container"
    assert_contain "$output" "Updated github-mcp-connector.sh" "Should update the connector script"

    # Cleanup
    unset DOCKER_MOCK_PS_OUTPUT
}

test_setup_warns_if_no_container_found() {
    # Arrange: Simulate no running container
    export DOCKER_MOCK_PS_OUTPUT=""

    # Act
    local output
    output=$(bash "$SETUP_SCRIPT" 2>&1)
    local exit_code=$?

    # Assert
    assert_equals 0 "$exit_code" "Script should still succeed even if no container is found"
    assert_contain "$output" "No GitHub MCP container found" "Should warn the user if no container is found"
}

test_setup_sets_executable_permissions() {
    # Arrange
    # Create a dummy script to check permissions on
    local dummy_script="$TMP_DIR/scripts/dummy.sh"
    touch "$dummy_script"
    chmod -x "$dummy_script"

    # Act
    bash "$SETUP_SCRIPT" > /dev/null 2>&1

    # Assert
    assert_is_executable "$dummy_script" "All scripts in the scripts directory should be executable"
}

# --- Run Tests ---
run_test_suite "Setup Script Tests" 
