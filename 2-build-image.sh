#!/bin/bash

# ==================================================================================================
# This script builds the container image with podman
# ==================================================================================================

test -r ./install/.shrc && . ./install/.shrc

TIME_START=$(now_ms_int)
source './container-conf.sh'

# Build and tag for each platform
for PLATFORM in "${PLATFORMS[@]}"; do
    export PLATFORM_SANITIZED=$(echo "$PLATFORM" | tr '/' '-')
    export CONTAINER_NAME="${VERSIONED_NAME}-${PLATFORM_SANITIZED}"
    # export CONTAINER_NAME_TAG="${CONTAINER_NAME}:${PLATFORM_SANITIZED}"
    export IMG_NAME_TAG="${VERSIONED_NAME}:${PLATFORM_SANITIZED}"
    export TARGETPLATFORM="$PLATFORM"
    podman-compose -f ${DOCKER_COMPOSE_CONF:-"docker-compose-multip.yml"} build
#   podman-compose push  # Optional: Push to a registry if needed
done


log_msg "Image built"
echo
podman images
echo
echo "Execution time: $(time_spent_ms ${TIME_START})ms ($(basename "$0"))"
