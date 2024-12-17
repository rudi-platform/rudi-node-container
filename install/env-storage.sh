#
# From global configuration
ROOT_DIR=$(dirname $(readlink -f $0))
. ${ROOT_DIR}/env-rudi.sh

#
# URL
STORAGE_PORT=${STORAGE_PORT:-$((${NODE_BASE_PORT}+1))}
STORAGE_PUBLIC_URL=${STORAGE_PUBLIC_URL:-${NODE_PUBLIC_URL}:${STORAGE_PORT}}
APP_STORAGE_DIR=${APP_STORAGE_DIR:-${APP_DIR}/rudi-storage}

#
# Config files
STORAGE_CONF="${STORAGE_CONF:-${INI_DIR}/rudi-storage-conf.ini}"
STORAGE_LOG_DIR="${STORAGE_LOG_DIR:-${LOG_DIR}/media/}"

#
# DB configuration
STORAGE_DB_NAME=${STORAGE_DB_NAME:-db_storage}
STORAGE_DB_URI="${STORAGE_DB_URI:-${MONGODB}/${STORAGE_DB_NAME}}"

log_msg Init RUDI storage variables

storage_check() {
    test -z "${STORAGE_GIT_REV:-}" && error "catalog git rev not set"
    test -d ${APP_STORAGE_DIR}  || error "Could not find ${APP_STORAGE_DIR}"
    test -d ${STORAGE_LOG_DIR}  || mkdir -p ${STORAGE_LOG_DIR}

    preprocess ${STORAGE_CONF}
    test -r ${STORAGE_CONF} || error "Could not find ${STORAGE_CONF}"
}

storage_run() {
    # Starting RUDI node Storage
    log_msg "Launching RUDI node module: Storage"
    cd "${APP_STORAGE_DIR}" || error "Storage application directory not found"
    node run-rudinode-storage.js     \
	 --hash "$STORAGE_GIT_REV"       \
	 --url  "$STORAGE_PUBLIC_URL"    \
	 --conf "$STORAGE_CONF"          || error "Could not launch app in ${APP_STORAGE_DIR}"
}
