#!/usr/bin/env bash

# ==================================================================================================
# This script installs all the module (except prodmanager/front that was built earlier)
# ==================================================================================================


source .bashrc
TIME_START=$(now_ms_int)

# log_msg Dokerfile env variables
# echo WK_DIR: "$WK_DIR"
# echo SSH_DIR: "$SSH_DIR"
# echo ENV_DIR: "$ENV_DIR"
# echo env_init_sh: "$env_init_sh"


log_msg Init RUDI environment variables
source "$env_init_sh"
echo RUDI_CATALOG_USER_CONF="$RUDI_CATALOG_USER_CONF"

chmod 100 "$ENV_DIR"

log_msg "SSH setup"
chmod 700 "$SSH_DIR"

for keyname in ${SSH_KEYS[@]}; do
    genssh "$keyname" "$SSH_DIR/"
done
chmod 400 "$SSH_DIR"/*.pub
chmod 500 "$SSH_DIR"

l "$SSH_DIR"


log_msg "Upgrading NPM"
export PATH="$(npm get prefix):$PATH"
npm config set loglevel error && npm i -g npm@latest

for module in catalog storage manager console crypto; do
    log_msg "Installing NodeJS app: rudi-$module"
    cd "$WK_DIR/rudi-$module" && npm i
done
echo
echo global packages installed here: "$(npm root -g)"
echo


# echo ---
# npm config list



log_msg "Internal setup over"
echo
echo "Execution time: $(time_spent_s "$TIME_START")s ($(basename "$0"))"
