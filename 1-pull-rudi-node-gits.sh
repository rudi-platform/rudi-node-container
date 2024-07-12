#!/bin/bash

# ==================================================================================================
# This script clone (or pull) the git repository for every RUDI module then builds RUDI Prodmanager
# frontend
# ==================================================================================================

source "./install/.bashrc"
log_in_file rudi-node-git
TIME_START=$(now_ms_int)


REPO=https://-:${rudi_node_git_token}@gitlab.aqmo.org/rudidev
PRJ_DIR=$(pwd)
PRJ_SRC_DIR=${PRJ_DIR}/src

# This file is used to gather each repository's git tag
PRJ_ENV_DIR=${PRJ_DIR}/env
GIT_REV_FILE=${PRJ_ENV_DIR}/git-rev.ini
if [ -f "$GIT_REV_FILE" ]; then rm "$GIT_REV_FILE"; fi

for module in catalog storage manager crypto; do
    # Recreating the git repo URI for this RUDI module
    mod_git=$( jq -r .${module} <"${PRJ_DIR}/git_sources.json")
    mod_repo=${REPO}/${mod_git}
    # Local destination folder for the RUDI module
    module_dir=${PRJ_SRC_DIR}/rudi-${module}
    ccd "${PRJ_SRC_DIR}"

    if [ -d "${module_dir}" ]; then
        log_msg Pulling git repo: rudi-${module}
        cd "${module_dir}"
        git pull origin release
    else
        log_msg Cloning git repo: rudi-${module}
        git clone -b release --single-branch "${mod_repo}" "${module_dir}"
    fi
    if [ $module == manager ]; then
        log_msg Installing manager front-end
        cd "${module_dir}/front" || exit 2
        export NODE_ENV='development'
        npm i

        log_msg Building manager frontend
        export PUBLIC_URL='';
        export NODE_ENV='production'
        npm run build:prod
    fi
    log_msg Collecting the git tag
    echo "${module}_git_rev=$(git rev-parse --short HEAD)" >> "$GIT_REV_FILE"
done

echo "Execution time: $(time_spent_s "${TIME_START}")s ($(basename "$0"))"
