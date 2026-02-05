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
GIT_CREDS_FILE="${GIT_CREDS_FILE:-"./creds/git_creds"}"

test -r "$GIT_CREDS_FILE" && echo "Creds file was found: '$GIT_CREDS_FILE'" && source "$GIT_CREDS_FILE"
GIT_CREDS="${GIT_CREDS:-"$GIT_USR:$GIT_TOKEN"}"

IMG_NAME="${IMG_NAME:-"rudinode"}"
VERSION="${VERSION:-"2.7.0b"}"
REGISTRY="${REGISTRY:-registry.aqmo.org/public-rudi/public-packages}"
PLATFORMS=${PLATFORMS:-(linux/amd64 linux/arm64)}

IMG_TAGGED="${IMG_NAME}:${IMG_TAG:-latest}"
IMG_VERSION="${IMG_NAME}:${VERSION}"

REPO_IMG_VERSION="docker://${REGISTRY}/${IMG_VERSION}"
REPO_IMG_TAGGED="docker://${REGISTRY}/${IMG_TAGGED}"

echo HLD_IMG=$HLD_IMG
echo HLD_MNFST=$HLD_MNFST

echo "This script will $([ -n "$HLD_IMG" ] && echo 'not ')push the podman images ${PLATFORMS[@]}"
echo "This script will $([ -n "$HLD_MNFST" ] && echo 'not ')push the podman manifests for ${IMG_TAGGED} and ${VERSION}"

if [ ! -n "$HLD_MNFST" ]; then
    log_msg "Removing the previous manifests if they exist"
    podman manifest rm "${IMG_TAGGED}" 2>/dev/null || true
    podman manifest rm "${IMG_VERSION}" 2>/dev/null || true

    log_msg "Create the manifest"
    podman manifest create "${IMG_TAGGED}"
    podman manifest create "${IMG_VERSION}"
fi

[ ! -n "$HLD_IMG" ] && log_msg "Pushing images to the registry $REGISTRY"
for PLATFORM in "${PLATFORMS[@]}"; do

    PLATFORM_SANITIZED=$(echo "$PLATFORM" | tr '/' '-')
    IMG_VERSION_PLATFORM="${IMG_NAME}:${VERSION}-${PLATFORM_SANITIZED}"
    LOCAL_IMG_VERSION_PLATFORM="localhost/${IMG_VERSION_PLATFORM}"
    REMOTE_IMG_VERSION_PLATFORM="docker://${REGISTRY}/${IMG_VERSION_PLATFORM}"

    # Push platform-specific images
    if [ ! -n "$HLD_IMG" ]; then
        log_msg "Pushing the image ${IMG_VERSION_PLATFORM} to ${REMOTE_IMG_VERSION_PLATFORM}"
        podman --log-level=debug push "${IMG_VERSION_PLATFORM}" "${REMOTE_IMG_VERSION_PLATFORM}" --creds=$GIT_CREDS
    fi
    if [ ! -n "$HLD_MNFST" ]; then
        log_msg "Adding ${REMOTE_IMG_VERSION_PLATFORM} to ${IMG_TAGGED} manifest"
        podman manifest add "${IMG_TAGGED}" "${REMOTE_IMG_VERSION_PLATFORM}"
        log_msg "Adding ${REMOTE_IMG_VERSION_PLATFORM} to ${IMG_VERSION} manifest"
        podman manifest add "${IMG_VERSION}" "${REMOTE_IMG_VERSION_PLATFORM}"
    fi
done

if [ ! -n "$HLD_MNFST" ]; then
    # Pushing the versioned manifest to the registry
    log_msg "Pushing $IMG_VERSION to the registry $REPO_IMG_VERSION"
    podman --log-level=debug manifest push "${IMG_VERSION}" "${REPO_IMG_VERSION}" --all --creds=$GIT_CREDS
    log_msg "Manifest for $IMG_VERSION"
    podman manifest inspect "${IMG_VERSION}" | jq '.manifests[].platform'

    # Pushing the latest manifest to the registry
    log_msg "Manifest for $IMG_TAGGED"
    podman manifest inspect "${IMG_TAGGED}" | jq '.manifests[].platform'

    log_msg "Pushing $IMG_TAGGED to the registry $REPO_IMG_TAGGED"
    podman --log-level=debug manifest push "${IMG_TAGGED}" "${REPO_IMG_TAGGED}" --all --creds=$GIT_CREDS

    log_msg "Manifests sent to aqmo registry"
fi
echo "Execution time: $(time_spent_ms ${TIME_START})ms ($(basename "$0"))"
