#!/usr/bin/env bash
#===================================================================================================
# This files is used to initialize the environments variables necessary for the RUDI modules to run.
# It only deals with variables that are fixed:
#
#===================================================================================================
# log_msg Dokerfile env variables
# echo WK_DIR: "$WK_DIR"
# echo SSH_DIR: "$SSH_DIR"
# echo ENV_DIR: "$ENV_DIR"
# echo env_init_sh: "$env_init_sh"

# shellcheck source=./git-rev.ini
log_msg Initializaing the environment variables

log_msg INIT git revisions
source "./env/git-rev.ini"

export WK_DIR=/app/rudi-node

# Checking if git rev variables were set
if [ -z "$CATALOG_GIT_REV" ]; then
    echo "WARN File \"${WK_DIR}/1-pull-rudi-node-gits.sh\" (line 49) should have been executed beforehand"
fi


#---------------------------------------------------------------------------------------------------
# Common constants
#---------------------------------------------------------------------------------------------------
log_msg INIT common constants
export LOG_DIR=/var/log/rudi

#---------------------------------------------------------------------------------------------------
# RUDI Catalog module constants
#---------------------------------------------------------------------------------------------------
log_msg INIT MongoDB constants
export MONGO_PORT=27017
export DUMP_DIR=/data/dump
export DB_LOG_DIR=/var/logs/db


log_msg INIT RUDI Catalog constants

# ----- External URL for the RUDI Catalog module
# Overrides the following setting in conf file:         [server.server_url]
export RUDI_CATALOG_URL=$public_url

# ----- DB connection URI
# Overrides the following setting in conf file:         [database.db_connection_uri]
export RUDI_CATALOG_DB_URI="mongodb://localhost:${MONGO_PORT}/rudi_api"

# ----- Node environment: 'production'|'development'
export RUDI_CATALOG_ENV="$NODE_ENV"
export RUDI_CATALOG_GIT_REV="$CATALOG_GIT_REV"

conf_path () {
    if [ -f "$CONF_DIR/$1" ]; then echo "$CONF_DIR/$1"; else echo "$INI_DIR/$1"; fi
}
# ----- Path of the configuration file for the RUDI Catalog module
export RUDI_CATALOG_USER_CONF=$(conf_path rudi-catalog-conf.ini)

# ----- Path of the configuration file for the connection to the RUDI portal
export RUDI_CATALOG_PORTAL_CONF=$(conf_path rudi-catalog-portal.ini)

# ----- File for the security configuration
# (key location + authorized route names for every client)
# Overrides the following setting in conf file:         [security.profiles]
export RUDI_CATALOG_PROFILES_CONF=$(conf_path rudi-catalog-profiles.ini)

# Path of the configuration file for the RUDI Storage module
export RUDI_STORAGE_USER_CONF=$(conf_path rudi-storage-conf.ini)

# Path of the configuration file for the RUDI Manager module
export RUDI_MANAGER_USER_CONF=$(conf_path rudi-manager-conf.ini)

log_msg Initialization complete
