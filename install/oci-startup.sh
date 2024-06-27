#!/usr/bin/env bash

# ==================================================================================================
# This script launches (in order):
# - MongoDB
# - RUDI Catalog (ex-API)
# - RUDI Storage (ex-Media)
# - RUDI Manager: backend
# - RUDI Manager: frontend
# - RUDI Console
#
# It then performs some tests
# ==================================================================================================

source .bashrc
TIME_START=$(now_ms_int)

log_msg Init RUDI environment variables
source "${env_init_sh}"
echo RUDI_CATALOG_USER_CONF="$RUDI_CATALOG_USER_CONF"

# echo
# echo "----- I'm here:"
# echo "$WK_DIR"
# echo
# echo "----- I see: "
# l
# echo "------"
# whoami

log_msg "----- Turning on bash's job control"
set -m

log_msg "----- DB preparation"

# Waiting for MongoDB to be ready
db_wait () {
        until nc -z localhost $MONGO_PORT; do
        echo waiting for MongoDB to initialize...
        sleep 1
    done
    log_msg DB is ready and listening on $(nc -z localhost $MONGO_PORT)
}

# Retrieving the last dump in the bound folder /data/dump/
db_restore () {
    if [ ! -d "${DUMP_DIR}" ]; then
        log_msg "db_restore: folder ${DUMP_DIR} was not found."
    fi
    # Wait for MongoDB to be ready for connections
    db_wait

    log_msg Restoring a previously dumped DB
    last_dump="${DUMP_DIR}/$(last_modified ${DUMP_DIR})"
    echo "last_dump: \"${last_dump}\""
    echo
    # Restoring a DB dumped with the following command
    # mongodump -d rudi_prod --excludeCollection logentries --archive=/data/dump/rudi_catalog_dump.gz --gzip
    mongorestore --archive="${last_dump}" --gzip --numInsertionWorkersPerCollection=6
    log_msg DB restored
}

# Starting MongoDB in the background
log_msg "----- Launching MongoDB"
mkdir -p "$DB_LOG_DIR"
mongod > "${DB_LOG_DIR}/mongo-$(now_s_str).log" &
db_restore

# Starting RUDI node Catalog in the background
log_msg "----- Launching RUDI node module: Catalog"
cd "${WK_DIR}/rudi-catalog/"
node rudiServer.js --conf="$RUDI_CATALOG_USER_CONF" &


# Starting RUDI node Storage in the background
log_msg "----- Launching RUDI node module: Storage"
cd "${WK_DIR}/rudi-storage/"
node index.js --revision "$revision" --ini "$RUDI_STORAGE_USER_CONF" &

# Bringing the primary process back ito the foreground
# and leaving it there
fg %1

# Waiting for any process to exit
wait

log_msg "----- Launching over"
echo "Execution time for launching: $(time_spent_s "${TIME_START}")s ($(basename "$0"))"

# Exiting with status of process that exited first
exit $?
