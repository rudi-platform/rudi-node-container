#!/bin/bash

# ==================================================================================================
# This script pushes the built image to gitlab
# ==================================================================================================


test -r ./install/.shrc && . ./install/.shrc
TIME_START=$(now_ms_int)

# Write your own configuration in 'container-conf.sh' file
test -r ./container-conf.sh && source ./container-conf.sh

# Write your credentials in 'git_creds' file with
#    GIT_CREDS="usr:token"
#    REGISTRY="ghcr.io/rudi-platform"
GIT_CREDS_FILE="${GIT_CREDS_FILE:-"./git_creds"}"

test -r "$GIT_CREDS_FILE" && echo "Creds file was found: '$GIT_CREDS_FILE'" && source "$GIT_CREDS_FILE"
GIT_CREDS="${GIT_CREDS:-"$GIT_USR:$GIT_TOKEN"}"

VERSION="${VERSION:-"1.0"}"
IMG_NAME="${IMG_NAME:-"rudinode"}"

REGISTRY="${REGISTRY:-"registry.aqmo.org/public-rudi/public-packages"}"
PLATFORMS=${PLATFORMS:-("linux/amd64" "linux/arm64")}

VERSIONED_NAME="${IMG_NAME}-${VERSION}"
LATEST="${IMG_NAME}:latest"

# Remove the previous manifest if it exists
podman manifest rm "${LATEST}" 2>/dev/null || true
podman manifest rm "${VERSIONED_NAME}" 2>/dev/null || true

# Create the manifest
podman manifest create "${LATEST}"
podman manifest create "${VERSIONED_NAME}"

log_msg "Pushing images to the registry $REGISTRY"
for PLATFORM in "${PLATFORMS[@]}"; do

    PLATFORM_SANITIZED=$(echo "$PLATFORM" | tr '/' '-')
    IMG_NAME_TAG="${VERSIONED_NAME}:${PLATFORM_SANITIZED}"

    # Push platform-specific images
    log_msg "Pushing the image ${IMG_NAME_TAG} to ${REGISTRY}"
    podman push "$IMG_NAME_TAG" "${REGISTRY}/${IMG_NAME_TAG}" --creds=$GIT_CREDS

    # Add platform-specific images to the manifest
    log_msg "Adding ${IMG_NAME_TAG} to manifests"
    podman manifest add "${LATEST}" "docker://${REGISTRY}/${IMG_NAME_TAG}"
    podman manifest add "${VERSIONED_NAME}" "docker://${REGISTRY}/${IMG_NAME_TAG}"
done

# Push the manifest to the registry
log_msg "Pushing $LATEST to the registry..."
podman manifest push "$LATEST" "docker://${REGISTRY}/$LATEST" --all --creds=$GIT_CREDS
podman manifest push "$VERSIONED_NAME" "docker://${REGISTRY}/$VERSIONED_NAME" --all --creds=$GIT_CREDS

log_msg "Images sent to aqmo registry"

echo "Execution time: $(time_spent_ms ${TIME_START})ms ($(basename "$0"))"
