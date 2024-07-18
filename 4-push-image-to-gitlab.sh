#!/bin/bash

# ==================================================================================================
# This script pushes the built image to gitlab
# ==================================================================================================


source "./install/.bashrc"
# source "./env/env-init.sh"
log_in_file rudi-node-push

source ./tmp/oci_name

@aqmo.org:registry = "https://gitlab.aqmo.org/api/v4/projects/59/packages/npm"

podman push "$DOCKER_IMG_NAME"