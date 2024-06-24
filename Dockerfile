FROM mongo:7.0.7

RUN apt-get update && apt-get install -y curl &&                    \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - &&    \
    apt-get install -y nodejs netcat rsync keychain &&              \
    apt-get clean &&                                                \
    rm -rf /var/lib/apt/lists/*

ENV WK_DIR="/app/rudi-node"                 \
    SSH_DIR="/.ssh"             
ENV ENV_DIR="$WK_DIR/env"                   \
    env_init_sh="$WK_DIR/env/_env-init.sh"   

WORKDIR "$WK_DIR"

RUN mkdir -p "$ENV_DIR" "$SSH_DIR" && ls -la "$WK_DIR"

COPY ./src/ ./install/* "$WK_DIR"/
COPY ./env/* "$ENV_DIR"/
COPY ./ssh/* "$SSH_DIR"/

RUN ./oci-setup.sh &&   \
    rm ./oci-setup.sh

EXPOSE 3000-3003
CMD ls -la ./oci-startup.sh && ./oci-startup.sh