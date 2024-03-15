# !/bin/bash

ls -la

source .bashrc

WK_DIR=`pwd`

npm config set loglevel error
npm i -g npm@latest

for module in api media prodmanager console crypto; do
    logmsg "Installing nodejs app: rudi-${module} "
    cd "${WK_DIR}/rudi-${module}" && npm i
    if [ -d "front" ]; then 
        logmsg "Installing front: rudi-${module} "
        cd front
        npm run install:dev
        npm run build:prod 
    fi
done

logmsg "Internal setup over"