#
# Global configuration
set -o nounset

#
# Global RUDI Config
NODE_PUBLIC_URL=${NODE_PUBLIC_URL:-http://127.0.0.1}
PORTAL_URL=${PORTAL_URL:-none}
PORTAL_USER=${PORTAL_USER:-0}
PORTAL_PASS=${PORTAL_PASS:-0}

DB_PREFIX=${DB_PREFIX:-}
NODE_BASE_PORT=${NODE_BASE_PORT:-3030}
MONGODB_PORT=${MONGGODB_PORT:-27017}
MONGODB=${MONGODB:-mongodb://localhost:${MONGODB_PORT}}

#
# Domains
LOCAL_INTERFACE=0.0.0.0
LOCAL_URL=${LOCAL_URL:-http://localhost}
TRUSTED_DOMAINS=${TRUSTED_DOMAINS:-}
# Sets different flags such as debug level or cookie security. Set to production | staging | development
ENV=${ENV:-production}

#
# Port Allocation
NODE_CATALOG_PORT=${NODE_CATALOG_PORT:-$((${NODE_BASE_PORT}+0))}
NODE_STORAGE_PORT=${NODE_STORAGE_PORT:-$((${NODE_BASE_PORT}+1))}
NODE_MANAGER_PORT=${NODE_MANAGER_PORT:-$((${NODE_BASE_PORT}+2))}
NODE_CRYPTO_PORT=${NODE_CRYPTO_PORT:-$((${NODE_BASE_PORT}+3))}

CATALOG_LOCAL_URL=${CATALOG_LOCAL_URL:-${LOCAL_URL}:${NODE_CATALOG_PORT}}
STORAGE_LOCAL_URL=${STORAGE_LOCAL_URL:-${LOCAL_URL}:${NODE_STORAGE_PORT}}
MANAGER_LOCAL_URL=${MANAGER_LOCAL_URL:-${LOCAL_URL}:${NODE_MANAGER_PORT}}
CRYPTO_LOCAL_URL=${CRYPTO_LOCAL_URL:-${LOCAL_URL}:${NODE_CRYPTO_PORT}}

#
# Main Directories
APP_DIR=${APP_DIR:-/app/rudi-node}
INI_DIR=${INI_DIR:-/app/config/ini}
SAFE_DIR=${SAFE_DIR:-/app/config/safe}
MEDIA_DIR=${MEDIA_DIR:-/data/media}
LOG_DIR=${LOG_DIR:-/data/log}
DB_DIR=${DB_DIR:-/data/db}
PUBKEY_DIR=${PUBKEY_DIR:-/data/keys}

#
# Extra
DB_WAIT_MAX=${DB_WAIT_MAX:-60}
LOG_ROTATE_CONF=${LOG_ROTATE_CONF:-${INI_DIR}/log_rotate}
GLOBAL_VARS="APP_DIR INI_DIR SAFE_DIR LOG_DIR MONGODB DB_PREFIX PUBKEY_DIR"
GLOBAL_VARS="${GLOBAL_VARS} MEDIA_DIR PORTAL_URL PORTAL_USER PORTAL_PASS TRUSTED_DOMAINS"
GLOBAL_VARS="${GLOBAL_VARS} NODE_CATALOG_PORT NODE_STORAGE_PORT NODE_MANAGER_PORT NODE_CRYPTO_PORT"
GLOBAL_VARS="${GLOBAL_VARS} LOCAL_INTERFACE LOCAL_URL CATALOG_LOCAL_URL STORAGE_LOCAL_URL MANAGER_LOCAL_URL CRYPTO_LOCAL_URL"

assert_key() {
    local keyname=${1:-myprivate}
    local user=${2:-rudiadm}
    local group=${3:-rudi}
    local kfile=${SAFE_DIR}/${keyname}
    test -d ${SAFE_DIR} || mkdir -p ${SAFE_DIR}
    test -d ${SAFE_DIR} || error "Could not find ${SAFE_DIR}"
    test -e ${kfile}    || ssh-keygen -t ed25519 -C "$keyname" -q -N '' -f "${kfile}" || error "Could not generate key $keyname"
    chown $user:$group ${kfile}
    chmod 400 ${kfile}
    chmod 440 ${kfile}.pub
    cp -p ${kfile}.pub ${PUBKEY_DIR}/
}

rudi_check() {
    local user=${1:-rudiadm}
    local group=${2:-rudi}
    test -d ${APP_DIR}     || error "Could not find ${APP_DIR}"
    test -d ${INI_DIR}     || mkdir -p ${INI_DIR}
    test -d ${SAFE_DIR}    || mkdir -p ${SAFE_DIR}
    test -d ${LOG_DIR}     || mkdir -p ${LOG_DIR}
    test -d ${MEDIA_DIR}   || mkdir -p ${MEDIA_DIR}
    test -d ${DB_DIR}      || mkdir -p ${DB_DIR}
    test -d ${PUBKEY_DIR}  || mkdir -p ${PUBKEY_DIR}

    chown $user:$group ${INI_DIR} ${SAFE_DIR} ${LOG_DIR} ${DB_DIR}
    chmod 770          ${INI_DIR} ${SAFE_DIR} ${LOG_DIR} ${DB_DIR}

    mkdir -p ${LOG_ROTATE_CONF}.d || error "Could not create ${LOG_ROTATE_CONF}.d"

    local log_rotate_default=${INI_DIR}/log_rotate_default.conf
    [ -r ${log_rotate_default} ] && cat ${log_rotate_default}      > ${LOG_ROTATE_CONF}.conf
    printf "# Include config files\ninclude ${LOG_ROTATE_CONF}.d\n" >> ${LOG_ROTATE_CONF}.conf || error "Could not initialize logrotate"
}

rudi_run() {
    ( sleep 60 ; watch -t -n 60 \
	  "/usr/sbin/logrotate --state ${SAFE_DIR}/logrotate.state ${LOG_ROTATE_CONF}.conf" \
	  >> ${LOG_DIR}/crontab.log || error "Could not launch cron" ) &
}

rudi_force_backup() {
    /usr/sbin/logrotate -f --state ${SAFE_DIR}/logrotate.state ${LOG_ROTATE_CONF}.conf
}

_preprocess_keys() {
    for k in ${GLOBAL_VARS}; do
	echo -n " -e" 's~@'${k}'@~'$(eval echo -n \$${k})'~g'
    done
}

preprocess() {
    local file=${1:-conf.ini}
    [ -r ${file}.am ] || return
    sed $(_preprocess_keys) \
	< ${file}.am \
	> ${file}        || error "Could not preprocess: ${file}"
}
