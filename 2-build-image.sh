#!/bin/bash

# ==================================================================================================
# This script builds the container image with podman
# ==================================================================================================

source "./install/.bashrc"
logmsg 'File .bashrc sourced'

# Argument 1 is the name for the docker image that is produced.
if [ $# -ne 1 ]; then
    CONTAINER_IMG_NAME=rudi-node:release
else
    CONTAINER_IMG_NAME=$1
fi

logmsg "Building the OCI image '${CONTAINER_IMG_NAME}'"

podman build                             \
    -f Dockerfile                        \
    -t "${CONTAINER_IMG_NAME}" .         \
    2>&1 | tee `logfile rudi-node-build`

logmsg "Container built"
