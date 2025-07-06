#!/bin/bash

# =============================================================================
# Mock for the 'docker' command-line interface
# =============================================================================
#
# This script simulates the behavior of the `docker` command for testing
# purposes. It allows us to test Docker-related scripts without needing a
# running Docker daemon. It can be configured to simulate different scenarios
# by setting environment variables.
#
# Supported Commands:
#   - docker info
#   - docker ps
#   - docker image inspect <image_name>
#   - docker build
#   - docker run
#   - docker rm
#
# Environment Variables for Configuration:
#   - DOCKER_MOCK_INFO_EXIT_CODE: Controls the exit code of `docker info`.
#   - DOCKER_MOCK_PS_OUTPUT: Sets the output for `docker ps`.
#   - DOCKER_MOCK_IMAGE_INSPECT_EXIT_CODE: Sets the exit code for `docker image inspect`.
#   - DOCKER_MOCK_BUILD_EXIT_CODE: Sets the exit code for `docker build`.
#   - DOCKER_MOCK_RUN_EXIT_CODE: Sets the exit code for `docker run`.
# =============================================================================

# Default exit codes
INFO_EXIT_CODE=${DOCKER_MOCK_INFO_EXIT_CODE:-0}
IMAGE_INSPECT_EXIT_CODE=${DOCKER_MOCK_IMAGE_INSPECT_EXIT_CODE:-0}
BUILD_EXIT_CODE=${DOCKER_MOCK_BUILD_EXIT_CODE:-0}
RUN_EXIT_CODE=${DOCKER_MOCK_RUN_EXIT_CODE:-0}

# Main command logic
case "$1" in
    "info")
        exit "$INFO_EXIT_CODE"
        ;;
    "ps")
        if [ -n "$DOCKER_MOCK_PS_OUTPUT" ]; then
            echo -e "$DOCKER_MOCK_PS_OUTPUT"
        else
            # Default behavior: return a sample container
            echo "CONTAINER ID   IMAGE                                 COMMAND                  STATUS"
            echo "0688b8e5847b   ghcr.io/github/github-mcp-server   \"/server/github-mcp...\"   Up 2 hours"
        fi
        exit 0
        ;;
    "image")
        if [ "$2" == "inspect" ]; then
            exit "$IMAGE_INSPECT_EXIT_CODE"
        elif [ "$2" == "prune" ]; then
            echo "Mocked: docker image prune $@" >&2
            exit 0
        fi
        ;;
    "build")
        echo "Mocked: docker build $@" >&2
        exit "$BUILD_EXIT_CODE"
        ;;
    "run")
        echo "Mocked: docker run $@" >&2
        exit "$RUN_EXIT_CODE"
        ;;
    "rm")
        echo "Mocked: docker rm $@" >&2
        exit 0
        ;;
    "container")
        if [ "$2" == "prune" ]; then
            echo "Mocked: docker container prune $@" >&2
            exit 0
        fi
        ;;
    "exec")
        echo "Mocked: docker exec $@" >&2
        # Simulate a successful connection for the connector test
        if [[ "$*" == *"stdio"* ]]; then
            echo "GitHub MCP Server running on stdio"
            echo '{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2024-11-05"}}'
        fi
        exit 0
        ;;
    *)
        echo "Mock Error: Unknown docker command '$1'" >&2
        exit 1
        ;;
esac
