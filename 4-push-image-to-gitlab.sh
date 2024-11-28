#!/bin/bash

# ==================================================================================================
# This script pushes the built image to gitlab
# ==================================================================================================


test -r ./install/.shrc && . ./install/.shrc
TIME_START=$(now_ms_int)
USR_IMG_NAME=${USR_IMG_NAME:-"rudinode"}

auth_file=$HOME/.config/containers/auth.json
echo $om_oci_aqmo_token | podman login registry.aqmo.org -u=$om_aqmo_usr --password-stdin

# TODO (uneeded so far): put aqmo as registry in either of these locations:
# /etc/containers/registries.conf
# $HOME/.config/containers/registries.conf.

log_msg "Pushing images to gitlab"
platforms=("linux/amd64" "linux/arm64")
for platform in "${platforms[@]}"; do
    SANITIZED_PLATFORM=$(echo "$platform" | tr '/' '-')
    IMG_NAME="rudinode:$SANITIZED_PLATFORM"
    DEST_NAME="registry.aqmo.org/public-rudi/public-packages/rudinode:$SANITIZED_PLATFORM"
    podman push "$IMG_NAME" "$DEST_NAME" --creds=$om_aqmo_usr:$om_oci_aqmo_token
done

log_msg "Images sent to aqom registry"

echo "Execution time: $(time_spent_ms ${TIME_START})ms ($(basename "$0"))"
