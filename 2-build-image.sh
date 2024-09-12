#!/bin/sh

# ==================================================================================================
# This script builds the container image with podman
# ==================================================================================================

source ./install/.shrc

TIME_START=$(now_ms_int)

# DOCKER_USR=5999

# Argument 1 is the destination platform for the container image. Defaults to "amd64"
if [ $# -lt 1 ]; then
    IMG_PLATFORM=arm64
else
    IMG_PLATFORM=$1
fi
echo IMG_PLATFORM=$IMG_PLATFORM > ./env/platform.ini

# Argument 2 is the name of the container image that is produced. Defaults to "rudi-node"
if [ $# -lt 2 ]; then
    IMG_PREFIX=rudi-node
else
    IMG_PREFIX=$2
fi
mkdir -p ./tmp

IMG_NAME="${IMG_PREFIX}-${IMG_PLATFORM}"

log_msg "Building the OCI image '${IMG_NAME}'"
echo IMG_PREFIX=$IMG_PREFIX > ./tmp/img_prefix.ini

podman build                        \
    --platform linux/$IMG_PLATFORM  \
    -t "${IMG_NAME}" .
    # --build-arg username=$DOCKER_USR    \
    # 2>&1 | tee `logfile_path rudi-node-build`

log_msg "Container built"

echo "Execution time: $(time_spent_s "${TIME_START}")s ($(basename "$0"))"
