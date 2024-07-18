#!/bin/bash

# ==================================================================================================
# This script runs the container image with podman
# ==================================================================================================

source "./install/.bashrc"
source "./env/env-init.sh"
log_in_file rudi-node-run
TIME_START=$(now_ms_int)
PRJ_DIR=$(pwd)

WK_DIR=/app/rudi-node
TAG=OCI-2.5.0-A
SU_CREDS=bm9kZSBhZG1pbjpUYlNDY1QzajN0eDZHZzdQdk10c0VGUDBEREw4TlFqRngxR0Z3MXVWbE5yTktudUFQTEp0Y1RBOFBkSklZS3dXRmpTU1lINHBHaVNVNXJsVHBBVGEyLTB0ZzItM1hBQWFrUmlUREtLTzNoR3cwMFVENmFzVXJZcFdQSW9IbXc=
echo "$PRJ_DIR"

log_msg Deleting the previous container to avoid accumulation
podman rm rudinode 2>/dev/null

log_msg "Creating & running the new container"
source ./tmp/oci_name

# Create a new container and binding the following folders
#   - .ssh as /keys for the secrets (:Z opt = private, :ro = read-only)
#   - data as /data/dump to restore previous DB at startup
podman run -it                                  \
    --rm                                        \
    --name rudinode                             \
    --log-level debug                           \
    --publish 3030:3030                         \
    --publish 3031:3031                         \
    --publish 3033:3033                         \
    --volume "${HOME}/data/db":/data/db:Z       \
    --volume "${HOME}/data/dump":/data/dump:Z   \
    --volume "${HOME}/data/media":/data/media:Z \
    --volume "${HOME}/data/conf":$WK_DIR/conf:Z \
    -e su=$SU_CREDS                             \
    -e tag=$TAG                                 \
    "${DOCKER_IMG_NAME}"


    # --network host
    # --expose 3030
    # --ip 10.88.0.88
    # --network bridge:ip=10.88.0.88,alias=rudinode
    # --network bridge:ip=10.88.0.88,alias=rudinode
    # --publish localhost:insidePort:outsidePort
    # --env-file ./env/env-init.sh
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