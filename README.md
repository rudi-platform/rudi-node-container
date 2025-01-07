_This file explains how to pull and run a RUDI producer node container.
It also explains the different options that can be set.
Eventually, a procedure to build your own image is detailed._

# 1. Basic use: pull the image and run your own RUDI producer node

## 1A. Prerequisites

### Podman

To run the following scripts you should have a podman instance running.

If you need to install podman on MacOS, you may use homebrew for this:

```sh
# Install podman
brew install podman
# Init podman
podman machine init
# Launch podman machine (Linux VM)
podman machine start
```

Check podman installation page for other OS:
https://podman.io/docs/installation

### Docker

You can alternatively replace or even alias every `podman`command with `docker` if you're used to Docker: it works exactly the same (`alias podman=docker`).

### (Optionally) specify these variables:

If you want to run the container locally, and need the data to persist between each run, you will have to run it in a folder where a 'data' subfolder will be created.

```sh
# This is where the container will run. A `data` folder will be created for the container data to be remanent even if you stopped the container
INSTALL_DIR="$HOME/rudinode"

# This is the way the RUDI node Docker image would be named on this computer
LOCAL_IMG_NAME="rudinode-local"

# This is the name we want for the running RUDI node Docker container
CNTNR_NAME="rudinode"
```

## 1B. Launch this script (or copy-paste the content)

The following script will pull the container image from aqmo gitlab repo and run it.
This command lets the logs be displayed by not using the 'detach' (-d) option.
Beware: closing the terminal will close the container.
To exit, press Ctrl+C

```sh
./0-run-container.sh
```

Here is the content of the script, in case you want to execute only a part of the steps

```sh

# A. Pulling the image
#    Two images are currenly available: either "linux/amd64" for Linux-based PC
#    (should work on Windows too) or "linux/arm64" for MacOS.

# This is aqmo gitlab container repo
REGISTRY_IMG=registry.aqmo.org/public-rudi/public-packages/rudinode

# Here you can specify any name you want
LOCAL_IMG_NAME="rudinode-local"

# Fetch the image
podman pull "$REGISTRY_IMG"

# Give the image your prefered name
podman tag "$REGISTRY_IMG" "$LOCAL_IMG_NAME" && podman rmi "$REGISTRY_IMG"

# List the images
podman images

# B. Running the image
#    To run the container with a remanent volume, only `/data` folder should be mounted as a volume.

# Give the running container a name of your choice
CNTNR_NAME="rudinode"
# Stop the running instance in case it hadn't been stopped
podman stop "$CNTNR_NAME" 2>/dev/null
podman rm "$CNTNR_NAME" 2>/dev/null

# This is the install folder, you can set your own.
INSTALL_DIR="$HOME/rudinode"
mkdir -p "$INSTALL_DIR/data" && cd "$INSTALL_DIR"

# The following variable is the hashed super user credentials that corresponds to
#     usr: 'rudinode admin'
#     pwd: 'manager admin password!'
# - If you don't set the SU variable the first time the container is run, credentials wil be
#   randomly generated and displayed in the logs.
# - You normally only need to set it once, but if you set it in the run command next time, the
#   previous super user credentials get overwritten.
SU="cnVkaW5vZGUgYWRtaW46R3dvRDFiTmt5N1F1ZjNrbG1NZVk3NUhnVFdtUDZsZFpzU0ZJLWJDY1NMVWI2MldKOTZkMlJRVDZlMTFUd0E0eGNzTDljSHVNSnFaSkh4eW1SZE1iemRhMUM5WU8yU3Q2QVJoMmhlZFN1UmpZWW5PcXZpbDFEWDJ4cDJqZTZ3"

podman run --rm                         \
    --name "$CNTNR_NAME"                \
    --volume "${INSTALL_DIR}/data":/data  \
    --publish 3030:3030                 \
    --publish 3031:3031                 \
    --publish 3032:3032                 \
    -e SU=$SU                           \
    "$LOCAL_IMG_NAME"

```

This is where the `./0-run-conainer.sh` script stops.
Now let's see more commands.

## 1C. Test the running container

```sh
echo "Checking the running images"
podman ps

# This should display the word "test"
TEST=$(curl -s http://localhost:3032/manager/api/open/test) && echo $TEST

```

Or check this URL in your browser:

http://localhost:3032/manager/api/open/test

## 1D. Log in to the RUDI node

You may open a web browser and type the following URL to enter the RUDI node:

http://localhost:3032

Here are the default credentials you'll need to log in if you set it as stated above:

