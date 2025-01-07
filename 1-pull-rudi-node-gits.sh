#!/bin/sh
# shellcheck disable=SC2034

# ==================================================================================================
# This script clone (or pull) the git repository for every RUDI module then builds RUDI Prodmanager
# frontend
# ==================================================================================================

test -r ./install/.shrc && . ./install/.shrc

# log_in_file rudi-node-git
TIME_START=$(now_ms_int)

# Loading the local conf file
LOCAL_CONF=${LOCAL_CONF:-".git-conf-aqmo.sh"}
test -r "./$LOCAL_CONF" && . "./$LOCAL_CONF"


# The gitlab repo generic URL. If set in
REPO="${REPO:-"https://github.com/rudi-platform"}"

# Correspondance between each RUDI module and its original gitlab repo
git_src_catalog="${git_src_catalog:-"rudi-node-catalog.git"}"
git_src_storage="${git_src_storage:-"rudi-node-storage.git"}"
git_src_manager="${git_src_manager:-"rudi-node-manager.git"}"
git_src_jwtauth="${git_src_jwtauth:-"rudi-node-jwtauth.git"}"

# Creating necessary folders
PRJ_DIR="$(pwd)"
PRJ_SRC_DIR="${PRJ_DIR}/src"
PRJ_ENV_DIR="${PRJ_DIR}/env"
mkdir -p "$PRJ_ENV_DIR" "$PRJ_SRC_DIR"

# The file `$GIT_REV_FILE`` is used to gather each repository's git tag
GIT_REV_FILE="${PRJ_ENV_DIR}/git-rev.ini"
if [ -f "$GIT_REV_FILE" ]; then rm "$GIT_REV_FILE"; fi


for module in catalog storage manager jwtauth; do
    cd "${PRJ_SRC_DIR}" || exit
    module_dir="${PRJ_SRC_DIR}/rudi-${module}"

    if [ -d "${module_dir}" ]; then
        log_msg Pulling git repo: rudi-${module}
        cd "${module_dir}" || exit
        git pull origin release
    else
        log_msg Cloning git repo: rudi-${module}
        # Recreating the git repo URI for this RUDI module
        mod_git=$(eval echo \$git_src_$module)
        mod_repo="${REPO}/${mod_git}"
        echo mod_repo=$mod_repo
        # Local destination folder for the RUDI module
        git clone -b release --single-branch "${mod_repo}" "${module_dir}"
    fi
    log_msg Collecting git tag for ${module}
    GIT_REV=$(echo "${module}_git_rev" | tr a-z A-Z)
    echo "${GIT_REV}=$(git rev-parse --short HEAD)" >>"$GIT_REV_FILE"
done

echo "Execution time: $(time_spent_ms ${TIME_START})ms ($(basename "$0"))"
