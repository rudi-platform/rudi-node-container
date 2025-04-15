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

VERSION="${VERSION:-"2.5.2"}"
IMG_NAME="${IMG_NAME:-"rudinode"}"

REGISTRY="${REGISTRY:-"registry.aqmo.org/public-rudi/public-packages"}"
PLATFORMS=${PLATFORMS:-("linux/amd64" "linux/arm64")}

IMG_VERSION="${IMG_NAME}-${VERSION}"
LATEST="${IMG_NAME}:latest"

# Remove the previous manifest if it exists
podman manifest rm "${LATEST}" 2>/dev/null || true
podman manifest rm "${IMG_VERSION}" 2>/dev/null || true

# Create the manifest
podman manifest create "${LATEST}"
podman manifest create "${IMG_VERSION}"

REPO="${REGISTRY}/${IMG_NAME}"

log_msg "Pushing images to the registry $REGISTRY"
for PLATFORM in "${PLATFORMS[@]}"; do

    PLATFORM_SANITIZED=$(echo "$PLATFORM" | tr '/' '-')
    IMG_VERSION_PLATFORM="${IMG_VERSION}:${PLATFORM_SANITIZED}"
    IMG_PLATFORM="${IMG_NAME}:${PLATFORM_SANITIZED}"

    # Push platform-specific images
    log_msg "Pushing the image ${IMG_VERSION_PLATFORM} to ${REGISTRY}"
    # Push to the versioned repo
    podman push "$IMG_VERSION_PLATFORM" "${REPO}-${VERSION}:${PLATFORM}" --creds="$GIT_CREDS"
    # Push to the latest repo
    podman push "$IMG_VERSION_PLATFORM" "${REPO}:${PLATFORM}" --creds="$GIT_CREDS"

    # Add platform-specific images to the manifest
    log_msg "Adding ${IMG_VERSION_PLATFORM} to manifests"
    podman manifest add "${IMG_VERSION}" "docker://${REGISTRY}/${IMG_VERSION_PLATFORM}"
    podman manifest add "${LATEST}" "docker://${REGISTRY}/${IMG_PLATFORM}"
done

# Push the manifest to the registry
log_msg "Pushing $LATEST to the registry 'docker://${REGISTRY}/${LATEST}'"

podman manifest push "$IMG_VERSION" "docker://${REGISTRY}/${IMG_VERSION}" --all --creds="$GIT_CREDS"
podman manifest push "$LATEST" "docker://${REGISTRY}/$LATEST" --all --creds="$GIT_CREDS"



log_msg "Images sent to aqmo registry"

echo "Execution time: $(time_spent_ms ${TIME_START})ms ($(basename "$0"))"
