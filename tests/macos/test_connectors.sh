#!/bin/bash

# =============================================================================
# Test Suite: Connector Scripts
# =============================================================================
#
# This test suite validates the connector scripts for both the GitHub and
# Memory Bank MCP servers.
#
# The tests ensure that:
#   - The GitHub connector correctly finds a running container and executes
#     the `docker exec` command with the required `stdio` argument.
#   - The Memory Bank connector verifies the existence of the Docker image
#     and correctly executes the `docker run` command.
#   - Both scripts handle error conditions gracefully, such as when a
#     container or image is not found.
#
# =============================================================================

# --- Test Setup ---

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$TEST_DIR")")"

source "$TEST_DIR/assert.sh"

# --- Mocks and Helpers ---

TMP_DIR=$(mktemp -d)

export PATH="$TMP_DIR:$PATH"
ln -s "$TEST_DIR/../mocks/docker_mock.sh" "$TMP_DIR/docker"

# --- Teardown ---

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# --- Test Cases ---

test_github_connector_succeeds_if_container_running() {
    # Arrange
    local connector_script="$PROJECT_ROOT/scripts/github-mcp-connector.sh"
    export DOCKER_MOCK_PS_OUTPUT="0688b8e5847b"

    # Act
    local output
    output=$(bash "$connector_script" stdio 2>&1)
    local exit_code=$?

    # Assert
    assert_equals 0 "$exit_code" "GitHub connector should succeed when container is running"
    assert_contain "$output" "GitHub MCP Server running on stdio" "Should establish a stdio connection"
}

test_github_connector_fails_if_container_not_running() {
    # Arrange
    local connector_script="$PROJECT_ROOT/scripts/github-mcp-connector.sh"
    export DOCKER_MOCK_PS_OUTPUT=""

    # Act
    local output
    output=$(bash "$connector_script" stdio 2>&1)
    local exit_code=$?

    # Assert
    assert_equals 1 "$exit_code" "GitHub connector should fail when container is not running"
    assert_contain "$output" "Error: No running GitHub MCP container found" "Should output a clear error message"
}

test_memory_bank_connector_succeeds_if_image_exists() {
    # Arrange
    local connector_script="$PROJECT_ROOT/scripts/memory-bank-connector.sh"
    export DOCKER_MOCK_IMAGE_INSPECT_EXIT_CODE=0

    # Act
    local output
    output=$(bash "$connector_script" 2>&1)
    local exit_code=$?

    # Assert
    assert_equals 0 "$exit_code" "Memory Bank connector should succeed when image exists"
    assert_contain "$output" "Mocked: docker run" "Should execute the docker run command"
}

test_memory_bank_connector_fails_if_image_missing() {
    # Arrange
    local connector_script="$PROJECT_ROOT/scripts/memory-bank-connector.sh"
    export DOCKER_MOCK_IMAGE_INSPECT_EXIT_CODE=1

    # Act
    local output
    output=$(bash "$connector_script" 2>&1)
    local exit_code=$?

    # Assert
    assert_equals 1 "$exit_code" "Memory Bank connector should fail when image is missing"
    assert_contain "$output" "Error: memory-bank-mcp:local image not found" "Should output a clear error message"
}

# --- Run Tests ---
run_test_suite "Connector Scripts Tests"
