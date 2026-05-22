test -r ./env/version && source ./env/version

IMG_NAME="rudinode"

PLATFORMS=("linux/amd64" "linux/arm64")

VERSIONED_NAME="${IMG_NAME}-${VERSION}"
LATEST="${IMG_NAME}:latest"
