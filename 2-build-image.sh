#!/bin/sh

# ==================================================================================================
# This script builds the container image with podman
# ==================================================================================================

test -r ./install/.shrc && . ./install/.shrc

TIME_START=$(now_ms_int)
IMG_NAME=${IMG_NAME:-"rudinode"}
# Define target platforms
platforms=("linux/amd64" "linux/arm64")

# Build and tag for each platform
for platform in "${platforms[@]}"; do
    export TARGETPLATFORM=$platform
    # export TARGETPLATFORM_SANITIZED=$(echo "$TARGETPLATFORM" | tr '/' '-')
    podman-compose -f ${DOCKER_COMPOSE_CONF:-"docker-compose-multip.yml"} build
#   podman-compose push  # Optional: Push to a registry if needed
done


log_msg "Container built"

echo "Execution time: $(time_spent_ms ${TIME_START})ms ($(basename "$0"))"
