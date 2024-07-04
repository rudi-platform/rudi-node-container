#!/bin/bash

# ==================================================================================================
# This script runs the container image with podman
# ==================================================================================================

source "./install/.bashrc"
log_in_file rudi-node-run
TIME_START=$(now_ms_int)
PRJ_DIR=$(pwd)
echo "$PRJ_DIR"

log_msg Deleting the previous container to avoid accumulation
podman rm rudinode 2>/dev/null

log_msg "Creating & running the new container"
source ./env/_oci_name.sh
# Create a new container and binding the following folders
#   - .ssh as /keys for the secrets (:Z opt = private, :ro = read-only)
#   - data as /data/dump to restore previous DB at startup
podman run -it                                      \
    --log-level debug                               \
    --rm                                            \
    --name rudinode                                 \
    --publish 3030:3030                             \
    --publish 3040:3040                             \
    --publish 3050:3050                             \
    --publish 3060:3060                             \
    --volume "${HOME}/data/dump":/data/dump:z       \
    "${CONTAINER_IMG_NAME}"


    # --network host
    # --expose 3030
    # --ip 10.88.0.88
    # --network bridge:ip=10.88.0.88,alias=rudinode
    # --network bridge:ip=10.88.0.88,alias=rudinode
    # --publish 127.0.0.1:insidePort:outsidePort
    # --env-file ./env/_env-init.sh
    # --log-opt=/log/path
    # --ip 10.88.0.88
    # -v "${PRJ_DIR}/.ssh":.ssh:Z:ro
    # -w /app/rudi-node

# Details on --publish option:
#   https://stackoverflow.com/a/69885042/1563072

# mongodump -d rudi_prod --archive=dump/rudi_catalog_dump.gz --gzip --excludeCollection logentries
# mongorestore -vvvvv --archive=./dump/rudi_catalog_dump.gz --gzip --numInsertionWorkersPerCollection=10

echo "Execution time: $( time_spent_s "${TIME_START}")s \($(basename "$0")\) )"
