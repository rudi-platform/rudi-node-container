#!/bin/bash

# ==================================================================================================
# This script pushes the built image to gitlab
# ==================================================================================================

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

podman pull "registry.aqmo.org/public-rudi/public-packages/$IMG_NAME"