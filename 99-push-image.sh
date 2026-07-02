#!/bin/bash
# 99-push-image.sh

# ==================================================================================================
# This script pushes the built image to gitlab
# ==================================================================================================
set -euo pipefail

test -r ./install/.bashrc && source ./install/.bashrc
enable_script_logging
podman-context build

TIME_START=$(now_ms_int)
test -r ./node-version && source ./node-version

# Write your own configuration in 'container-conf.sh' file
test -r ./container-conf.sh && source ./container-conf.sh

# Write your credentials in 'git_creds' file with
#    GIT_CREDS="usr:token"
#    REGISTRY="ghcr.io/rudi-platform"
GIT_CREDS_FILE="${GIT_CREDS_FILE:-"./creds/git_creds"}"

test -r "$GIT_CREDS_FILE" && echo "Creds file was found: '$GIT_CREDS_FILE'" && source "$GIT_CREDS_FILE"
GIT_CREDS="${GIT_CREDS:-"${GIT_USR:-}:${GIT_TOKEN:-}"}"

IMG_NAME="${IMG_NAME:-"rudinode"}"
VERSION="${VERSION:-"2.7.5"}"
REGISTRY="${REGISTRY:-registry.aqmo.org/public-rudi/public-packages}"
read -r -a PLATFORMS <<<"${PLATFORMS:-linux/amd64 linux/arm64}"

IMG_TAGGED="${IMG_NAME}:${IMG_TAG:-latest}"
IMG_VERSION="${IMG_NAME}:${VERSION}"

REPO_IMG_VERSION="docker://${REGISTRY}/${IMG_VERSION}"
REPO_IMG_TAGGED="docker://${REGISTRY}/${IMG_TAGGED}"

HLD_IMG="${HLD_IMG:-false}"
if $HLD_IMG; then
    echo "This script will not push the podman images"
else
    echo "This script will push the podman images"
fi

HLD_MNFST="${HLD_MNFST:-false}"
if $HLD_MNFST; then
    echo "This script will not push the podman manifests for ${IMG_TAGGED} and ${VERSION}"
else
    echo "This script will push the podman manifests for ${IMG_TAGGED} and ${VERSION}"
fi

if ! $HLD_MNFST; then
    log_msg "Removing the previous manifests if they exist"
    podman manifest rm "${IMG_TAGGED}" 2>/dev/null || true
    podman manifest rm "${IMG_VERSION}" 2>/dev/null || true

    log_msg "Create the manifest"
    podman manifest create "${IMG_TAGGED}"
    podman manifest create "${IMG_VERSION}"
fi

if ! $HLD_IMG; then
    log_msg "Pushing images to the registry $REGISTRY"
fi

for PLATFORM in "${PLATFORMS[@]}"; do
    # PLATFORM_SANITIZED=$(echo "$PLATFORM" | tr '/' '-')
    PLATFORM_SANITIZED=${PLATFORM//\//-}
    IMG_VERSION_PLATFORM="${IMG_NAME}:${VERSION}-${PLATFORM_SANITIZED}"
    # LOCAL_IMG_VERSION_PLATFORM="localhost/${IMG_VERSION_PLATFORM}"
    REMOTE_IMG_VERSION_PLATFORM="docker://${REGISTRY}/${IMG_VERSION_PLATFORM}"

    # Push platform-specific images
    if ! $HLD_IMG; then
        log_msg "Pushing the image ${IMG_VERSION_PLATFORM} to ${REMOTE_IMG_VERSION_PLATFORM}"
        podman --log-level=debug push 			\
			"${IMG_VERSION_PLATFORM}" 			\
			"${REMOTE_IMG_VERSION_PLATFORM}"	\
			 --creds="$GIT_CREDS"
    fi
    if ! $HLD_MNFST; then
        log_msg "Adding ${REMOTE_IMG_VERSION_PLATFORM} to ${IMG_TAGGED} manifest"
        podman manifest add "${IMG_TAGGED}" "${REMOTE_IMG_VERSION_PLATFORM}"
        log_msg "Adding ${REMOTE_IMG_VERSION_PLATFORM} to ${IMG_VERSION} manifest"
        podman manifest add "${IMG_VERSION}" "${REMOTE_IMG_VERSION_PLATFORM}"
    fi
done

if ! $HLD_MNFST; then
    # Pushing the versioned manifest to the registry
    log_msg "Pushing $IMG_VERSION to the registry $REPO_IMG_VERSION"
		# --format=v2s2 						\
    podman --log-level=debug manifest push 	\
		--all 								\
		--creds="$GIT_CREDS"  				\
		"${IMG_VERSION}" 					\
		"${REPO_IMG_VERSION}"

    log_msg "Manifest for $IMG_VERSION"
    podman manifest inspect "${IMG_VERSION}" | jq '.manifests[].platform'

    # Pushing the latest manifest to the registry
    log_msg "Manifest for $IMG_TAGGED"
    podman manifest inspect "${IMG_TAGGED}" | jq '.manifests[].platform'

    log_msg "Pushing $IMG_TAGGED to the registry $REPO_IMG_TAGGED"
		# --format=v2s2 						\
    podman --log-level=debug manifest push 	\
		--all 								\
		--creds="$GIT_CREDS" 				\
		"${IMG_TAGGED}" 					\
		"${REPO_IMG_TAGGED}"

    log_msg "Manifests sent to aqmo registry"
fi
echo "Execution time: $(time_spent_ms ${TIME_START})ms ($(basename "$0"))"
echo "At: $(date '+%Y-%m-%d %H:%M:%S %Z')"
