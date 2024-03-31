#!/usr/bin/env bash

# ==================================================================================================
# This script installs all the module (except prodmanager/front that was built earlier)
# ==================================================================================================


source .bashrc
TIME_START=$(now_ms_int)

WK_DIR=`pwd`
log_msg WK_DIR: $WK_DIR

l

log_msg "Upgrading NPM"
npm config set loglevel error && npm i -g npm@latest

for module in api media prodmanager console crypto; do
    log_msg "Installing NodeJS app: rudi-${module}"
    export NODE_ENV=production
    cd "${WK_DIR}/rudi-${module}" && npm i -g
    # if [ -d "front" ]; then 
    #     log_msg "Installing front: rudi-${module} "
    #     cd front
    #     npm run install:dev
    #     npm run build:prod 
    # fi
done

log_msg "Internal setup over"

echo "Execution time: $(time_spent_s ${TIME_START})s ($(basename "$0"))"
