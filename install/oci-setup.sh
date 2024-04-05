#!/usr/bin/env bash

# ==================================================================================================
# This script installs all the module (except prodmanager/front that was built earlier)
# ==================================================================================================


source .bashrc
TIME_START=$(now_ms_int)

export WK_DIR=$(pwd)
log_msg WK_DIR: "$WK_DIR"
chmod 100 "${WK_DIR}/env"

l

log_msg "Upgrading NPM"
export PATH="$(npm get prefix):${PATH}"
npm config set loglevel error && npm i -g npm@latest

for module in api media prodmanager console crypto; do
    log_msg "Installing NodeJS app: rudi-${module}"
    export NODE_ENV=production
    cd "${WK_DIR}/rudi-${module}" && npm i
done
log_msg "Internal setup over"
echo
echo global packages installed here: $(npm root -g)
echo

# echo ---
# npm config list



echo
echo "Execution time: $(time_spent_s "${TIME_START}")s ($(basename "$0"))"
