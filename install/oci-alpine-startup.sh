#!/bin/ash
# ==================================================================================================
# This script launches (in order):
# - MongoDB
# - RUDI Catalog (ex-API)
# - RUDI Storage (ex-Media)
# - RUDI Manager: backend
# - RUDI Manager: frontend
#
# It then performs some tests
# ==================================================================================================
set -o nounset

. /etc/profile.d/10-rudi.sh

ROOT_DIR=$(dirname $(readlink -f $0))
cd ${ROOT_DIR} || error "installation directly not found"
. ${ROOT_DIR}/git-rev.ini || error "Git revision file not found"

TIME_START=$(now_ms_int)
log_msg "Executing as user $(whoami)"

ENABLE_DB=${ENABLE_DB:-true}
ENABLE_CATALOG=${ENABLE_CATALOG:-true}
ENABLE_STORAGE=${ENABLE_STORAGE:-true}
ENABLE_JWTAUTH=${ENABLE_JWTAUTH:-false}
ENABLE_MANAGER=${ENABLE_MANAGER:-true}

# Load configurations
. ${ROOT_DIR}/env-rudi.sh
${ENABLE_DB}      && . ${ROOT_DIR}/env-db.sh
${ENABLE_CATALOG} && . ${ROOT_DIR}/env-catalog.sh
${ENABLE_STORAGE} && . ${ROOT_DIR}/env-storage.sh
${ENABLE_JWTAUTH} && . ${ROOT_DIR}/env-jwtauth.sh
${ENABLE_MANAGER} && . ${ROOT_DIR}/env-manager.sh

# Chek installations
rudi_check
${ENABLE_DB}      && db_check
${ENABLE_CATALOG} && catalog_check
${ENABLE_STORAGE} && storage_check
${ENABLE_JWTAUTH} && jwtauth_check
${ENABLE_MANAGER} && manager_check

# Run services
PIDS=""
rudi_run
${ENABLE_DB}      && db_run
${ENABLE_CATALOG} && catalog_run & PIDS="${PIDS} $!"
${ENABLE_STORAGE} && storage_run & PIDS="${PIDS} $!"
${ENABLE_JWTAUTH} && jwtauth_run & PIDS="${PIDS} $!"
${ENABLE_MANAGER} && manager_run & PIDS="${PIDS} $!"

log_msg "Launching over"
echo "Execution time for launching: $(time_spent_s "${TIME_START}")s ${ROOT_DIR}"

allstop() {
    rudi_force_backup
    sleep 2
    kill ${PIDS} 2>/dev/null
}

trap 'rudi_force_backup' USR1 USR2
trap 'allstop' TERM INT

# Waiting for any process to exit
wait

#rm -rf /data/*
#su -l rudiadm /app/rudi-node/oci-alpine-startup.sh &
