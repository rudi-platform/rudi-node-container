#
# From global configuration
ROOT_DIR=$(dirname "$(readlink -f "$0")")
source "${ROOT_DIR}/env-rudi.sh"

#
# Network options
DB_LISTEN_ALL=${DB_LISTEN_ALL:-false}

#
# BD Storage locations
DB_LOG_DIR=${DB_LOG_DIR:-${LOG_DIR}/db}
DB_DATA_DIR=${DB_DATA_DIR:-${DB_DIR}}
DB_DUMP_DIR=${DB_DUMP_DIR:-${MEDIA_DIR}/zone_db}
DB_DUMP_PATH=${DB_DUMP_PATH:-${DB_DUMP_DIR}/db_${DB_PREFIX:-default}.mongo}

# Restore sentinel (persistent, explicit): persistent marker for “already restored”
DB_RESTORE_MARKER="${DB_DATA_DIR}/.restore_done"

log_msg Init RUDI DB variables

#
# DB Management functions
is_db_alive() {
    ! ( netstat -ltn | grep -q ":$MONGODB_PORT" ) # TODO:Rendre portable en fonction des bases de container.
}

#
# Waiting for MongoDB to be ready
db_wait()  {
    ITE=${DB_WAIT_MAX:-60}
    while [ "$ITE" -gt 0 ] && is_db_alive; do
        log_msg "waiting for MongoDB to initialize (${ITE})..."
        sleep 1
        ITE=$(($ITE - 1))
    done
    [ $ITE -eq 0 ] && return 1
    log_msg MongoDB is ready and listening
    # echo D port=$MONGODB_PORT
    # echo D mongo version=$(mongod --version)
}

# Restore database from dump (authoritative restore)
db_restore()  {
    local db_dump_file="$1"

    # Ensure file exists and is readable
    [ -r "${db_dump_file}" ] || error "Restore file not readable: '${db_dump_file}'"

    # Wait for MongoDB to be alive before restoring
    db_wait || error "Cannot restore: MongoDB is not running"

    log_msg "Restoring database from '${db_dump_file}'"

    # Restoring a DB dumped with the following command
    # mongodump -d rudi_prod --excludeCollection logentries --archive=/data/dump/rudi_catalog_dump.gz --gzip
    mongorestore \
        --drop \
        --archive="${db_dump_file}" \
        --gzip ||
        error "Restauration failed from '${db_dump_file}'"

    # Mark that restore has been done (idempotent)
    touch "${DB_RESTORE_MARKER}"
    log_msg "Database restored successfully from '${db_dump_file}'"
}

db_check() {
    log_msg "Checking DB"
    test -d "${DB_DATA_DIR}" || error "Could not find '${DB_DATA_DIR}'"
    test -d "${DB_LOG_DIR}"  || mkdir -p "${DB_LOG_DIR}" || error "Could not create log folder '${DB_LOG_DIR}'"
    test -d "${DB_DUMP_DIR}" || mkdir -p "${DB_DUMP_DIR}" || error "Could not create DB dump folder '${DB_DUMP_DIR}'"

    # Add automatic backup in logrotate
    cat >"${LOG_ROTATE_CONF}.d/rudi-db.conf"  <<EOF
${DB_DUMP_PATH} {
    missingok
    nocompress
    firstaction
        /usr/bin/mongodump --forceTableScan --gzip --archive=${DB_DUMP_PATH} ${MONGODB}
    endscript
    postrotate
        rm -f '${DB_RESTORE_MARKER}'
	    cp -p '${DB_DUMP_PATH}'.1 '${DB_DUMP_PATH}'
    endscript
}
EOF
}

db_run() {
    # Starting MongoDB in the background
    log_msg "Launching MongoDB on $MONGODB_PORT"

    local extraopts=""
    [ "${DB_LISTEN_ALL}" = "true" ] && extraopts="--bind_ip_all"

    # Start MongoDB in background, redirect stdout+stderr to log
    mongod \
        --port ${MONGODB_PORT} \
        --dbpath "${DB_DATA_DIR}" \
        ${extraopts} \
        >>"${DB_LOG_DIR}/mongo-$(now_s_str).log" 2>&1 &

    # Save PID for later stop
    PIDS="${PIDS:-} $!"
    log_msg "MongoDB started with PID $!"

    # Wait for MongoDB to be ready
    if ! db_wait; then
        log_msg "MongoDB failed to start within ${DB_WAIT_MAX:-60}s. Check log: ${DB_LOG_DIR}/mongo-*.log"
        error "MongoDB did not start"
    fi

    # ---- Determine which dump to restore ----

    # Priority 1: user-provided restore file
    local restore_file="${DB_DUMP_DIR}/restore_${DB_PREFIX}.mongo"
    if [ -r "${restore_file}" ]; then
        log_msg "Using custom restore file: ${restore_file}"
    # Priority 2: default dump archive
    elif [ ! -f "${DB_RESTORE_MARKER}" ] && [ -r "${DB_DUMP_PATH}" ]; then
        restore_file="${DB_DUMP_PATH}"
        log_msg "Using default dump: '${restore_file}'"
    else
        restore_file=""
        log_msg "No restore needed"
    fi
    # ---- Perform restore if needed ----
    if [ -n "${restore_file}" ]; then
        db_restore "${restore_file}"
    fi
}
