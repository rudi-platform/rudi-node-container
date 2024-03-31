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

echo
echo "----- I'm here:"
pwd
echo
echo "----- I see: "
l
echo ------
whoami 
ls /data/dump

# MongoDB default port
MONGO_PORT=27017

# Retrieve the last dump in the bound folder /data/dump/
db_restore () {
    if [ ! -d /data/dump ]; then 
        log_msg "db_restore: folder /data/dump was found."
        exit 0
    fi

    # Wait for MongoDB to be ready for connections
    until nc -z localhost $MONGO_PORT; do
        echo waiting for MongoDB to initialize...
        sleep 1
    done
    echo $(nc -z localhost $MONGO_PORT)

    log_msg Restoring a previously dumped DB
    last_dump=/data/dump/$(last_modified /data/dump)
    echo last_dump: $last_dump
    # Restoring a DB dumped with the following command
    # mongodump -d rudi_prod --excludeCollection logentries --archive=/data/dump/rudi_api_dump.gz --gzip 
    mongorestore -vvvvv --archive="${last_dump}" --gzip --numInsertionWorkersPerCollection=6
    log_msg DB restored

}
# Start MongoDB in the background
log_msg Launching MongoDB
mongod &
db_restore &
wait
exit 0

# Start the RUDI Node module: API
log_msg "Launching RUDI node module: API"
cd ./rudi-api/ && npm run rudiapp &

echo "Execution time: $(time_spent_s ${TIME_START})s ($(basename "$0"))"

wait

