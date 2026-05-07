#!/bin/bash

# ==================================================================================================
# This script builds the container image with docker
# ==================================================================================================

test -r ./install/.shrc && source ./install/.shrc
TIME_START=$(now_ms_int)

test -r ./container-conf.sh && source ./container-conf.sh

IMG_NAME="${IMG_NAME:-"rudinode"}"
VERSION="${VERSION:-"2.7.1"}"
PLATFORMS=${PLATFORMS:-("linux/amd64" "linux/arm64")}

# Build and tag for each platform
for PLATFORM in "${PLATFORMS[@]}"; do
    PLATFORM_SANITIZED=$(echo "$PLATFORM" | tr '/' '-')
    TAG="${IMG_NAME}:${VERSION}-${PLATFORM_SANITIZED}"

    export PLATFORM_SANITIZED
    export CONTAINER_NAME="$TAG"
    export IMG_NAME_TAG="$TAG"
    export TARGETPLATFORM="$PLATFORM"

    log_msg "Building the image '$TAG' for platform '$TARGETPLATFORM'"
    docker-compose -f "${DOCKER_COMPOSE_CONF:-docker-compose-multip.yml}" build
done

log_msg "Images built"
echo
docker images
echo
echo "Execution time: $(time_spent_ms ${TIME_START})ms ($(basename "$0"))"
echo "At: $(date '+%Y-%m-%d %H:%M:%S %Z')"
