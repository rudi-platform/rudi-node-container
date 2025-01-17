#
# From global configuration
ROOT_DIR=$(dirname $(readlink -f $0))
. ${ROOT_DIR}/env-rudi.sh

#
# Network options
DB_LISTEN_ALL=${DB_LISTEN_ALL:-false}


#
# BD Storage locations
DB_LOG_DIR=${DB_LOG_DIR:-${LOG_DIR}}
DB_DATA_DIR=${DB_DATA_DIR:-${DB_DIR}}
DB_DUMP_DIR=${DB_DUMP_DIR:-${MEDIA_DIR}/zone_db}
DB_DUMP_PATH=${DB_DUMP_PATH:-${DB_DUMP_DIR}/db_${DB_PREFIX:-default}.mongo}

log_msg Init RUDI DB variables

#
# DB Management functions
is_db_alive() {
    ! ( netstat -ltn | grep -q :$MONGODB_PORT ) # TODO:Rendre portable en fonction des bases de container.
}

# Waiting for MongoDB to be ready
db_wait () {
    ITE=${DB_WAIT_MAX:-60}
    while [ $ITE -gt 0 ] && is_db_alive; do
        echo "waiting for MongoDB to initialize (${ITE})..."
        sleep 1
	ITE=$(($ITE-1))
    done
    [ $ITE -eq 0 ] &&
	return 1 ||
	    log_msg DB is ready and listening on $MONGODB_PORT
}

# Retrieving the last dump in the bound folder /data/dump/
db_restore () {
    local db_dump_file=${1:-./dump}

    # Wait for MongoDB to be ready for connections
    db_wait || error "Restauration impossible, mongodb not running"

    log_msg Restoring a previously dumped DB

    # Restoring a DB dumped with the following command
    # mongodump -d rudi_prod --excludeCollection logentries --archive=/data/dump/rudi_catalog_dump.gz --gzip
    mongorestore --archive="${db_dump_file}" --gzip --numInsertionWorkersPerCollection=6 &&
	log_msg DB restored ||
	    error "Restauration from ${db_dump_file} failed"
}

db_check() {
    test -r ${DB_DATA_DIR}     || error "Could not find ${DB_DATA_DIR}"
    test -d ${DB_LOG_DIR}      || mkdir -p ${DB_LOG_DIR}

    # Add automatic backup in logrotate
    test -r ${DB_DUMP_DIR} || mkdir -p ${DB_DUMP_DIR} || error "Could not create ${dbdir}"

    cat > ${LOG_ROTATE_CONF}.d/rudi-db.conf <<EOF
${DB_DUMP_PATH} {
    missingok
    nocompress
    firstaction
        /usr/bin/mongodump --forceTableScan --gzip --archive=${DB_DUMP_PATH} ${MONGODB}
    endscript
    postrotate
	cp -p '${DB_DUMP_PATH}'.1 '${DB_DUMP_PATH}'
    endscript
}
EOF
}

db_run() {
    # Starting MongoDB in the background
    log_msg "Launching MongoDB"
    local extraops=""
    ${DB_LISTEN_ALL} && extraops=" --bind_ip_all"
    (mongod --port ${MONGODB_PORT} --dbpath ${DB_DATA_DIR} ${extraops} \
	    >> "${DB_LOG_DIR}/mongo-$(now_s_str).log" || error "launching mongodb " ) &
    PIDS="${PIDS:-} $!"

    local restore_file=${DB_DUMP_DIR}/restore_${DB_PREFIX}.mongo

    if [ ! -r ${restore_file} -a ! -e ${DB_DATA_DIR}/storage.bson -a -r ${DB_DUMP_PATH} ]; then
	    restore_file=${DB_DUMP_PATH}
    else
	    touch ${DB_DUMP_PATH}
    fi

    [ -r ${restore_file} ] && db_restore ${restore_file} || db_wait
}
