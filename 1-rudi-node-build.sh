#!/bin/bash

source ".bashrc"
logmsg 'File .bashrc sourced'

REPO=https://-:${aqmo_git_rudi_container}@gitlab.aqmo.org/rudidev
WK_DIR=`pwd`
SRC_DIR=${WK_DIR}/src


for module in api media prodmanager console crypto; do
    logmsg "Cloning/pulling git repo: rudi-${module}"
    MOD_GIT=$( jq -r .${module} <"${WK_DIR}/git_sources.json")
    MOD_REPO=${REPO}/${MOD_GIT}
    MOD_DIR=${SRC_DIR}/rudi-${module}
    ccd ${SRC_DIR}
    if [ -d "${MOD_DIR}" ]; then 
        cd "${MOD_DIR}" && git pull
    else
        git clone "${MOD_REPO}" "${MOD_DIR}"
    fi
done

logmsg "Building the container"
cd "$WK_DIR"
podman build                                                \
    -f ./rudi-node.dockerfile                               \
    -t om/rudi-node:release .                               \
    2>&1 | tee `logfile rudi-node-build`

