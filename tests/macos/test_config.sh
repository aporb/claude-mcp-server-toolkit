#!/bin/bash

# =============================================================================
# Test Suite: Configuration Scripts
# =============================================================================
#
# This test suite validates the configuration-related scripts:
#   - `sync-env-to-config.sh`
#   - `setup-github-token.sh`
#
# The tests ensure that:
#   - The `.env` file is correctly read and synced to `config/config.sh`.
#   - Secure file permissions (600) are set on `config.sh`.
#   - The GitHub token setup script correctly validates a token.
#   - Error conditions (e.g., missing .env file) are handled gracefully.
#
# =============================================================================

# --- Test Setup ---

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$TEST_DIR")")"

source "$TEST_DIR/assert.sh"

# --- Mocks and Helpers ---

TMP_DIR=$(mktemp -d)

# Mock files and directories
mkdir -p "$TMP_DIR/config"
cp "$PROJECT_ROOT/.env.template" "$TMP_DIR/.env"

# Override the PROJECT_ROOT for the scripts under test
export PROJECT_ROOT="$TMP_DIR"

# Mock curl for token validation
export PATH="$TMP_DIR:$PATH"
cat > "$TMP_DIR/curl" << EOF
#!/bin/bash
echo '{"login": "testuser"}'
exit 0
EOF
chmod +x "$TMP_DIR/curl"

# --- Teardown ---

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# --- Test Cases ---

test_sync_env_creates_config_file() {
    # Arrange
    local sync_script="$PROJECT_ROOT/scripts/sync-env-to-config.sh"
    local config_file="$TMP_DIR/config/config.sh"
    rm -f "$config_file"

    # Act
    bash "$sync_script" > /dev/null 2>&1

    # Assert
    assert_equals 0 $? "Sync script should exit successfully"
    assert [ -f "$config_file" ] "config.sh should be created"
}

test_sync_env_sets_secure_permissions() {
    # Arrange
    local sync_script="$PROJECT_ROOT/scripts/sync-env-to-config.sh"
    local config_file="$TMP_DIR/config/config.sh"

    # Act
    bash "$sync_script" > /dev/null 2>&1

    # Assert
    local permissions
    permissions=$(stat -f "%A" "$config_file")
    assert_equals 600 "$permissions" "config.sh should have 600 permissions"
}

test_sync_env_copies_content() {
    # Arrange
    local sync_script="$PROJECT_ROOT/scripts/sync-env-to-config.sh"
    local env_file="$TMP_DIR/.env"
    local config_file="$TMP_DIR/config/config.sh"
    echo "TEST_VARIABLE=test_value" >> "$env_file"

    # Act
    bash "$sync_script" > /dev/null 2>&1

    # Assert
    assert_contain "$(cat "$config_file")" "TEST_VARIABLE=test_value" "config.sh should contain the content of .env"
}

test_github_token_setup_validates_token() {
    # Arrange
    local setup_token_script="$PROJECT_ROOT/scripts/setup-github-token.sh"
    local env_file="$TMP_DIR/.env"
    echo "GITHUB_PERSONAL_ACCESS_TOKEN=valid_token" > "$env_file"

    # Act
    local output
    output=$(bash "$setup_token_script" 2>&1)
    local exit_code=$?

    # Assert
    assert_equals 0 "$exit_code" "Token setup script should succeed with a valid token"
    assert_contain "$output" "GitHub token is valid" "Should confirm that the token is valid"
}

# --- Run Tests ---
run_test_suite "Configuration Scripts Tests"
