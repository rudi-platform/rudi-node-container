#!/bin/bash

# ==================================================================================================
# This script builds the container image with podman
# ==================================================================================================

test -r ./install/.shrc && . ./install/.shrc

TIME_START=$(now_ms_int)
IMG_NAME=${IMG_NAME:-"rudinode"}
# Define target platforms
PLATFORMS=("linux/amd64" "linux/arm64")

# Build and tag for each platform
for PLATFORM in "${PLATFORMS[@]}"; do
    export PLATFORM_SANITIZED=$(echo "$PLATFORM" | tr '/' '-')
    export CONTAINER_NAME="${IMG_NAME}-${PLATFORM_SANITIZED}"
    # export CONTAINER_NAME_TAG="${CONTAINER_NAME}:${PLATFORM_SANITIZED}"
    export IMG_NAME_TAG="${IMG_NAME}:${PLATFORM_SANITIZED}"
    export TARGETPLATFORM="$PLATFORM"
    podman-compose -f ${DOCKER_COMPOSE_CONF:-"docker-compose-multip.yml"} build
#   podman-compose push  # Optional: Push to a registry if needed
done


log_msg "Image built"
echo
podman images
echo
echo "Execution time: $(time_spent_ms ${TIME_START})ms ($(basename "$0"))"
