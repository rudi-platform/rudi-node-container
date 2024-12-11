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
OCI_NAME="my-rudinode"
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
curl -v http://localhost:3032/api/open/test

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
podman stop $OCI_NAME
```

## 1F. Second run

Next time you want to run the container without seeing the logs, you can just run the following command:

```sh
podman run --rm -d --name "${OCI_NAME:-"my-rudinode"}" --volume ./data:/data --publish 3030:3030 --publish 3031:3031 --publish 3032:3032 ${LOCAL_IMG_NAME:-"rudinode-local"}
# Or with the logs
podman run --rm --name "${OCI_NAME:-"my-rudinode"}" --volume ./data:/data --publish 3030:3030 --publish 3031:3031 --publish 3032:3032 ${LOCAL_IMG_NAME:-"rudinode-local"}
```

You can alternatively run the container and open a terminal within:

```sh
# You may have to stop the running container first
podman stop $OCI_NAME

# Run it with the terminal opened
podman run -it --rm --name "${OCI_NAME:-"my-rudinode"}" --user root -t ${LOCAL_IMG_NAME:-"rudinode-local"} '/bin/ash' -l

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
SU_CREDS=$(curl --json "{\"usr\": \"$SU_USR\", \"pwd\":\"$SU_PWD\"}" http://localhost:3032/api/open/hash-credentials)
# This gives a base64 encoded "usr:hashed_pwd" string
echo $SU_CREDS
```

You may then use the environment variable "SU" to overwrite the Admin credentials in the RUDI Manager next time
you run the container. This only needs to be done once obviously.

```sh
podman run --rm -d -e SU="$SU_CREDS" --name "${OCI_NAME:-rudinode}" --volume ./data:/data --publish 3030:3030 --publish 3031:3031 --publish 3032:3032 ${LOCAL_IMG_NAME:-"rudinode-local"}
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

http://localhost:3032

## ------------------------------vvv--- TO BE CLEANED ---vvv---

```sh
IMG_PLATFORM=${IMG_PLATFORM:-"amd64"} # or arm64
DST_PLATFORM=linux/$IMG_PLATFORM
USR_IMG_NAME=rudinode
podman build --platform $DST_PLATFORM --net host -f Dockerfile.build -t $USR_IMG_NAME .
```

### Test the OCI/Docker image

If you want to inspect you container, you can get inside :

```sh
podman run -it --rm --net host --name rudinode-dc --user root -t rudinode-dc '/bin/ash' -l
```

In this command, you become root, and call directly a shell. To continue the execution, simply run :

```sh
$ su -l rudiadm /app/rudi-node/oci-alpine-startup.sh &
```

To run the container with a remanent volume, only _/data_ is needed :

```sh
podman run -d --rm --net host --name rudinode-dc_t --volume ./data:/data rudinode-dc
```

This way, you can investigate any problem you may face.

**Warning**

The files and directories in the volume './data' has to comply with user access rights as configure
for the container and shifted according to your configuration.
For example, in rootless mode, here is my result :

```sh
$ podman info | yq .host.idMappings
gidmap:
  - container_id: 0
    host_id: 1000
    size: 1
  - container_id: 1
    host_id: 100000
    size: 65536
uidmap:
  - container_id: 0
    host_id: 1000
    size: 1
  - container_id: 1
    host_id: 100000
    size: 65536
```

This output tells that in my case the _root_ user will have the id
_1000_, and other users will have an id shifted by _100000_. This
configuration is set in the **'/etc/subuid'** and **'/etc/subgid'**
files. So, if you use files in your containers that are not _root_, in
our case, the user _rudiadm_ has an id _5000_ and the group _rudi_ the same number.
Outside the container, they must have the id/group numbers _105000_/_105000_.

```sh
$ ls -alF data/
total 12
drwxrwxr-x 3 105000 105000 4096 nov.  13 09:43 ./
drwxrwxr-x 9 lmorin lmorin 4096 nov.  13 11:14 ../
drwxr-x--- 4 105000 105000 4096 nov.  11 18:15 media/
```

How to proceed ? It your are a sudo user, easy :

```sh
$ mkdir ./data
$ sudo chown 105001:105001 ./data
```

If you are not, mount the volume with any container runing a shell, and set it inside.

### Run the container with podman-compose

You may need to install _podman-compose_ as it is not necessarily installed together with Podman.
Several types of deployments are possible :

- A single container attached to the host network with _docker-compose-basic.yml_
- A container by application attached to the host network with _docker-compose-host.yml_
- A container by application with a local network with _docker-compose.yml_ (default)

You can build the necessary images with the command

```sh
podman-compose build
```

Remainder:

- To launch a deployment : `podman-compose  -f docker-compose-basic.yml up -d`
- To stop a deployment : `podman-compose  -f docker-compose-basic.yml down`

# In short: execution example

```sh
#!/bin/bash

# ==================================================================================================
# This script runs the container image with podman
# ==================================================================================================

# Argument 1 is the destination platform for the container image.
#   Values: amd64 (Linux) | arm64 (MacOS)
IMG_PLATFORM=amd64

# Give your local container a name
POD_NAME="tiare.rudi-node"

# --------------------------------------------------------------------------------------------------
# Setting environment variables for the container
# --------------------------------------------------------------------------------------------------

# Set the encrypted credentials for the Super User
#   Note: you can hash a password with the latest version of the node manager:
#       POST https://admin-rudi.aqmo.org/prodmanager/api/open/hash-password
#
#          with payload: { "usr":<pmAdminUsr>, "pwd":"<pmAdminPwd>" }
#
#       This will give you a base64 encoded usr:hashed_password pair that is safe to put on a server
#       and the kind that is expected here
SU_CREDS=UE0gQWRtaW46QTUyMllEV2ZpWDV2VkpManlTNU5DTkVSTS16cnpxdlotLTl6eVhJYzVJSVpXVkVITi02aThnTkZ1aUticmxHS1pUSV82SnNPYzh2bC11SlFRTGJRZnE1ZnVQLVVReUFiMWpXV1c3N3RWeFRoWVlodlU5azhDeDNhV1VWempR

# Public URL for the node
#   Note: if your modules have different URLs, you might want to alternatively set the 3 following URLs
#       CATALOG_PUBLIC_URL=https://tiare.rudi.univ-rennes.fr/catalog
#       STORAGE_PUBLIC_URL=https://tiare.rudi.univ-rennes.fr/media
#       MANAGER_PUBLIC_URL=https://tiare.rudi.univ-rennes.fr/manager
NODE_PUBLIC_URL=https://tiare.rudi.univ-rennes.fr

# Set the environment variable: production | staging | development
#   Note: 'staging' makes it possible to communicate with a http only node
#   For a local or https node, please use 'production'
RUDI_ENV=staging

# Set a tag for your node
TAG=TIARE_2.5.0-A


# --------------------------------------------------------------------------------------------------
# Setting the paths of configuration files
# --------------------------------------------------------------------------------------------------

# In the example bellow, the configuration files have reference to the same folder, which we set
# here for practical reasons
DATA_DIR=/home/data

# You may optionally need to set the paths for the RUDI node modules configuration files, that offer
# a deeper configuration level
#
#   Note: CLI options have priority over ENV variables that have themselves priority over config
#         files
#   Note2: correspondance with legacy projects module names ("RUDI Console" is obsolete)
#       - Catalog: previously "RUDI API"
#       - Storage: previously "RUDI Media"
#       - Manager: previously "Prodmanager" or even "RUDI console proxy"
CATALOG_CONF="$DATA_DIR/rudiapi/conf_custom.ini"
STORAGE_CONF="$DATA_DIR/rudimedia/rudi_media_custom.ini"
MANAGER_CONF="$DATA_DIR/rudimanager/rudi_console_proxy_custom.ini"

# In this configuration file are declared the public keys to access the Catalog API
CATALOG_PROFILES="$DATA_DIR/rudiapi/profiles_custom.ini"

# In this configuration file are declared the URL, user and password to access the RUDI Portal
PORTAL_CONF="$DATA_DIR/rudiapi/portal_login.ini"

# This is the URI towards a local MongoDB instance. Here is a default value that uses the MongoDB
# instance that is onboard the container
CATALOG_DB_URI="mongodb://localhost:27017/rudiapi"

# This is the path towards the SQLite DB of the Manager users
MANAGER_DB_PATH="$DATA_DIR/manager/db/rudy_manager.db"


echo "----- Deleting the previous container to avoid accumulation"
podman stop "${POD_NAME}" 2>/dev/null
podman rm "${POD_NAME}" 2>/dev/null

echo "----- Creating & running the new container"
podman pull "registry.aqmo.org/public-rudi/public-packages/rudi-node-${IMG_PLATFORM}"

# Create a new container and binding the following folders
#   - .ssh as /keys for the secrets (:Z opt = private, :ro = read-only)
#   - data as /data/dump to restore previous DB at startup
podman run -it                                                  \
    --rm                                                        \
    --name "$POD_NAME"                                          \
    --log-level debug                                           \
                                                                \
    -e NODE_PUBLIC_URL="$NODE_PUBLIC_URL"                       \
    -e SU="$SU_CREDS"                                           \
    -e ENV=$RUDI_ENV                                            \
    -e TAG="$TAG"                                               \
                                                                \
    --publish 3000:3000                                         \
    --publish 3040:3040                                         \
    --publish 3010:3010                                         \
                                                                \
    --volume "$HOME/tiare/data/":"$DATA_DIR":Z                  \
    --volume "$HOME/tiare/db":/data/db:Z                        \
    --volume "$HOME/tiare/data/logs/mongodb":/tmp/logs/mongo:Z  \
                                                                \
    -e CATALOG_CONF="$CATALOG_CONF"                             \
    -e STORAGE_CONF="$STORAGE_CONF"                             \
    -e MANAGER_CONF="$MANAGER_CONF"                             \
                                                                \
    -e CATALOG_PROFILES="$CATALOG_PROFILES"                     \
    -e PORTAL_CONF="$PORTAL_CONF"                               \
    -e CATALOG_DB_URI="$CATALOG_DB_URI"                         \
                                                                \
    -e MANAGER_DB_PATH="$DATA_DIR/manager/db/rudy_manager.db"   \
                                                                \
    rudi-node-$IMG_PLATFORM
```

## Build the container yourself: prerequisites

### Access to `aqmo` gitlab

The environment variable `$aqmo_git_rudi_container` must be set with a valid aqmo gitlab token that can be used to pull the needed repositories, the URLs of which are created from the partial information given in the file `./git_sources.json`.
the token should also make it possible to push the final Docker image.

## Build the container yourself: launch scripts

This part explains how to create your own container with the code provided in this repo.
5 scripts were written to facilitate this.

### Fetch the sources

```sh
./1-pull-rudi-node-gits.sh
```

### Build the OCI/Docker image

The name for the docker image can be set as an argument of this scritpt. It defaults to 'rudi-container'

```sh
./2-build-image.sh
```

### Launch the OCI/Docker container

This script gives an example of a launching

```sh
./3-run-container.sh
```

## Parameters to run the container with

### Container arguments (and container environment variables)

| env var            | description                                                           | optional | example value                                                       | defaults                                                   | note                                                                                                                                                                                      |
| :----------------- | :-------------------------------------------------------------------- | :------- | ------------------------------------------------------------------- | ---------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ENV                | Sets the RUDI node ENV variable                                       | yes      | -e ENV=production                                                   | production                                                 | `development`: the frontend needs to be launched as a separate server<br>`staging`: unsafe cookies, http ok<br>`production`: safe cookies, CORS, https only                               |
| TAG                | Sets the RUDI node TAG that is displayed in the upper right of the UI | yes      | -e TAG=RUDI-OCI-2.5.0-A                                             | RUDI-OCI-2.5.0                                             |                                                                                                                                                                                           |
| SU                 | Sets the username and password for the super user.                    | yes\*    | -e SU=PHVzZXI+OjxoYXNoZWRfcHdkPg==                                  | login = '`node admin`' / pwd = '`manager admin password!`' | \* Testing purpose only, please change these credentials! Username and hashed password must be base 64 encoded as `<usr>:<hashed pwd>`. Seel bellow the **"Hash credentials"** paragraph. |
| NODE_PUBLIC_URL    | Public URL for the node                                               | yes\*    | -e NODE_PUBLIC_URL=https://tiare.rudi.univ-rennes.fr                | localhost                                                  | \* Testing purpose only. In a production environment, this should be set.                                                                                                                 |
| CATALOG_PUBLIC_URL | Public URL for the RUDI node Catalog module                           | yes      | -e CATALOG_PUBLIC_URL=https://tiare.rudi.univ-rennes.fr             |                                                            | Useless in a configuration where the 3 modules are behind the same URI                                                                                                                    |
| STORAGE_PUBLIC_URL | Public URL for the RUDI node Storage module                           | yes      | -e STORAGE_PUBLIC_URL=https://tiare.rudi.univ-rennes.fr/media       |                                                            | Useless in a configuration where the 3 modules are behind the same URI                                                                                                                    |
| MANAGER_PUBLIC_URL | Public URL for the RUDI node Manager module                           | yes      | -e MANAGER_PUBLIC_URL=https://tiare.rudi.univ-rennes.fr/prodmanager |                                                            | Useless in a configuration where the 3 modules are behind the same URI                                                                                                                    |
| CATALOG_CONF       | Path to the configuration file of the RUDI node Catalog module        | yes      | -e CATALOG_CONF"./ini/rudi-catalog-conf.in"                         | ./ini/rudi-catalog-conf.ini                                |                                                                                                                                                                                           |
| STORAGE_CONF       | Path to the configuration file of the RUDI node Storage module        | yes      | -e STORAGE_CONF="./ini/rudi-storage-conf.ini"                       | ./ini/rudi-storage-conf.ini                                |                                                                                                                                                                                           |
| MANAGER_CONF       | Path to the configuration file of the RUDI node Manager module        | yes      | -e MANAGER_CONF="./ini/rudi-manager-conf.ini"                       | ./ini/rudi-manager-conf.ini                                |                                                                                                                                                                                           |
| CATALOG_DB_URI     | URI towards a MongoDB microservice                                    | yes      | -e CATALOG_DB_URI="mongodb://localhost:27017/rudi_api"              | mongodb://localhost:27017/rudi_api                         | Useless if you're using the MongoDB that is onboard the container                                                                                                                         |
| CATALOG_PROFILES   | Path to the file where public keys for the Catalog are declared       | yes\*    | -e CATALOG_PROFILES="./ini/rudi-catalog-profiles.ini"               | ./ini/rudi-catalog-profiles.ini                            | \* You'll most likely want to declare a few keys if you need to access the Catalog API directly                                                                                           |
| PORTAL_CONF        | Path to the file where usr, pwd and URI to the portal are declared    | yes      | -e PORTAL_CONF="./ini/rudi-catalog-portal.ini"                      | ./ini/rudi-catalog-portal.ini                              |
| MANAGER_DB_PATH    | Path to the file where public keys for the Catalog are declared       | yes      | -e MANAGER_DB_PATH="/data/db/rudi_mngr.db"                          | /data/db/rudi_mngr.db                                      |

### Ports

- `-p 3030:3030` is the port to access the RUDI Catalog module (ex-API)
- `-p 3031:3031` is the port to access the RUDI Storage module (ex-Media)
- `-p 3033:3033` sets the default port to access the RUDI Manager module.

The UI of the RUDI node can be accessed by default at http://localhost:3033

### Volumes

Here is a list of volume you might want to bind mount to access data from the container:

- `-v "${HOME}/data/db":/data/db:Z`: location of the Catalog MongoDB database as well as the RUDI Manager SQLite user database
- `-v "${HOME}/data/dump":/data/dump:Z`: folder for dumping the RUDI Catalog MongoDB database
- `-v "${HOME}/data/media":/data/media:Z`: storage of the media files for the RUDI Storage module
- `-v "${HOME}/data/conf":$WK_DIR/conf:Z`: folder for setting custom configuration files for each RUDI module (Catalog, Storage or Manager)

## Testing the running container

### Basic API tests

- GET http://localhost:3033/api/open/test : answers "test"
- GET http://localhost:3033/api/open/hash : answers with the current git hash of the RUDI manager module
- GET http://localhost:3033/api/open/tag : answers with the current tag of the RUDI node

### Hash credentials

An API is provided to hash credentials.

- POST http://localhost:3033/api/open/hash-credentials: a JSON body must be provided with the request
  - either the password alone, in a JSON object with "pwd" key `{"pwd":"<my password>"}`. In such case, the answer is the hashed password
  - or the username + password pair `{"usr":"<my username>", "pwd":"<my password>"}`. In such case, the anwser is a base 64 encoded pair of `<username>:<hashed password>`
