#
# From global configuration
ROOT_DIR=$(dirname $(readlink -f $0))
. ${ROOT_DIR}/env-rudi.sh

#
# URL
JWTAUTH_PUBLIC_URL=${JWTAUTH_PUBLIC_URL:-${NODE_PUBLIC_URL}:${JWTAUTH_PORT}}
APP_JWTAUTH_DIR=${APP_JWTAUTH_DIR:-${APP_DIR}/rudi-jwtauth}

#
# Config files
JWTAUTH_CONF="${JWTAUTH_CONF:-${INI_DIR}/rudi-jwtauth-conf.ini}"
JWTAUTH_KEY=${JWTAUTH_KEY:-jwtauth_mngr}

log_msg Init RUDI jwtauth variables

jwtauth_check() {
    test -z "${JWTAUTH_GIT_REV:-}" && error "jwtauth git rev not set"
    test -d ${APP_JWTAUTH_DIR}  || error "Could not find ${APP_JWTAUTH_DIR}"

    preprocess ${JWTAUTH_CONF}

    test -r ${JWTAUTH_CONF}     || error "Could not find ${JWTAUTH_CONF}"
    assert_key ${JWTAUTH_KEY} rudiadm rudi
}

jwtauth_run() {
    local env=${ENV:-"production"}

    # Starting RUDI node JwtAuth module
    log_msg "Launching RUDI node module: JwtAuth"
    cd "${APP_JWTAUTH_DIR}" || error "JwtAuth application directory not found"
    echo "$JWTAUTH_PROFILES"
    ls -lah    "$JWTAUTH_PROFILES"
    node run-rudinode-jwtauth.js        \
	 --node_env "$env"                  \
	 --app_env  "$env"                  \
	 --hash      "$JWTAUTH_GIT_REV"      \
	 --url       "$JWTAUTH_PUBLIC_URL"   \
	 --conf      "$JWTAUTH_CONF"        || error "Could not launch app in ${APP_JWTAUTH_DIR}"
}
