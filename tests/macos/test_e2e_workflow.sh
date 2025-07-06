#!/bin/bash

# =============================================================================
# Test Suite: End-to-End Workflow
# =============================================================================
#
# This test suite validates the entire user workflow from start to finish.
# It does not use mocks and requires a functional environment with Docker
# and the Claude CLI installed.
#
# The test performs the following steps:
#   1. Starts from a clean state.
#   2. Runs the main `setup.sh` script.
#   3. Builds the Memory Bank Docker image.
#   4. Starts the MCP servers using the VS Code integration script.
#   5. Performs a health check to verify the setup.
#   6. Cleans up the environment by removing all registered servers.
#
# This test provides the highest level of confidence that the entire system
# is working correctly.
#
# =============================================================================

# --- Test Setup ---

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$TEST_DIR")")"

source "$TEST_DIR/assert.sh"

# --- Pre-flight Checks ---

if ! command -v docker &> /dev/null || ! docker info &> /dev/null; then
    echo "Error: Docker is not running. This test requires a live Docker environment." >&2
    exit 1
fi

if ! command -v claude &> /dev/null; then
    echo "Error: The 'claude' CLI is not installed. This test requires a live Claude environment." >&2
    exit 1
fi

# --- Test Workflow ---

test_full_e2e_workflow() {
    # Step 1: Initial Cleanup (to ensure a clean state)
    echo "--- E2E Step 1: Cleaning up environment ---"
    yes | bash "$PROJECT_ROOT/scripts/cleanup.sh" > /dev/null 2>&1
    docker rm -f $(docker ps -aq --filter ancestor=memory-bank-mcp:local) > /dev/null 2>&1
    docker image rm -f memory-bank-mcp:local > /dev/null 2>&1
    echo "Cleanup complete."

    # Step 2: Run Setup Script
    echo "--- E2E Step 2: Running setup.sh ---"
    local setup_output
    setup_output=$(bash "$PROJECT_ROOT/setup.sh" 2>&1)
    assert_equals 0 $? "setup.sh should complete successfully"
    assert_contain "$setup_output" "Setup complete!" "Should display setup complete message"

    # Step 3: Build Memory Bank Image
    echo "--- E2E Step 3: Building Memory Bank image ---"
    local build_output
    build_output=$(bash "$PROJECT_ROOT/scripts/build-memory-bank.sh" 2>&1)
    assert_equals 0 $? "build-memory-bank.sh should complete successfully"
    assert_contain "$build_output" "Memory Bank MCP Docker image built successfully" "Should confirm image build"

    # Step 4: Start Servers
    echo "--- E2E Step 4: Starting MCP servers ---"
    (bash "$PROJECT_ROOT/vscode-integration/start-servers.sh" &) & pid=$!
    sleep 5 # Give servers time to register

    # Step 5: Health Check
    echo "--- E2E Step 5: Performing health check ---"
    local health_output
    health_output=$(claude mcp list)
    assert_contain "$health_output" "github-mcp-server" "GitHub server should be registered"
    assert_contain "$health_output" "memory-bank-mcp-server" "Memory Bank server should be registered"

    # Step 6: Final Cleanup
    echo "--- E2E Step 6: Final cleanup ---"
    kill "$pid"
    yes | bash "$PROJECT_ROOT/scripts/cleanup.sh" > /dev/null 2>&1
    echo "E2E test complete."
}

# --- Run Tests ---
run_test_suite "End-to-End Workflow Test"
