#!/bin/bash

# ==================================================================================================
# This script runs the container image with podman
# ==================================================================================================


test -r ./install/.shrc && . ./install/.shrc
TIME_START=$(now_ms_int)

# Write your own configuration in 'container-conf.sh' file
test -r ./container-conf.sh && source ./container-conf.sh

VERSION="${VERSION:-"2.5.0"}"
IMG_NAME="localhost/rudinode-2.5.0:linux-arm64"
TAG="${TAG:-"OCI-2.5.0a"}"
SU=UE0gQWRtaW46RXgwOTktblZMYlMtNVNTZkxGWElsSk1fWENBWHdZb2Fya19UVjliM3U5YlhGMGZSZXU2QTJWRndXdllXZm9QT3NUSm5RUkxIbDRvUFA1R2dUTDllNGFRRnJyOVNGSE9QZ3JKS3dMOS0wNGJLRTBOS19WeWRXcGR5aDNlRV9n

# Here you can specify any name you want
LOCAL_IMG_NAME="${LOCAL_IMG_NAME:-$IMG_NAME}"

# Give the running container a name of your choice
CNTNR_NAME="${CNTNR_NAME:-$LOCAL_IMG_NAME}"
# Stop the running instance in case it hadn't been stopped
podman stop "$CNTNR_NAME" 2>/dev/null
podman rm "$CNTNR_NAME" 2>/dev/null

# This is the install folder, you can set your own
INSTALL_DIR="${INSTALL_DIR:-"$HOME/rudinode"}"
mkdir -p "$INSTALL_DIR/data" && cd "$INSTALL_DIR"

[ -z ${CATALOG_PREFIX+x} ] && CATALOG_PREFIX="electricite/catalog"
[ -z ${STORAGE_PREFIX+x} ] && STORAGE_PREFIX="electricite/storage"
[ -z ${MANAGER_PREFIX+x} ] && MANAGER_PREFIX="electricite/manager"

podman run --rm -it                     \
    --name "$CNTNR_NAME"                \
    --volume ./data:/data               \
    --publish 3030:3030                 \
    --publish 3031:3031                 \
    --publish 3032:3032                 \
    -e CATALOG_PREFIX=$CATALOG_PREFIX   \
    -e STORAGE_PREFIX=$STORAGE_PREFIX   \
    -e MANAGER_PREFIX=$MANAGER_PREFIX   \
    -e TAG=$TAG                         \
    -e SU=$SU                           \
    $LOCAL_IMG_NAME



