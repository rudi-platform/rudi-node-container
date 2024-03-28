#!/bin/bash

# ==================================================================================================
# This script runs the container image with podman
# ==================================================================================================

podman rm rudinode 2>/dev/null; 
podman run -i --name rudinode localhost/rudi-node:release