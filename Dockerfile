FROM mongo:7.0.7

# Additional dependecies
RUN apt-get update && apt-get install -y curl                    && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -    && \
    apt-get install -y                                              \
        netcat                                                      \
        nodejs                                                      \
        vim                                                         \
        keychain                                                 && \
    apt-get clean                                                && \
    rm -rf /var/lib/apt/lists/*


# # User
# ARG DOCKER_USR=default_user
# RUN groupadd -g 6000 "$DOCKER_USR"                           && \
#     useradd -ms /bin/bash -u 6001 -g "$DOCKER_USR" "$DOCKER_USR"
# USER $DOCKER_USR

# Folder that contains the source of every rudi-node module
ARG SRC_DIR="./src"

ENV WK_DIR="/app/rudi-node"                  \
    SSH_DIR="/.ssh"                          \
    STORAGE_DIR="/data/media"                \
    DUMP_DIR="/data/dump"                    \
    DB_DIR="/data/db"

WORKDIR "$WK_DIR"
ENV INI_DIR="$WK_DIR/ini"

# Public URL of the container (used for the metadata connector URL)
ARG NODE_PUBLIC_URL="http://localhost"
ARG CATALOG_PUBLIC_URL="$NODE_PUBLIC_URL:3030"
ARG STORAGE_PUBLIC_URL="$NODE_PUBLIC_URL:3031"
ARG MANAGER_PUBLIC_URL="$NODE_PUBLIC_URL:3033"

# Path for the conf files of each RUDI node module
ARG CATALOG_CONF="$INI_DIR/rudi-catalog-conf.ini"
ARG STORAGE_CONF="$INI_DIR/rudi-storage-conf.ini"
ARG MANAGER_CONF="$INI_DIR/rudi-manager-conf.ini"

# Specific configuration for Catalog
ARG CATALOG_DB_URI="mongodb://localhost:27017/rudi_api"
ARG CATALOG_PROFILES="$INI_DIR/rudi-catalog-profiles.ini"
ARG PORTAL_CONF="$INI_DIR/rudi-catalog-portal.ini"

# Specific configuration for Manager
ARG MANAGER_DB_PATH="/data/db/rudi_mngr.db"

# Sets different flags such as debug level or cookie security. Set to production | staging | development
ARG ENV="production"

# Tag for the container, usually the RUDI node version
ARG TAG="OCI-2.5.0"
# Base64 encoded <usr>:<hashedPwd> pair. You may use /api/open/hash-credentials to correctly hash the password and encode the pair
ARG SU="bm9kZSBhZG1pbjpUYlNDY1QzajN0eDZHZzdQdk10c0VGUDBEREw4TlFqRngxR0Z3MXVWbE5yTktudUFQTEp0Y1RBOFBkSklZS3dXRmpTU1lINHBHaVNVNXJsVHBBVGEyLTB0ZzItM1hBQWFrUmlUREtLTzNoR3cwMFVENmFzVXJZcFdQSW9IbXc="


# Declaring dockerfile input arguments as environment variables for later use
ENV NODE_PUBLIC_URL="$NODE_PUBLIC_URL "      \
    CATALOG_PUBLIC_URL="$CATALOG_PUBLIC_URL" \
    STORAGE_PUBLIC_URL="$STORAGE_PUBLIC_URL" \
    MANAGER_PUBLIC_URL="$MANAGER_PUBLIC_URL" \
    CATALOG_CONF="$CATALOG_CONF"             \
    STORAGE_CONF="$STORAGE_CONF"             \
    MANAGER_CONF="$MANAGER_CONF"             \
    PORTAL_CONF="$PORTAL_CONF"               \
    CATALOG_PROFILES="$CATALOG_PROFILES"     \
    MANAGER_DB_PATH="$MANAGER_DB_PATH"       \
    DOCKER_USR="$DOCKER_USR"                 \
    NODE_ENV="$ENV"                          \
    ENV="$ENV"                               \
    TAG="$TAG"                               \
    SU="$SU"

RUN mkdir -p "$SSH_DIR" "$INI_DIR"

COPY "$SRC_DIR" ./install/* ./env/* "$WK_DIR"/
COPY ./ssh/* "$SSH_DIR"/
COPY ./ini/* "$INI_DIR"/

EXPOSE 3030 3031 3033

RUN export PATH="$(npm get prefix):$PATH"            && \
    npm config set loglevel error                    && \
    npm i -g npm@latest                              && \
    for module in catalog storage manager crypto; do    \
        echo "Installing NodeJS app: rudi-$module";     \
        cd "$WK_DIR/rudi-$module" && npm i;             \
    done                                             && \
    cd "$WK_DIR"                                     && \
    echo "$SSH_DIR:" && ls -la "$SSH_DIR"            && \
    echo "$INI_DIR:" && ls -la "$INI_DIR"            && \
    echo "$WK_DIR:"  && ls -la "$WK_DIR"

CMD ./oci-startup.sh