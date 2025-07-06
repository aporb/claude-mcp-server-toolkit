#!/bin/bash

# =============================================================================
# Test Suite: Documentation Commands
# =============================================================================
#
# This test suite validates the shell commands present in the documentation
# files (`README.md`, `TROUBLESHOOTING.md`). It helps ensure that the
# documentation does not become outdated.
#
# The script works by:
#   1. Parsing all `.md` files in the project root.
#   2. Extracting all shell command blocks.
#   3. Executing each command to ensure it runs without errors.
#
# Note: This is a powerful but potentially fragile test. It makes certain
# assumptions about the environment and the commands in the documentation.
# Some commands that are not meant to be tested (e.g., those that require
# user input) are skipped.
#
# =============================================================================

# --- Test Setup ---

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$TEST_DIR")")"

source "$TEST_DIR/assert.sh"

# --- Test Logic ---

# Find all markdown files in the project root
MD_FILES=$(find "$PROJECT_ROOT" -maxdepth 1 -type f -name "*.md")

# Function to test a single command
test_command() {
    local cmd=$1
    local file=$2

    # Skip commands that are not meant to be tested automatically
    if [[ "$cmd" == *"nano .env"* || \
          "$cmd" == *"your_actual_token_here"* || \
          "$cmd" == *"read -r response"* ]]; then
        echo "  ⏭️  SKIP: Command requires user input or secrets: '$cmd' (from $file)"
        return
    fi

    echo "  ▶️  TEST: '$cmd' (from $file)"
    
    # Execute the command
    # We use a subshell to avoid affecting the main test script's environment
    (cd "$PROJECT_ROOT" && eval "$cmd")
    local exit_code=$?

    assert_equals 0 "$exit_code" "Command should execute successfully"
}

# Main test function
test_all_documentation_commands() {
    for file in $MD_FILES; do
        echo "--- Checking file: $(basename "$file") ---"
        # Extract shell commands from markdown code blocks
        local commands
        commands=$(grep -E '^`{3}(bash|shell)?' -A 1000 "$file" | grep -E -v '^`{3}' | sed -e 's/^\$ //' -e 's/^> //')

        # Save the current IFS and set a new one to handle newlines
        local OLD_IFS=$IFS
        IFS=$'\n'

        for cmd in $commands; do
            # Skip empty lines
            if [ -n "$cmd" ]; then
                test_command "$cmd" "$(basename "$file")"
            fi
        done

        # Restore the original IFS
        IFS=$OLD_IFS
    done
}

# --- Run Tests ---
run_test_suite "Documentation Commands Test"
