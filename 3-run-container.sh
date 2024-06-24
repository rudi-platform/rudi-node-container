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

# Create a new container and binding the following folders
#   - .ssh as /keys for the secrets (:Z opt = private, :ro = read-only)
#   - data as /data/dump to restore previous DB at startup
podman run -it                          \
    -v "${HOME}/data/dump":/data/dump:z \
    --expose 3000-3033                  \
    --publish 127.0.0.1:3030:3030       \
    --ip 10.88.0.88                     \
    --name rudinode                     \
    "localhost/rudi-node:release"
    # -v "${PRJ_DIR}/.ssh":.ssh:Z:ro \
    # -w /app/rudi-node \


# mongodump -d rudi_prod --archive=dump/rudi_api_dump.gz --gzip --excludeCollection logentries
# mongorestore -vvvvv --archive=./dump/rudi_api_dump.gz --gzip --numInsertionWorkersPerCollection=10

echo "Execution time: $( time_spent_s "${TIME_START}")s \($(basename "$0")\) )"
