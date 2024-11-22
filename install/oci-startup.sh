#!/usr/bin/env bash

# ==================================================================================================
# This script launches (in order):
# - MongoDB
# - RUDI Catalog (ex-API)
# - RUDI Storage (ex-Media)
# - RUDI Manager: backend
# - RUDI Manager: frontend
#
# It then performs some tests
# ==================================================================================================


source ./.bashrc
source ./git-rev.ini 2?>&1

alias l="ls -lah"


TIME_START=$(now_ms_int)
log_msg "Executing as user $(whoami)"
log_msg Init RUDI environment variables

echo Content of ./ini folder:
ls -lah "$INI_DIR"

# echo
# echo "----- I'm here:"
# echo "$WK_DIR"
# echo
# echo "----- I see: "
# l
# echo "------"
# whoami

log_msg "Turning on bash's job control"
set -m

log_msg "DB preparation"
export MONGO_PORT=27017
export DUMP_DIR=/data/dump

# Waiting for MongoDB to be ready
db_wait () {
    until nc -z localhost "$MONGO_PORT"; do
        echo waiting for MongoDB to initialize...
        sleep 1
    done
    log_msg DB is ready and listening on $(nc -z localhost "$MONGO_PORT")
}

# Retrieving the last dump in the bound folder /data/dump/

db_restore () {
    if [ ! -d "${DUMP_DIR}" ]; then
        log_msg "db_restore: folder ${DUMP_DIR} was not found."
    fi
    # Wait for MongoDB to be ready for connections
    db_wait

    log_msg Restoring a previously dumped DB
    # shellcheck disable=SC2086
    last_dump="${DUMP_DIR}/$(last_modified ${DUMP_DIR})"
    echo "last_dump: \"${last_dump}\""
    echo
    # Restoring a DB dumped with the following command
    # mongodump -d rudi_prod --excludeCollection logentries --archive=/data/dump/rudi_catalog_dump.gz --gzip
    mongorestore --archive="${last_dump}" --gzip --numInsertionWorkersPerCollection=6
    log_msg DB restored
}

# Starting MongoDB in the background
log_msg "Launching MongoDB"
export DB_LOG_DIR="/tmp/logs/mongo"
mkdir -p "$DB_LOG_DIR"
mongod > "${DB_LOG_DIR}/mongo-$(now_s_str).log" &
# db_restore

# Generating the SSH keys
log_msg "SSH setup"
chmod 700 "$SSH_DIR"

for keyname in storage_mngr catalog_mngr; do
    ssh-keygen -t ed25519 -C "$keyname" -q -N '' -f "$SSH_DIR/$keyname"
    chmod 400 "$SSH_DIR"/*
done
chmod 500 "$SSH_DIR"

echo "Key generated"
ls -lah "$SSH_DIR"

# Starting RUDI node Catalog
log_msg "Launching RUDI node module: Catalog"
cd "${WK_DIR}/rudi-catalog/" || exit
echo "$CATALOG_PROFILES"
ls -lah    "$CATALOG_PROFILES"
node run-rudinode-catalog.js            \
    --node_env "$ENV"                   \
    --app_env  "$ENV"                   \
    --hash      "$CATALOG_GIT_REV"      \
    --url       "$CATALOG_PUBLIC_URL"   \
    --conf      "$CATALOG_CONF"         \
    --db_uri    "$CATALOG_DB_URI"       \
    --profiles  "$CATALOG_PROFILES"     \
    --portal_conf "$PORTAL_CONF"        &

# Starting RUDI node Storage
log_msg "Launching RUDI node module: Storage"
cd "${WK_DIR}/rudi-storage/" || exit
node run-rudinode-storage.js        \
    --hash "$STORAGE_GIT_REV"       \
    --url  "$STORAGE_PUBLIC_URL"    \
    --conf "$STORAGE_CONF"          &

# Starting RUDI node Manager backend (node_env!="development" => serves the built front-end)
log_msg "Launching RUDI node module: Manager"
cd "${WK_DIR}/rudi-manager/" || exit
node run-rudinode-manager.js        \
    --su "$SU"                      \
    --tag "$TAG"                    \
    --node_env "$ENV"               \
    --hash "$MANAGER_GIT_REV"       \
    --url  "$MANAGER_PUBLIC_URL"    \
    --conf "$MANAGER_CONF"          \
    --db   "$MANAGER_DB_PATH"       &

# Bringing the primary process back ito the foreground
# and leaving it there
fg %1

# Waiting for any process to exit
wait

log_msg "Launching over"
echo "Execution time for launching: $(time_spent_s "${TIME_START}")s ($(basename "$0"))"

# Exiting with status of process that exited first
exit $?
