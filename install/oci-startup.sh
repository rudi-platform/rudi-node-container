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
source "${ENV_INIT_SH}"
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

# Generating the SSH keys
log_msg "SSH setup"
chmod 700 "$SSH_DIR"

for keyname in storage_mngr catalog_mngr; do
    ssh-keygen -t ed25519 -C "$keyname" -q -N '' -f "$SSH_DIR/$keyname"
    chmod 400 "$SSH_DIR"/*
done
chmod 500 "$SSH_DIR"

echo "Key generated"
l "$SSH_DIR"

# Starting RUDI node Catalog
log_msg "----- Launching RUDI node module: Catalog"
cd "${WK_DIR}/rudi-catalog/"
node rudiServer.js --hash="$catalog_git_rev" --conf="$RUDI_CATALOG_USER_CONF" &

# Starting RUDI node Storage
log_msg "----- Launching RUDI node module: Storage"
cd "${WK_DIR}/rudi-storage/"
node index.js --revision "$storage_git_rev" --ini "$RUDI_STORAGE_USER_CONF" &

# Starting RUDI node Manager backend (node_env="production" => serves the built front-end)
log_msg "----- Launching RUDI node module: Manager"
cd "${WK_DIR}/rudi-manager/"
node server.js --hash $manager_git_rev --tag "$REVISION" --node_env="production" --conf "$RUDI_MANAGER_USER_CONF" &

# Starting RUDI node Console
log_msg "----- Launching RUDI node module: Console"
cd "${WK_DIR}/rudi-console/"
node index.js --revision "$console_git_rev" --config "$RUDI_CONSOLE_USER_CONF" &

# Bringing the primary process back ito the foreground
# and leaving it there
fg %1

# Waiting for any process to exit
wait

log_msg "----- Launching over"
echo "Execution time for launching: $(time_spent_s "${TIME_START}")s ($(basename "$0"))"

# Exiting with status of process that exited first
exit $?
