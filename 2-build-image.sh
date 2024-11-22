#!/bin/sh

# ==================================================================================================
# This script builds the container image with podman
# ==================================================================================================

. ./install/.shrc

TIME_START=$(now_ms_int)

# DOCKER_USR=5999
#!/bin/bash

# Define target platforms
platforms=("linux/amd64" "linux/arm64")

# Build and tag for each platform
for platform in "${platforms[@]}"; do
    export TARGETPLATFORM=$platform
    export TARGETPLATFORM_SANITIZED=$(echo "$TARGETPLATFORM" | tr '/' '-')
    podman-compose -f "docker-compose-basic.yml" build
#   podman-compose push  # Optional: Push to a registry if needed
done


log_msg "Container built"

echo "Execution time: $(time_spent_s "${TIME_START}")s ($(basename "$0"))"
