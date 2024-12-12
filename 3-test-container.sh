#!/bin/bash

# ==================================================================================================
# This script runs the container image with podman
# ==================================================================================================


test -r ./install/.shrc && . ./install/.shrc
TIME_START=$(now_ms_int)

# Write your own configuration in 'container-conf.sh' file
test -r ./container-conf.sh && source ./container-conf.sh

VERSION="${VERSION:-'2.5.0'}"
IMG_NAME='localhost/rudinode-2.5.0:linux-arm64'

# Here you can specify any name you want
LOCAL_IMG_NAME=${LOCAL_IMG_NAME:-$IMG_NAME}

# Give the running container a name of your choice
CNTNR_NAME="${CNTNR_NAME:-LOCAL_IMG_NAME}"
# Stop the running instance in case it hadn't been stopped
podman stop "$CNTNR_NAME" 2>/dev/null
podman rm "$CNTNR_NAME" 2>/dev/null

# This is the install folder, you can optionally
INSTALL_DIR=${INSTALL_DIR:-"~/rudinode"}
mkdir -p "$INSTALL_DIR/data" && cd "$INSTALL_DIR"

podman run --rm -it --name "$CNTNR_NAME"  \
    --volume ./data:/data           \
    --publish 3030:3030             \
    --publish 3031:3031             \
    --publish 3032:3032             \
    -e CATALOG_PREFIX=catalog       \
    -e STORAGE_PREFIX=storage       \
    -e MANAGER_PREFIX=manager       \
    $LOCAL_IMG_NAME




exit 0

# Argument 1 is the destination platform for the container image. Defaults to "amd64"
if [ $# -lt 1 ]; then source ./env/platform.ini; else IMG_PLATFORM=$1; fi

# Argument 2 is the name of the container image that is produced. Defaults to "rudi-node"
if [ $# -lt 2 ]; then source ./tmp/img_prefix.ini; else IMG_PREFIX=$2; fi

IMG_PLATFORM=arm64
IMG_NAME="${IMG_PREFIX}-${IMG_PLATFORM}"

# log_in_file rudi-node-run
TIME_START=$(now_ms_int)
PRJ_DIR=$(pwd)

TAG=OCI-2.5.0-A
SU_CREDS=bm9kZSBhZG1pbjpUYlNDY1QzajN0eDZHZzdQdk10c0VGUDBEREw4TlFqRngxR0Z3MXVWbE5yTktudUFQTEp0Y1RBOFBkSklZS3dXRmpTU1lINHBHaVNVNXJsVHBBVGEyLTB0ZzItM1hBQWFrUmlUREtLTzNoR3cwMFVENmFzVXJZcFdQSW9IbXc=

WK_DIR=/app/rudi-node

echo "$PRJ_DIR"

log_msg Deleting the previous container to avoid accumulation
podman stop "${IMG_NAME}" 2>/dev/null
podman rm "${IMG_NAME}" 2>/dev/null

log_msg "Creating & running the new container"

# Create a new container and binding the following folders
#   - .ssh as /keys for the secrets (:Z opt = private, :ro = read-only)
#   - data as /data/dump to restore previous DB at startup
podman run -it                                                  \
    --rm                                                        \
    --name "$IMG_NAME"                                          \
    --log-level debug                                           \
    --publish 3030:3030                                         \
    --publish 3031:3031                                         \
    --publish 3033:3033                                         \
    --volume "${HOME}/data":/data:Z                       \
    -e CATALOG_PROFILES="$WK_DIR/ini/rudi-catalog-profiles.ini" \
    -e PORTAL_CONF="$WK_DIR/conf/rudi-catalog-portal.ini"       \
    -e SU=$SU_CREDS                                             \
    -e TAG=$TAG                                                 \
    -e ENV=staging                                              \
    "$IMG_NAME"

    # --network host
    # --expose 3030
    # --ip 10.88.0.88
    # --network bridge:ip=10.88.0.88,alias=rudinode
    # --network bridge:ip=10.88.0.88,alias=rudinode
    # --publish localhost:insidePort:outsidePort
    # --log-opt=/log/path
    # --ip 10.88.0.88
    # -v "${PRJ_DIR}/.ssh":.ssh:Z:Ro
    # -w /app/rudi-node

# Details on --publish option:
#   https://stackoverflow.com/a/69885042/1563072

# mongodump -d rudi_prod --archive=dump/rudi_catalog_dump.gz --gzip --excludeCollection logentries
# mongorestore -vvvvv --archive=./dump/rudi_catalog_dump.gz --gzip --numInsertionWorkersPerCollection=10

echo
# shellcheck disable=SC2046
echo Execution time: $( time_spent_s $TIME_START)s \($(basename "$0")\)

