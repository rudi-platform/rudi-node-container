FROM mongo:7.0.7

RUN apt-get update && apt-get install -y curl                    && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -    && \
    apt-get install -y netcat nodejs keychain                    && \
    apt-get clean                                                && \
    rm -rf /var/lib/apt/lists/*

# Folder that contains the source of every rudi-node module
ARG SRC_DIR="./src"

# Public URL of the container (used for the metadata connector URL)
ARG public_url="https://rudinode.org"

# Tag for the container, usually the RUDI node version
ARG tag="OCI-00-2.4.0"

# Declaring dockerfile input arguments as environment variables for later use
ENV PUBLIC_URL=$public_url                  \
    TAG=$tag

ENV WK_DIR="/app/rudi-node"                 \
    SSH_DIR="/.ssh"                         \
    NODE_ENV="production"

ENV ENV_DIR="$WK_DIR/env"                   \
    ENV_INIT_SH="$WK_DIR/env/_env-init.sh"

WORKDIR "$WK_DIR"
RUN mkdir -p "$ENV_DIR" "$SSH_DIR"

COPY "$SRC_DIR" ./install/* "$WK_DIR"/
COPY ./env/* "$ENV_DIR"/
COPY ./ssh/* "$SSH_DIR"/

EXPOSE 3030 3040 3050 3060

RUN chmod 100 "$ENV_DIR"                                     && \
    export PATH="$(npm get prefix):$PATH"                    && \
    npm config set loglevel error                            && \
    npm i -g npm@latest                                      && \
    for module in catalog storage manager console crypto; do    \
        echo "Installing NodeJS app: rudi-$module";             \
        cd "$WK_DIR/rudi-$module" && npm i;                     \
    done                                                     && \
    chmod 100 "$ENV_DIR"                                     && \
    echo "wk_dir=$(pwd); content:"                           && \
    ls -la "$WK_DIR"

CMD ./oci-startup.sh