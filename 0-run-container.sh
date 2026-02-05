#!/bin/bash

# ==================================================================================================
# This script runs the container image with podman
# ==================================================================================================

test -r ./install/.shrc && source ./install/.shrc
TIME_START=$(now_ms_int)

# A. Pulling the image
#    Two images are currenly available: either "linux/amd64" for Linux-based PC (should work on Windows too)
#    or "linux/arm64" for MacOS.

# This is aqmo gitlab container repo
REGISTRY_IMG=registry.aqmo.org/public-rudi/public-packages/rudinode:latest

# Here you can specify any name you want
LOCAL_IMG_NAME="${LOCAL_IMG_NAME:-"rudinode-local"}"

log_msg "Fetching the image"
podman pull "$REGISTRY_IMG"

# Give the image your prefered name
podman tag "$REGISTRY_IMG" "$LOCAL_IMG_NAME" && podman rmi "$REGISTRY_IMG"

log_msg "Listing the images"
podman images

# B. Running the image
#    To run the container with a remanent volume, only `/data` folder should be mounted as a volume.

# Give the running container a name of your choice
CNTNR_NAME="${CNTNR_NAME:-"rudinode"}"

log_msg "Stopping the running instance in case it hadn't been stopped"
podman stop "$CNTNR_NAME" 2>/dev/null
podman rm "$CNTNR_NAME" 2>/dev/null
# podman rm -f "$CNTNR_NAME" 2>/dev/null

# This is the install folder, you can optionally set a path for the files that will need to be stored
INSTALL_DIR="${INSTALL_DIR:-"$HOME/rudi-node"}"
mkdir -p "$INSTALL_DIR/data" && cd "$INSTALL_DIR"

# The following variable is the hashed super user credentials that corresponds to the following (without quotes)
#     usr: 'rudinode admin'
#     pwd: 'manager admin password!'
# - If you don't set the SU variable the first time the container is run, credentials wil be
#   randomly generated and displayed in the logs.
# - You normally only need to set it once, but if you set it in the run command next time, the
#   previous super user credentials get overwritten.
SU="cnVkaW5vZGUgYWRtaW46R3dvRDFiTmt5N1F1ZjNrbG1NZVk3NUhnVFdtUDZsZFpzU0ZJLWJDY1NMVWI2MldKOTZkMlJRVDZlMTFUd0E0eGNzTDljSHVNSnFaSkh4eW1SZE1iemRhMUM5WU8yU3Q2QVJoMmhlZFN1UmpZWW5PcXZpbDFEWDJ4cDJqZTZ3"

# In case you already have a MongoDB server running and you want to use it, you may give its URL and port to the container.
# Uncomment the following line if needed
# EXT_MONGODB_URL="mongodb://host.containers.internal:27017"

db_flag=""
[ -z ${EXT_MONGODB_URL+x} ] || db_flag="-e MONGODB=${EXT_MONGODB_URL}"

log_msg "Launching the RUDI node"

podman run --rm \
    --name "$CNTNR_NAME" \
    --volume "${INSTALL_DIR}/data":/data \
    --publish 27017:27017 \
    --publish 3030:3030 \
    --publish 3031:3031 \
    --publish 3032:3032 \
    -e SU=$SU \
    -e TAG=${VERSION:-dev} \
    -e VERSION=${VERSION} \
    -e NODE_PUBLIC_URL="http://localhost" \
    -e CATALOG_DB_NAME="rudi_catalog" \
    -e LOG_DIR="/data/log" \
    ${db_flag} \
    $LOCAL_IMG_NAME
