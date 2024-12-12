This file explains how to pull and run a RUDI producer node container.
It also explains the different options that can be set.
Eventually, a procedure to build your own image is detailed.

# 1. Basic use: pull the image and run a RUDI producer node

## 1A. (Optionally) specify these variables:

```sh
# This is where the container will run. A `data` folder will be created for the container data to be
# be remanent even if you stopped the container
INSTALL_DIR="~/rudinode"

# This is the way the RUDI node Docker image would be named on this computer
LOCAL_IMG_NAME="rudinode-local"

# This is the name we want for the running RUDI node Docker container
CNTNR_NAME="my-rudinode"
```

## 1B. Launch this script (or copy-paste the content)

This will pull the container image from aqmo gitlab repo and run it.
This command lets the logs be displayed. Beware: closing the terminal should close the container.

```sh
./0-run-container.sh
```

## 1C. Test the running container

```sh
# Check the running images
podman ps

# This should display the word "test"
curl -v http://localhost:3032/manager/api/open/test

```

## 1D. Log to the RUDI node

You may open a web browser and type the following URL:

http://localhost:3032

Here are the default credentials you'll need to log in the first time:

```js
usr: `node admin`
pwd: `manager admin password!`
```

Start with creating an organization and a contact (avoid using personal data as a good practice).
You can possibly create a new user.

## 1E. Stop the container

```sh
podman stop $CNTNR_NAME
```

## 1F. Second run

Next time you want to run the container without seeing the logs, you can just run the following command:

```sh
podman run --rm -d --name "${CNTNR_NAME:-"my-rudinode"}" --volume ./data:/data --publish 3030:3030 --publish 3031:3031 --publish 3032:3032 ${LOCAL_IMG_NAME:-"rudinode-local"}
# Or with the logs
podman run --rm --name "${CNTNR_NAME:-"my-rudinode"}" --volume ./data:/data --publish 3030:3030 --publish 3031:3031 --publish 3032:3032 ${LOCAL_IMG_NAME:-"rudinode-local"}
```

You can alternatively run the container and open a terminal within:

```sh
# You may have to stop the running container first
podman stop $CNTNR_NAME

# Run it with the terminal opened
podman run -it --rm --name "${CNTNR_NAME:-"my-rudinode"}" --user root -t ${LOCAL_IMG_NAME:-"rudinode-local"} '/bin/ash' -l

# Once in the container, you may run msot shell commands:
ls -laH

# To leave and close the container:
exit
```

## 1G.Custom SuperUser

You'll certainly want to define a custom user password.
You can use the RUDI Manager API to hash your usr+pwd pair.

```sh
SU_USR="RudiNodeAdmin"
SU_PWD="bed12345-2ec2-4713-98c3-6bcb1c74f37e"
SU_CREDS=$(curl --json "{\"usr\": \"$SU_USR\", \"pwd\":\"$SU_PWD\"}" http://localhost:3032/manager/api/open/hash-credentials)
# This gives a base64 encoded "usr:hashed_pwd" string
echo $SU_CREDS
```

You may then use the environment variable "SU" to overwrite the Admin credentials in the RUDI Manager next time
you run the container. This only needs to be done once obviously.

```sh
podman run --rm -d -e SU="$SU_CREDS" --name "${CNTNR_NAME:-rudinode}" --volume ./data:/data --publish 3030:3030 --publish 3031:3031 --publish 3032:3032 ${LOCAL_IMG_NAME:-"rudinode-local"}
```

# 2. Building your own RUDI node container

Scripts have been written to help you with building your own container, you may use them or take
what you need from them.

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

## 2D. Log to the RUDI node

Go to the following URL and login with the Super User password you have set at

http://localhost:3032/manager
