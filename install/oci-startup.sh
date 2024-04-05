#!/usr/bin/env bash

# ==================================================================================================
# This script launches (in order):
# - MongoDB
# - RUDI API
# - RUDI Media
# - RUDI Prodmanager: backend
# - RUDI Console
#
# It then performs some tests
# ==================================================================================================

source .bashrc
TIME_START=$(now_ms_int)

export WK_DIR=$(pwd)
export ENV_DIR="${WK_DIR}/env"

# shellcheck source=./env-var-init.sh
source "${ENV_DIR}/env-var-init.sh"
echo RUDI_API_USER_CONF="$RUDI_API_USER_CONF"

echo
echo "----- I'm here:"
echo "$WK_DIR"
echo
echo "----- I see: "
l
echo ------
# whoami 

# MongoDB default port
export MONGO_PORT=27017
export DUMP_DIR=/data/dump

if [ ! -d "$DUMP_DIR" ]; then log_msg "db_restore: folder $DUMP_DIR was not found."; exit 0; fi

db_wait () {
        until nc -z localhost $MONGO_PORT; do
        echo waiting for MongoDB to initialize...
        sleep 1
    done
    log_msg DB is ready and listening on $(nc -z localhost $MONGO_PORT)
}
# Retrieve the last dump in the bound folder /data/dump/
db_restore () {
        # Wait for MongoDB to be ready for connections
    db_wait

    log_msg Restoring a previously dumped DB
    ls "$DUMP_DIR"
    last_dump="$DUMP_DIR/$(last_modified $DUMP_DIR)"
    echo last_dump: \""$last_dump"\"
    echo
    # Restoring a DB dumped with the following command
    # mongodump -d rudi_prod --excludeCollection logentries --archive=/data/dump/rudi_api_dump.gz --gzip 
    mongorestore --archive="${last_dump}" --gzip --numInsertionWorkersPerCollection=6
    log_msg DB restored
    }
# Start MongoDB in the background
log_msg Launching MongoDB
DB_LOG_DIR=/var/logs/db
mkdir -p $DB_LOG_DIR
mongod > "$DB_LOG_DIR/mongo-$(now_s_str).log" &
db_restore &

db_wait
# Start the RUDI Node module: API
log_msg Launching RUDI node module: API
# echo $NODE_PATH
# ls $NODE_PATH/npm/*

echo "${WORK_DIR} contents:"
ls "$WORK_DIR"

cd "${WORK_DIR}/rudi-api/" && npm run rudiapp &

log_msg Launching over
echo "Execution time for launching: $(time_spent_s "${TIME_START}")s ($(basename "$0"))"

wait

