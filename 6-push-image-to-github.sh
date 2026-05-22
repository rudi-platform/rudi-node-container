#!/bin/bash

REGISTRY="ghcr.io/rudi-platform"         &&
    GIT_CREDS_FILE="./creds/git_creds_rudip" &&
    IMG_TAG=latest                       &&
    source "./99-push-image.sh"
