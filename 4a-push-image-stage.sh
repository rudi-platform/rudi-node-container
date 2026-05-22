#!/bin/bash

# 4a-push-image-stage.sh

REGISTRY="registry.aqmo.org/public-rudi/public-packages" &&
    GIT_CREDS_FILE="./creds/git_creds"                   &&
    IMG_TAG=stage                                        &&
    source "./99-push-image.sh"
