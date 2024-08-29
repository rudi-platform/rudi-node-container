#!/bin/bash

# ==================================================================================================
# This script pushes the built image to gitlab
# ==================================================================================================


source "./install/.bashrc"

# Argument 1 is the destination platform for the container image. Defaults to "amd64"
if [ $# -lt 1 ]; then
    source ./env/platform.ini
else
    IMG_PLATFORM=$1
fi

# Argument 2 is the name of the container image that is produced. Defaults to "rudi-node"
if [ $# -lt 2 ]; then
    source ./tmp/img_prefix.ini
else
    IMG_PREFIX=$2
fi

IMG_NAME="${IMG_PREFIX}-${IMG_PLATFORM}"

auth_file=$HOME/.config/containers/auth.json
echo $om_oci_aqmo_token | podman login registry.aqmo.org -u=$om_aqmo_usr --password-stdin

# TODO (uneeded so far): put aqmo as registry in either of these locations:
# /etc/containers/registries.conf
# $HOME/.config/containers/registries.conf.
log_msg "Pushing image $IMG_NAME to gitlab"
podman push "$IMG_NAME" "registry.aqmo.org/public-rudi/public-packages/$IMG_NAME" --creds=$om_aqmo_usr:$om_oci_aqmo_token
