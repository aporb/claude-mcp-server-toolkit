#!/bin/bash

# =============================================================================
# Simple Bash Assertion Library
# =============================================================================
#
# This library provides a set of simple, reusable functions for writing tests
# in Bash scripts. It helps in making assertions about exit codes, output
# content, and file properties.
#
# Usage:
#   source "assert.sh"
#   run_test_suite "My Test Suite"
#
# Functions:
#   - assert_equals <expected> <actual> <message>
#   - assert_not_equals <expected> <actual> <message>
#   - assert_contain <string> <substring> <message>
#   - assert_not_contain <string> <substring> <message>
#   - assert_is_executable <file_path> <message>
#   - run_test_suite <suite_name>
#
# =============================================================================

# --- State ---
_TEST_SUCCESS=0
_TEST_FAIL=0

# --- Assertions ---

assert_equals() {
    local expected=$1
    local actual=$2
    local message=$3

    if [ "$actual" == "$expected" ]; then
        echo "  ✅ PASS: $message"
        _TEST_SUCCESS=$((_TEST_SUCCESS + 1))
    else
        echo "  ❌ FAIL: $message"
        echo "     Expected: '$expected'"
        echo "     Actual:   '$actual'"
        _TEST_FAIL=$((_TEST_FAIL + 1))
    fi
}

assert_not_equals() {
    local expected=$1
    local actual=$2
    local message=$3

    if [ "$actual" != "$expected" ]; then
        echo "  ✅ PASS: $message"
        _TEST_SUCCESS=$((_TEST_SUCCESS + 1))
    else
        echo "  ❌ FAIL: $message"
        echo "     Expected not to be: '$expected'"
        echo "     Actual:             '$actual'"
        _TEST_FAIL=$((_TEST_FAIL + 1))
    fi
}

assert_contain() {
    local string=$1
    local substring=$2
    local message=$3

    if [[ "$string" == *"$substring"* ]]; then
        echo "  ✅ PASS: $message"
        _TEST_SUCCESS=$((_TEST_SUCCESS + 1))
    else
        echo "  ❌ FAIL: $message"
        echo "     Expected string to contain: '$substring'"
        _TEST_FAIL=$((_TEST_FAIL + 1))
    fi
}

assert_not_contain() {
    local string=$1
    local substring=$2
    local message=$3

    if [[ "$string" != *"$substring"* ]]; then
        echo "  ✅ PASS: $message"
        _TEST_SUCCESS=$((_TEST_SUCCESS + 1))
    else
        echo "  ❌ FAIL: $message"
        echo "     Expected string not to contain: '$substring'"
        _TEST_FAIL=$((_TEST_FAIL + 1))
    fi
}

assert_is_executable() {
    local file_path=$1
    local message=$2

    if [ -x "$file_path" ]; then
        echo "  ✅ PASS: $message"
        _TEST_SUCCESS=$((_TEST_SUCCESS + 1))
    else
        echo "  ❌ FAIL: $message"
        echo "     Expected file to be executable: '$file_path'"
        _TEST_FAIL=$((_TEST_FAIL + 1))
    fi
}

# --- Test Runner ---

run_test_suite() {
    local suite_name=$1
    echo "--- Running: $suite_name ---"

    # Find all functions in the current script that start with 'test_'
    local test_functions
    test_functions=$(compgen -A function | grep '^test_')

    for func in $test_functions; do
        $func
    done

    echo "---------------------------------"
    echo "Results for $suite_name: Passed: $_TEST_SUCCESS, Failed: $_TEST_FAIL"
    echo ""

    # Return a non-zero exit code if any test failed
    if [ "$_TEST_FAIL" -ne 0 ]; then
        return 1
    fi
    return 0
}
