test -r ./rudinode-version && source ./rudinode-version

IMG_NAME="rudinode"

PLATFORMS="linux/amd64 linux/arm64"

VERSIONED_NAME="${IMG_NAME}-${VERSION}"
LATEST="${IMG_NAME}:latest"
