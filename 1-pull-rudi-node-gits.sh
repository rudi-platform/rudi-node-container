#!/bin/bash

# ==================================================================================================
# This script clone (or pull) the git repository for every RUDI module then builds RUDI Prodmanager 
# frontend
# ==================================================================================================

source "./install/.bashrc"
log_in_file rudi-node-git
TIME_START=$(now_ms_int)


REPO=https://-:${aqmo_git_rudi_container}@gitlab.aqmo.org/rudidev
WK_DIR=`pwd`
SRC_DIR=${WK_DIR}/src

if [ -f ${SRC_DIR}/git-rev.ini ]; then
    rm ${SRC_DIR}/git-rev.ini
fi

for module in api media prodmanager console crypto; do
    mod_git=$( jq -r .${module} <"${WK_DIR}/git_sources.json")
    mod_repo=${REPO}/${mod_git}
    mod_dir=${SRC_DIR}/rudi-${module}
    ccd ${SRC_DIR}
    if [ -d "${mod_dir}" ]; then 
        log_msg Pulling git repo: rudi-${module}
        cd "${mod_dir}" 
        # cur_branch=`git rev-parse --abbrev-ref HEAD`
        # if [ ${cur_branch} != release ]; then git checkout release; fi
        git pull
    else
        log_msg Cloning git repo: rudi-${module}
        git clone -b release --single-branch "${mod_repo}" "${mod_dir}"
    fi
    if [ $module == prodmanager ]; then
        log_msg Installing prodmanager frontend
        cd "${mod_dir}/front" 
        export PUBLIC_URL=/prodmanager
        npm i
        log_msg Building prodmanager frontend
        npm run build
    fi
    log_msg Collecting the git tag
    echo ${module}=$(git rev-parse --short HEAD) >> ${SRC_DIR}/git-rev.ini
done

echo "Execution time: $(time_spent_s ${TIME_START})s ($(basename "$0"))"
