#!/bin/bash

# =============================================================================
# Test Suite: Utility Scripts
# =============================================================================
#
# This test suite validates the utility scripts:
#   - `health-check.sh`
#   - `maintenance.sh`
#   - `security-audit.sh`
#
# The tests ensure that:
#   - The health check correctly identifies missing dependencies and configs.
#   - The maintenance script performs its update and cleanup tasks.
#   - The security audit correctly checks file permissions and tokens.
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
ln -s "$TEST_DIR/../mocks/claude_mock.sh" "$TMP_DIR/claude"

# Mock other commands
ln -s "$(which true)" "$TMP_DIR/npm"
ln -s "$(which true)" "$TMP_DIR/curl"

export PROJECT_ROOT="$TMP_DIR"
mkdir -p "$TMP_DIR/config"
mkdir -p "$TMP_DIR/data/memory-bank"
mkdir -p "$TMP_DIR/data/knowledge-graph"
mkdir -p "$TMP_DIR/logs"
cp "$PROJECT_ROOT/scripts/health-check.sh" "$TMP_DIR/scripts/"
cp "$PROJECT_ROOT/scripts/maintenance.sh" "$TMP_DIR/scripts/"
cp "$PROJECT_ROOT/scripts/security-audit.sh" "$TMP_DIR/scripts/"

# --- Teardown ---

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# --- Test Cases ---

test_health_check_passes_with_good_environment() {
    # Arrange
    local health_check_script="$TMP_DIR/scripts/health-check.sh"
    echo "GITHUB_PERSONAL_ACCESS_TOKEN=valid_token" > "$TMP_DIR/.env"

    # Act
    local output
    output=$(bash "$health_check_script" 2>&1)
    local exit_code=$?

    # Assert
    assert_equals 0 "$exit_code" "Health check should pass in a good environment"
    assert_contain "$output" "Environment checks passed" "Should confirm that all checks passed"
}

test_health_check_fails_with_missing_env() {
    # Arrange
    local health_check_script="$TMP_DIR/scripts/health-check.sh"
    rm -f "$TMP_DIR/.env"

    # Act
    local output
    output=$(bash "$health_check_script" 2>&1)
    local exit_code=$?

    # Assert
    assert_equals 1 "$exit_code" "Health check should fail if .env is missing"
    assert_contain "$output" "No environment configuration found" "Should output a clear error message"
}

test_maintenance_script_runs_all_tasks() {
    # Arrange
    local maintenance_script="$TMP_DIR/scripts/maintenance.sh"
    echo "GITHUB_PERSONAL_ACCESS_TOKEN=valid_token" > "$TMP_DIR/.env"

    # Act
    local output
    output=$(bash "$maintenance_script" 2>&1)

    # Assert
    assert_contain "$output" "Updating Node.js packages" "Should attempt to update npm packages"
    assert_contain "$output" "Updating Docker images" "Should attempt to update Docker images"
    assert_contain "$output" "Cleaning up Docker resources" "Should attempt to clean up Docker"
    assert_contain "$output" "Backing up MCP configurations" "Should attempt to back up configs"
}

test_security_audit_checks_permissions() {
    # Arrange
    local audit_script="$TMP_DIR/scripts/security-audit.sh"
    echo "GITHUB_PERSONAL_ACCESS_TOKEN=valid_token" > "$TMP_DIR/.env"
    touch "$TMP_DIR/config/config.sh"
    chmod 777 "$TMP_DIR/config/config.sh"

    # Act
    local output
    output=$(bash "$audit_script" 2>&1)

    # Assert
    assert_contain "$output" "Configuration file has loose permissions" "Should detect and warn about loose permissions"
}

# --- Run Tests ---
run_test_suite "Utility Scripts Tests"
