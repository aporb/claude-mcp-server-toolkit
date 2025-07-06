#!/bin/bash

# =============================================================================
# Main Test Runner for macOS
# =============================================================================
#
# This script executes all test suites for the macOS environment.
# It runs tests in a logical order, starting with unit tests,
# then integration tests, and finally end-to-end workflow tests.
#
# Usage:
#   bash tests/run_tests.sh
#
# The script will exit with a non-zero status code if any test fails.
# =============================================================================

# Set the project root
PROJECT_ROOT="$(dirname "$PWD")"
export PROJECT_ROOT

# Ensure we are in the tests directory
cd "$(dirname "${BASH_SOURCE[0]}")" || exit

# Test Suites
# An array of test scripts to be executed in order.
TEST_SUITES=(
    "macos/test_setup.sh"
    "macos/test_config.sh"
    "macos/test_connectors.sh"
    "macos/test_server_management.sh"
    "macos/test_utilities.sh"
    "macos/test_e2e_workflow.sh"
    "macos/test_documentation.sh"
)

# --- Test Execution ---
SUCCESS_COUNT=0
FAIL_COUNT=0
TOTAL_COUNT=0

# Function to run a single test suite
run_suite() {
    local suite_path=$1
    echo "======================================================================"
    echo "▶️  Running Test Suite: ${suite_path}"
    echo "======================================================================"

    if [ ! -f "$suite_path" ]; then
        echo "❌ Error: Test suite not found at '${suite_path}'"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return
    fi

    # Make sure the test suite is executable
    chmod +x "$suite_path"

    # Execute the test suite
    if bash "$suite_path"; then
        echo "✅ Suite Passed: ${suite_path}"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "❌ Suite Failed: ${suite_path}"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    echo ""
}

# Run all test suites
for suite in "${TEST_SUITES[@]}"; do
    run_suite "$suite"
done

# --- Summary ---
echo "======================================================================"
echo "📊 Test Summary"
echo "======================================================================"
echo "Total Suites: ${TOTAL_COUNT}"
echo "✅ Passed:     ${SUCCESS_COUNT}"
echo "❌ Failed:     ${FAIL_COUNT}"
echo "======================================================================"

# Exit with a status code indicating success or failure
if [ "$FAIL_COUNT" -ne 0 ]; then
    echo "🔥 Some tests failed. Please review the output above."
    exit 1
else
    echo "🎉 All tests passed successfully!"
    exit 0
fi
