# !/bin/bash

ls -la

source .bashrc
mv .bashrc ~

WK_DIR=`pwd`

npm config set loglevel error
npm i -g npm@latest

logmsg "Installing MongoDB"
# ccd "${WK_DIR}/mongo" && npm i -g mongo 

for module in api media prodmanager console crypto; do
    logmsg "Installing NodeJS app: rudi-${module} "
    export NODE_ENV=production
    cd "${WK_DIR}/rudi-${module}" && npm i -g
    # if [ -d "front" ]; then 
    #     logmsg "Installing front: rudi-${module} "
    #     cd front
    #     npm run install:dev
    #     npm run build:prod 
    # fi
done

logmsg "Internal setup over"