#!/bin/bash

# ==================================================================================================
# This script runs the container image with podman
# ==================================================================================================

# A. Pulling the image
#    Two images are currenly available: either "linux/amd64" for Linux-based PC (should work on Windows too)
#    or "linux/arm64" for MacOS.

# This is aqmo gitlab container repo
REGISTRY_IMG=registry.aqmo.org/public-rudi/public-packages/rudinode:latest

# Here you can specify any name you want
LOCAL_IMG_NAME=${LOCAL_IMG_NAME:-"rudinode-local"}

# Fetch the image
podman pull "$REGISTRY_IMG"

# Give the image your prefered name
podman tag "$REGISTRY_IMG" "$LOCAL_IMG_NAME" && podman rmi "$REGISTRY_IMG"

# List the images
podman images

# B. Running the image
#    To run the container with a remanent volume, only `/data` folder should be mounted as a volume.

# Give the running container a name of your choice
CNTNR_NAME="${CNTNR_NAME:-rudinode}"
# Stop the running instance in case it hadn't been stopped
podman stop "$CNTNR_NAME" 2>/dev/null
podman rm "$CNTNR_NAME" 2>/dev/null

# This is the install folder, you can optionally
INSTALL_DIR=${INSTALL_DIR:-$HOME/rudinode}
mkdir -p "$INSTALL_DIR/data" && cd "$INSTALL_DIR"

# The following variable is the hashed super user credentials that corresponds to
#     usr: 'node admin'
#     pwd: 'manager admin password!'
# - If you don't set the SU variable the first time the container is run, credentials wil be
#   randomly generated and displayed in the logs.
# - You normally only need to set it once, but if you set it in the run command next time, the
#   previous super user credentials get overwritten.
SU=cnVkaW5vZGUgYWRtaW46WnU2WGwxWVNRUS0tT1BzenlhUFNzcmlQRjA5V1U2dHlVYlh3ZVdaX1lOTVRXMG82MWwxUFVoU3BOdWlhSVBCdGFlN2xXVmU2M0ExRV9zTk85QnlUcWhaZGx5RHY5UW5xdlkxX2lMaklXb3pJRXRlX29zQkM4WmlwUmxvTmR3

podman run --rm                             \
    --name "$CNTNR_NAME"                    \
    --volume "${INSTALL_DIR}/data":/data    \
    --publish 3030:3030                     \
    --publish 3031:3031                     \
    --publish 3032:3032                     \
    -e SU=$SU                               \
    $LOCAL_IMG_NAME
