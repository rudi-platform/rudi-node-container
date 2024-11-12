#
# From global configuration
ROOT_DIR=$(dirname $(readlink -f $0))
. ${ROOT_DIR}/env-rudi.sh

#
# URL
CRYPTO_PUBLIC_URL=${CRYPTO_PUBLIC_URL:-${NODE_PUBLIC_URL}:${NODE_CRYPTO_PORT}}
APP_CRYPTO_DIR=${APP_CRYPTO_DIR:-${APP_DIR}/rudi-crypto}

#
# Config files
CRYPTO_CONF="${CRYPTO_CONF:-${INI_DIR}/rudi-crypto-conf.ini}"
CRYPTO_KEY=${CRYPTO_KEY:-crypto_mngr}

log_msg Init RUDI crypto variables

crypto_check() {
    test -z "${CRYPTO_GIT_REV:-}" && error "crypto git rev not set"
    test -d ${APP_CRYPTO_DIR}  || error "Could not find ${APP_CRYPTO_DIR}"

    preprocess ${CRYPTO_CONF}

    test -r ${CRYPTO_CONF}     || error "Could not find ${CRYPTO_CONF}"
    assert_key ${CRYPTO_KEY} rudiadm rudi
}

crypto_run() {
    local env=${ENV:-"production"}

    # Starting RUDI node Crypto
    log_msg "Launching RUDI node module: Crypto"
    cd "${APP_CRYPTO_DIR}" || error "Crypto application directory not found"
    echo "$CRYPTO_PROFILES"
    ls -lah    "$CRYPTO_PROFILES"
    node rudiServer.js                       \
	 --node_env "$env"                   \
	 --app_env  "$env"                   \
	 --hash      "$CRYPTO_GIT_REV"      \
	 --url       "$CRYPTO_PUBLIC_URL"   \
	 --conf      "$CRYPTO_CONF"        || error "Could not launch app in ${APP_CRYPTO_DIR}"
}
