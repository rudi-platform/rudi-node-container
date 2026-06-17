#!/bin/bash
# shellcheck disable=SC2034

# ==================================================================================================
# This script clone (or pull) the git repository for every RUDI module then builds RUDI Prodmanager
# frontend
# ==================================================================================================
set -euo pipefail

test -r ./install/.bashrc && . ./install/.bashrc
enable_script_logging

# log_in_file rudi-node-git
TIME_START=$(now_ms_int)

# Loading the local conf file
LOCAL_CONF=${LOCAL_CONF:-".git-conf-aqmo.sh"}
test -r "./$LOCAL_CONF" && . "./$LOCAL_CONF"

# The gitlab repo generic URL. If set in
REPO="${REPO:-"https://github.com/rudi-platform"}"

echo "Pulling from $REPO"

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

package_json_changed=false

for module in catalog storage manager jwtauth; do
    cd "${PRJ_SRC_DIR}" || exit
    module_dir="${PRJ_SRC_DIR}/rudi-${module}"

    if [ -d "${module_dir}" ]; then
        log_msg Pulling git repo: rudi-${module}
        cd "${module_dir}" || exit
        old_head=$(git rev-parse HEAD)
        git fetch origin
        git checkout release
        git reset --hard origin/release
        new_head=$(git rev-parse HEAD)
        if [ "$old_head" != "$new_head" ]; then
            changed=$(git diff --name-only "$old_head" "$new_head" 2>/dev/null || true)
            if echo "$changed" | grep -q '^package.json$'; then
                package_json_changed=true
            fi
        fi
    else
        log_msg Cloning git repo: rudi-${module}
        mod_git=$(eval echo \$git_src_$module)
        mod_repo="${REPO}/${mod_git}"
        echo mod_repo=$mod_repo
        git clone -b release --single-branch "${mod_repo}" "${module_dir}"
        cd ${module_dir}
        package_json_changed=true
    fi
    log_msg Collecting git tag for ${module}
    GIT_REV=$(echo "${module}_git_rev" | tr a-z A-Z)
    echo "${GIT_REV}=\"$(git rev-parse --short HEAD)\"" >>"$GIT_REV_FILE"
done

if [ "$package_json_changed" = true ]; then
    log_msg "package.json changed — regenerating npmci/package-lock.json..."
    "${PRJ_DIR}"/10-update-lockfile.sh
fi

echo "Execution time: $(time_spent_ms ${TIME_START})ms ($(basename "$0"))"
echo "At: $(date '+%Y-%m-%d %H:%M:%S %Z')"
