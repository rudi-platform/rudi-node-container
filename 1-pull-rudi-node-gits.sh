#!/bin/bash

# ==================================================================================================
# This script clone (or pull) the git repository for every RUDI module then builds RUDI Prodmanager 
# frontend
# ==================================================================================================

source "./install/.bashrc"
logmsg 'File .bashrc sourced'

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
        logmsg "Installing prodmanager frontend"
        cd front
        export PUBLIC_URL=/prodmanager
        npm i
        logmsg "Building prodmanager frontend"
        npm run build
    fi
done
