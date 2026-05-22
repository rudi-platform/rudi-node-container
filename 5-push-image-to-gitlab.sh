#!/bin/bash

REGISTRY="registry.aqmo.org/public-rudi/public-packages" &&
    GIT_CREDS_FILE="./creds/git_creds"                   &&
    IMG_TAG=latest                                       &&
    source "./99-push-image.sh"
