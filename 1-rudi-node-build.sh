#!/bin/bash

source "./install/.bashrc"
logmsg 'File .bashrc sourced'

# Argument 1 is the name for the docker image that is produced.
CONTAINER_IMG_NAME="$1" || "rudi-node:release"

REPO=https://-:${aqmo_git_rudi_container}@gitlab.aqmo.org/rudidev
WK_DIR=`pwd`
SRC_DIR=${WK_DIR}/src

for module in api media prodmanager console crypto; do
    mod_git=$( jq -r .${module} <"${WK_DIR}/git_sources.json")
    mod_repo=${REPO}/${mod_git}
    mod_dir=${SRC_DIR}/rudi-${module}
    ccd ${SRC_DIR}
    if [ -d "${mod_dir}" ]; then 
        logmsg "Pulling git repo: rudi-${module}"
        cd "${mod_dir}" && git pull
    else
        logmsg "Cloning git repo: rudi-${module}"
        git clone "${mod_repo}" "${mod_dir}"
    fi
    if [ $module == prodmanager ]; then
        logmsg "Installing prodmanager front"
        cd front
        rm -fR front/build/*
        export PUBLIC_URL=/prodmanager
        npm i
        logmsg "Building prodmanager front"
        npm run build
        rm -fR node_modules
    fi
done

logmsg "Building the OCI image '${CONTAINER_IMG_NAME}'"

cd "$WK_DIR"
podman build                             \
    -f Dockerfile                        \
    -t "${CONTAINER_IMG_NAME}" .         \
    2>&1 | tee `logfile rudi-node-build`

logmsg "Container built"