```js
usr: 'rudinode admin'
pwd: 'manager admin password!'
```

Start with creating an organization and a contact (avoid using personal data as a good practice).

Create your own metadata.

You can possibly create a new user that you'll reuse later.

## 1E. Stop the container

_Note: in the following commands, the `"${VAR:-something}` means use the variable `$VAR`, but if you don't find it use the default value `something`. You may use `"$VAR"`_

```sh
echo "Stopping the '${CNTNR_NAME:-rudinode}' container"
podman stop "${CNTNR_NAME:-rudinode}"
```

## 1F. Second run

Next time you want to run the container in the background (without seeing the logs displayed in you terminal) you can just run the following command:

```sh
podman run --rm -d --name "${CNTNR_NAME:-rudinode}" --volume "$INSTALL_DIR/data":/data --publish 3030:3030 --publish 3031:3031 --publish 3032:3032 ${LOCAL_IMG_NAME:-"rudinode-local"}
```

Or with the logs (= without the "detach" `-d` option)

```sh
podman run --rm --name "${CNTNR_NAME:-rudinode}" --volume "$INSTALL_DIR/data":/data --publish 3030:3030 --publish 3031:3031 --publish 3032:3032 ${LOCAL_IMG_NAME:-"rudinode-local"}
```

You can alternatively run the container and access the inside through a terminal launched within:

```sh
# You may have to stop the running container first
podman stop $CNTNR_NAME

# Run it with the terminal opened
podman run -it --rm --name "${CNTNR_NAME:-rudinode}" --volume "$INSTALL_DIR/data":/data --publish 3030:3030 --publish 3031:3031 --publish 3032:3032 --user root -t ${LOCAL_IMG_NAME:-"rudinode-local"} '/bin/sh' -l

# Once in the container, you may run any shell command:
ls -laH

# To leave and close the container:
exit
```

## 1G. Custom SuperUser

You'll certainly want to define a custom user password.
For this you'll need to provide a base64url encoded usr:hashed_pwd pair.

For this, you can use the RUDI Manager API to hash your usr+pwd pair.

```sh
# Redefine the super user name
SU_USR="RudiNodeAdmin"

# Redefine the super user password
SU_PWD="bed12345-2ec2-4713-98c3-6bcb1c74f37e"

# Hash the credentials with the running instance of your RUDI node
SU_CREDS=$(curl --json "{\"usr\": \"$SU_USR\", \"pwd\":\"$SU_PWD\"}" http://localhost:3032/manager/api/open/hash-credentials)

# This gives a base64 encoded "usr:hashed_pwd" string
echo $SU_CREDS
```

You can then use the environment variable "SU" to overwrite the Admin credentials in the RUDI Manager next time
you run the container. This only needs to be done once obviously.

```sh
podman stop $CNTNR_NAME

podman run --rm -d -e SU="$SU_CREDS" --name "${CNTNR_NAME:-rudinode}" --volume "$INSTALL_DIR/data":/data --publish 3030:3030 --publish 3031:3031 --publish 3032:3032 ${LOCAL_IMG_NAME:-"rudinode-local"}
```

# 2. Building your own RUDI node container

Scripts have been written to help you with building your own container, you may use them (maybe pull this git repo) or take what you need from them.

## 2A. Fetching the sources

Two configurations are offered:

- default is `.git-conf-rudip.sh` to fetch the sources from https://github.com/rudi-platform that is
  accessible to anyone
- alternatively, `.git-conf-aqmo.sh` can be used for development

```sh
export LOCAL_CONF='.git-conf-rudip.sh' # or '.git-conf-aqmo.sh' if you have access to aqmo gitlab
./1-pull-rudi-node-gits.sh
```

## 2B. Building the OCI/Docker image

The name for the docker image is set to 'rudinode-dc', but can be what
you need. The network is needed to fetch the source. This step can
take some time, go take any hot beverage you like.

```sh
export IMG_NAME="rudinode"
export DOCKER_COMPOSE_CONF="docker-compose-multip.yml"
./2-build-image.sh
```

## 2C. Running the container

```sh
# launch -- you may remove the `-d` (=detach) option to directly see the logs
podman-compose -f "${DOCKER_COMPOSE_CONF:-'docker-compose-multip.yml'}" up -d

# stop
podman-compose -f "${DOCKER_COMPOSE_CONF:-'docker-compose-multip.yml'}" down
```

## 2D. Log in to the RUDI node

Go to the following URL and login with the Super User password you have set:

http://localhost:3032/manager
