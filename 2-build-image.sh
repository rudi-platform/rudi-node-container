#!/bin/bash

# ==================================================================================================
# This script builds the container image with podman
# ==================================================================================================

source "./install/.bashrc"
log_in_file rudi-node-img
TIME_START=$(now_ms_int)

DOCKER_USER=5999

# Argument 1 is the name for the docker image that is produced.
if [ $# -ne 1 ]; then
    DOCKER_IMG_NAME=rudinode:release
else
    DOCKER_IMG_NAME=$1
fi

mkdir -p ./tmp
echo DOCKER_IMG_NAME=$DOCKER_IMG_NAME > ./tmp/oci_name
log_msg "Building the OCI image '${DOCKER_IMG_NAME}'"

podman build                            \
    --build-arg username=$DOCKER_USER    \
    -t "${DOCKER_IMG_NAME}" .
    # 2>&1 | tee `logfile_path rudi-node-build`

log_msg "Container built"

echo "Execution time: $(time_spent_s "${TIME_START}")s ($(basename "$0"))"
