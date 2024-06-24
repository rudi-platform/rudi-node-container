#!/bin/bash

# ==================================================================================================
# This script clone (or pull) the git repository for every RUDI module then builds RUDI Prodmanager 
# frontend
# ==================================================================================================

source "./install/.bashrc"
log_in_file rudi-node-git
TIME_START=$(now_ms_int)

# shellcheck disable=SC2154
GIT_TOKEN="${aqmo_git_rudi_pod_token}"

REPO=https://-:${GIT_TOKEN}@gitlab.aqmo.org/rudidev
PRJ_DIR=$(pwd)
PRJ_SRC_DIR=${PRJ_DIR}/src

# This file is used to gather each repository's git tag
PRJ_ENV_DIR=${PRJ_DIR}/env
GIT_REV_FILE=${PRJ_ENV_DIR}/git-rev.ini
if [ -f "$GIT_REV_FILE" ]; then rm "$GIT_REV_FILE"; fi

for module in api media prodmanager console crypto; do
    # Recreating the git repo URI for this RUDI module
    mod_git=$( jq -r .${module} <"${PRJ_DIR}/git_sources.json")
    mod_repo=${REPO}/${mod_git}
    # Local destination folder for the RUDI module
    mod_dir=${PRJ_SRC_DIR}/rudi-${module}
    ccd "${PRJ_SRC_DIR}"

    if [ -d "${mod_dir}" ]; then 
        log_msg Pulling git repo: rudi-${module}
        cd "${mod_dir}" || exit 1
        git pull origin release
    else
        log_msg Cloning git repo: rudi-${module}
        git clone -b release --single-branch "${mod_repo}" "${mod_dir}"
    fi
    if [ $module == prodmanager ]; then
        log_msg Installing prodmanager frontend
        cd "${mod_dir}/front" || exit 1
        export PUBLIC_URL=/prodmanager
        npm i
        log_msg Building prodmanager frontend
        npm run build
    fi
    log_msg Collecting the git tag
    echo ${module}_git_rev="$(git rev-parse --short HEAD)" >> "$GIT_REV_FILE"
done

echo "Execution time: $(time_spent_s "${TIME_START}")s ($(basename "$0"))"
