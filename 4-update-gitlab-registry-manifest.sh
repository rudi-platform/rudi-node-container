#!/bin/bash

# Define variables
REGISTRY="registry.aqmo.org/public-rudi/public-packages"
IMG_NAME="rudinode"
LATEST="${IMG_NAME}:latest"


# Platform-specific image tags
PLATFORMS=("linux/amd64" "linux/arm64")

# Optional: remove the previous manifest
podman rmi "${LATEST}"


# Create the manifest
podman manifest create "${LATEST}"

# Add platform-specific images to the manifest
for PLATFORM in "${PLATFORMS[@]}"; do
    PLATFORM_SANITIZED=$(echo "$PLATFORM" | tr '/' '-')
    IMG_NAME_TAG="${IMG_NAME}:${PLATFORM_SANITIZED}"
    echo "Adding ${IMG_NAME_TAG} to ${LATEST}"
    podman manifest add "${LATEST}" "docker://${REGISTRY}/${IMG_NAME_TAG}"
done

# Push the manifest to the registry
echo "Pushing $LATEST to the registry..."
podman manifest push "$LATEST" "docker://${REGISTRY}/$LATEST" --all --creds=$om_aqmo_usr:$aqmo_om_publish


# podman manifest create rudinode:latest
# podman manifest add rudinode:latest registry.aqmo.org/public-rudi/public-packages/rudinode:linux-amd64
# podman manifest add rudinode:latest registry.aqmo.org/public-rudi/public-packages/rudinode:linux-arm64
# podman manifest push rudinode:latest docker://registry.aqmo.org/public-rudi/public-packages/rudinode:latest --all --creds=$om_aqmo_usr:$aqmo_om_publish
