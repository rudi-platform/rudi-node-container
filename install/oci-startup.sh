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

echo
echo "----- I'm here:"
pwd
echo
echo "----- I see: "
ls -la

ls -la /var/lib
ls -la /var/log/mongodb

logmsg "Launching the app..."
service mongod restart