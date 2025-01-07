#!/bin/bash

# ==================================================================================================
# This script builds the container image with podman
# ==================================================================================================

test -r ./install/.shrc && source ./install/.shrc

TIME_START=$(now_ms_int)
test -r ./container-conf.sh && source ./container-conf.sh

VERSION="${VERSION:-"2.5.0"}"
IMG_NAME="${IMG_NAME:-"rudinode"}"

REGISTRY="${REGISTRY:-"registry.aqmo.org/public-rudi/public-packages"}"
PLATFORMS=${PLATFORMS:-("linux/amd64" "linux/arm64")}

VERSIONED_NAME="${IMG_NAME}-${VERSION}"
LATEST="${IMG_NAME}:latest"

# Build and tag for each platform
for PLATFORM in "${PLATFORMS[@]}"; do

    export PLATFORM_SANITIZED=$(echo "$PLATFORM" | tr '/' '-')
    export CONTAINER_NAME="${VERSIONED_NAME}-${PLATFORM_SANITIZED}"
    export IMG_NAME_TAG="${VERSIONED_NAME}:${PLATFORM_SANITIZED}"
    export TARGETPLATFORM="$PLATFORM"
    echo building the image \'$IMG_NAME_TAG\' for platform \'$TARGETPLATFORM\'
    podman-compose -f "${DOCKER_COMPOSE_CONF:-"docker-compose-multip.yml"}" build
#   podman-compose push  # Optional: Push to a registry if needed
done


log_msg "Image built"
echo
podman images
echo
echo "Execution time: $(time_spent_ms ${TIME_START})ms ($(basename "$0"))"
