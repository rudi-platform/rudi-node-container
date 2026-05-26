# !/bin/bash

test -r ./node-version && source ./node-version

VERSION="${VERSION:-2.7.2a}"
IMG_NAME="rudinode"

PLATFORMS=("linux/amd64" "linux/arm64")

VERSIONED_NAME="${IMG_NAME}-${VERSION}"
LATEST="${IMG_NAME}:latest"
