#
# From global configuration
ROOT_DIR=$(dirname $(readlink -f $0))
. ${ROOT_DIR}/env-rudi.sh

#
# URL
MANAGER_PUBLIC_URL=${MANAGER_PUBLIC_URL:-${NODE_PUBLIC_URL}:${MANAGER_PORT}}
APP_MANAGER_DIR=${APP_MANAGER_DIR:-${APP_DIR}/rudi-manager}

#
# Config files
MANAGER_CONF="${MANAGER_CONF:-${INI_DIR}/rudi-manager-conf.ini}"

# Tag for the container, usually the RUDI node version
TAG=${TAG:-RUDI-node-2.5.0}

#
# DB configuration
MANAGER_DB_DIR=${MANAGER_DB_DIR:-${DB_DIR}}
MANAGER_DB_PATH=${MANAGER_DB_PATH:-${MANAGER_DB_DIR}/rudi_mngr.db}
MANAGER_DUMP_DIR=${MANAGER_DUMP_DIR:-${MEDIA_DIR}/zone_db}
MANAGER_DUMP_PATH=${MANAGER_DUMP_PATH:-${MANAGER_DUMP_DIR}/rudi_${DB_PREFIX:-default}_mngr.db}

log_msg Init RUDI manager variables

manager_check() {
    test -z "${MANAGER_GIT_REV:-}" && error "manager git rev not set"
    test -d ${APP_MANAGER_DIR}  || error "Could not find ${APP_MANAGER_DIR}"

    preprocess ${MANAGER_CONF}
    test -r ${MANAGER_CONF}     || error "Could not find ${MANAGER_CONF}"

    test -d $(dirname ${MANAGER_DB_PATH})  || error "Could not find ${MANAGER_DB_PATH} directory"
    assert_key store_mngr rudiadm rudi
    assert_key catalog_mngr rudiadm rudi

    cat > ${LOG_ROTATE_CONF}.d/rudi-manager.conf <<EOF
${MANAGER_DUMP_PATH} {
    missingok
    firstaction
        /usr/bin/sqlite3 ${MANAGER_DB_PATH} ".backup '${MANAGER_DUMP_PATH}'"
    endscript
    postrotate
	cp -p '${MANAGER_DUMP_PATH}'.1 '${MANAGER_DUMP_PATH}'
    endscript
}
EOF

    [ ! -r ${MANAGER_DB_PATH} -a -e ${MANAGER_DUMP_PATH} ] && \
	/usr/bin/install -m 640 -o rudiadm -g rudi ${MANAGER_DUMP_PATH} ${MANAGER_DB_PATH}
}

manager_run() {
    local env=${ENV:-"production"}
    local su_flag=""

    # Let's check if $SU is set
    #   https://stackoverflow.com/a/13864829/1563072
    [ -z ${SU+x} ] || su_flag="--su ${SU}"

    # Starting RUDI node Manager backend (node_env!="development" => serves the built front-end)
    log_msg "Launching RUDI node module: Manager"
    cd "${APP_MANAGER_DIR}" || error "Manager application directory not found"

    touch ${MANAGER_DUMP_PATH}
    node run-rudinode-manager.js   \
	 ${su_flag}                    \
	 --tag "$TAG"                  \
	 --node_env "$env"             \
	 --hash "$MANAGER_GIT_REV"     \
	 --url  "$MANAGER_PUBLIC_URL"  \
	 --conf "$MANAGER_CONF"        \
	 --db   "$MANAGER_DB_PATH"     || error "Could not launch app in ${APP_MANAGER_DIR}"
}
