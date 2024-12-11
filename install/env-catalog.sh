#
# From global configuration
ROOT_DIR=$(dirname $(readlink -f $0))
. ${ROOT_DIR}/env-rudi.sh

#
# URL
APP_CATALOG_DIR=${APP_CATALOG_DIR:-${APP_DIR}/rudi-catalog}

#
# Config files
CATALOG_CONF="${CATALOG_CONF:-${INI_DIR}/rudi-catalog-conf.ini}"
PORTAL_CONF="${PORTAL_CONF:-${INI_DIR}/rudi-catalog-portal.ini}"

CATALOG_EXTERNAL_PROFILES="${CATALOG_EXTERNAL_PROFILES:-${INI_DIR}/rudi-catalog-profiles.ini}"
CATALOG_PROFILES="${CATALOG_PROFILES:-${SAFE_DIR}/rudi-catalog-profiles.ini}"

#
# DB configuration
CATALOG_DB_NAME=${CATALOG_DB_NAME:-${DB_PREFIX}-db_catalog}
CATALOG_DB_URI=${CATALOG_DB_URI:-${MONGODB}/${CATALOG_DB_NAME}}

log_msg Init RUDI manager variables

generateProfile() {
    local name=${1:-invited}
    local key=${2:-${PUBKEY_DIR}/invited.pub}
    cat <<EOF
;--------------------------------------------------------------------------
; Profile for ${name}
;--------------------------------------------------------------------------
[rudi_node_${name}]
pub_key=${key}
routes[]="all"
EOF

}

catalog_check() {
    test -z "${CATALOG_GIT_REV:-}" && error "catalog git rev not set"
    test -d ${APP_CATALOG_DIR} || error "Could not find ${APP_CATALOG_DIR}"

    preprocess ${CATALOG_CONF}
    preprocess ${CATALOG_EXTERNAL_PROFILES}
    preprocess ${PORTAL_CONF}

    generateProfile manager ${PUBKEY_DIR}/catalog_mngr.pub >${CATALOG_PROFILES}
    cat ${CATALOG_EXTERNAL_PROFILES} >>${CATALOG_PROFILES}

    test -r ${CATALOG_CONF}     || error "Could not find ${CATALOG_CONF}"
    test -r ${CATALOG_PROFILES} || error "Could not find ${CATALOG_PROFILES}"
    test -r ${PORTAL_CONF}      || error "Could not find ${PORTAL_CONF}"
}

catalog_run() {
    local env=${ENV:-"production"}

    # Starting RUDI node Catalog
    log_msg "Launching RUDI node module: Catalog"
    cd "${APP_CATALOG_DIR}" || error "Catalog application directory not found"
    echo "$CATALOG_PROFILES"
    ls -lah "$CATALOG_PROFILES"
    node run-rudinode-catalog.js        \
        --node_env "$env"               \
        --app_env "$env"                \
        --hash "$CATALOG_GIT_REV"       \
        --url "$CATALOG_PUBLIC_URL"     \
        --conf "$CATALOG_CONF"          \
        --db_uri "$CATALOG_DB_URI"      \
        --profiles "$CATALOG_PROFILES"  \
        --portal_conf "$PORTAL_CONF"    ||
           error "Could not launch app in ${APP_CATALOG_DIR}"
}
