#!/bin/bash

# ==================================================================================================
# This script builds the container image with podman
# ==================================================================================================

source "./install/.bashrc"
log_in_file rudi-node-img
TIME_START=$(now_ms_int)


# Argument 1 is the name for the docker image that is produced.
if [ $# -ne 1 ]; then
    CONTAINER_IMG_NAME=rudi-node:release
else
    CONTAINER_IMG_NAME=$1
fi

log_msg "Building the OCI image '${CONTAINER_IMG_NAME}'"

podman build \
    -f ./Dockerfile \
    -t "${CONTAINER_IMG_NAME}" .         
    # 2>&1 | tee `logfile_path rudi-node-build`

log_msg "Container built"

echo "Execution time: $(time_spent_s "${TIME_START}")s ($(basename "$0"))"
