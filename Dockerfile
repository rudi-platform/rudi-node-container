FROM mongo:7.0.7

# Additional dependecies
RUN apt-get update && apt-get install -y curl                    && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -    && \
    apt-get install -y                                              \
        netcat                                                      \
        nodejs                                                      \
        keychain                                                 && \
    apt-get clean                                                && \
    rm -rf /var/lib/apt/lists/*


# # User
# ARG DOCKER_USER=default_user
# RUN groupadd -g 6000 "$DOCKER_USER"                           && \
#     useradd -ms /bin/bash -u 6001 -g "$DOCKER_USER" "$DOCKER_USER"
# USER $DOCKER_USER

# Folder that contains the source of every rudi-node module
ARG SRC_DIR="./src"

# Public URL of the container (used for the metadata connector URL)
ARG node_public_url="https://rudinode.org"
ARG catalog_public_url="http://localhost:3030"
ARG storage_public_url="http://localhost:3031"

# Tag for the container, usually the RUDI node version
ARG tag="OCI-2.5.0"
# Base64 encoded <usr>:<hashedPwd> pair. You may use /api/open/hash-credentials to correctly hash the password and encode the pair
ARG su="bm9kZSBhZG1pbjpUYlNDY1QzajN0eDZHZzdQdk10c0VGUDBEREw4TlFqRngxR0Z3MXVWbE5yTktudUFQTEp0Y1RBOFBkSklZS3dXRmpTU1lINHBHaVNVNXJsVHBBVGEyLTB0ZzItM1hBQWFrUmlUREtLTzNoR3cwMFVENmFzVXJZcFdQSW9IbXc="

# Declaring dockerfile input arguments as environment variables for later use
ENV node_public_url=$node_public_url        \
    catalog_public_url=$catalog_public_url  \
    storage_public_url=$storage_public_url  \
    DOCKER_USER=$DOCKER_USER                  \
    su=$su                                  \
    tag=$tag

ENV WK_DIR="/app/rudi-node"                 \
    SSH_DIR="/.ssh"                         \
    NODE_ENV="production"

ENV ENV_DIR="$WK_DIR/env"                   \
    ENV_INIT_SH="$WK_DIR/env/env-init.sh"   \
    INI_DIR="$WK_DIR/ini"

WORKDIR "$WK_DIR"
RUN mkdir -p "$ENV_DIR" "$SSH_DIR" "$INI_DIR"

COPY "$SRC_DIR" ./install/* "$WK_DIR"/
COPY ./ssh/* "$SSH_DIR"/
COPY ./ini/* "$INI_DIR"/

EXPOSE 3030 3031 3033

RUN chmod 100 "$ENV_DIR"                                     && \
    export PATH="$(npm get prefix):$PATH"                    && \
    npm config set loglevel error                            && \
    npm i -g npm@latest                                      && \
    for module in catalog storage manager crypto; do            \
        echo "Installing NodeJS app: rudi-$module";             \
        cd "$WK_DIR/rudi-$module" && npm i;                     \
    done                                                     && \
    echo "wk_dir=$(pwd); content:"                           && \
    ls -la "$WK_DIR"

CMD ./oci-startup.sh