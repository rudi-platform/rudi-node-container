#!/bin/bash

# ==================================================================================================
# This script pushes the built image to gitlab
# ==================================================================================================


test -r ./install/.shrc && . ./install/.shrc

TIME_START=$(now_ms_int)
USR_IMG_NAME=${USR_IMG_NAME:-"rudinode"}

auth_file=$HOME/.config/containers/auth.json
echo $aqmo_om_publish | podman login registry.aqmo.org -u=$om_aqmo_usr --password-stdin

# TODO (uneeded so far): put aqmo as registry in either of these locations:
# /etc/containers/registries.conf
# $HOME/.config/containers/registries.conf.

REGISTRY=registry.aqmo.org/public-rudi/public-packages
IMG_NAME=rudinode
PLATFORMS=("linux/amd64" "linux/arm64")


log_msg "Pushing images to gitlab"
for PLATFORM in "${PLATFORMS[@]}"; do
    PLATFORM_SANITIZED=$(echo "$PLATFORM" | tr '/' '-')
    IMG_NAME_TAG="${IMG_NAME}:${PLATFORM_SANITIZED}"
    podman push "$IMG_NAME_TAG" "${REGISTRY}/${IMG_NAME_TAG}" --creds=$om_aqmo_usr:$aqmo_om_publish
done


log_msg "Images sent to aqom registry"

echo "Execution time: $(time_spent_ms ${TIME_START})ms ($(basename "$0"))"
