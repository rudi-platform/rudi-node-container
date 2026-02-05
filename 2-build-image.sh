#!/bin/bash

# ==================================================================================================
# This script builds the container image with podman
# ==================================================================================================

test -r ./install/.shrc && source ./install/.shrc
TIME_START=$(now_ms_int)

test -r ./container-conf.sh && source ./container-conf.sh

# log_msg Cleaning podman images
# podman image prune -f

IMG_NAME="${IMG_NAME:-"rudinode"}"
VERSION="${VERSION:-"2.7.0b"}"
PLATFORMS=${PLATFORMS:-("linux/amd64" "linux/arm64")}

# Enable BuildKit-style features like `RUN --mount=type=cache` (that uses npm cache)`
export DOCKER_BUILDKIT=1

# Build and tag for each platform
for PLATFORM in "${PLATFORMS[@]}"; do
    PLATFORM_SANITIZED=$(echo "$PLATFORM" | tr '/' '-')
    TAG="${IMG_NAME}:${VERSION}-${PLATFORM_SANITIZED}"

    export PLATFORM_SANITIZED
    export CONTAINER_NAME="$TAG"
    export IMG_NAME_TAG="$TAG"
    export TARGETPLATFORM="$PLATFORM"

    log_msg "Building the image '$TAG' for platform '$TARGETPLATFORM'"
    podman-compose -f "${DOCKER_COMPOSE_CONF:-docker-compose-multip.yml}" build
done

log_msg "Images built"
echo
podman images
echo
echo "Execution time: $(time_spent_ms ${TIME_START})ms ($(basename "$0"))"
