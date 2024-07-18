# Containerization of the "RUDI Producer Node" modules.

# Prerequisites

## Access to `aqmo` gitlab

The environment variable `$aqmo_git_rudi_container` must be set with a valid aqmo gitlab token that can be used to pull the needed repositories, the URLs of which are created from the partial information given in the file `./git_sources.json`.
the token should also make it possible to push the final Docker image.

# Launch scripts

## Fetch the sources

```sh
./1-pull-rudi-node-gits.sh
```

## Build the OCI/Docker image

The name for the docker image can be set as an argument of this scritpt. It defaults to 'rudinode:release'

```sh
./2-build-image.sh
```

## Launch the OCI/Docker container

This script gives an example of a launching

```sh
./3-run-container.sh
```

# Parameters to run the container with

## Environment variables

| env var | description                                                                                                                                                                        | optional | example value                      | note                                                                                                        |
| :------ | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------- | ---------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| tag     | Sets the RUDI node tag that is displayed in the upper right of the UI                                                                                                              | yes      | -e tag=OCI-2.5.0-A                 |
| su      | Sets the username and password for the super user. Username and hashed password must be base 64 encoded as `<usr>:<hashed pwd>`. Seel bellow the **"Hash credentials"** paragraph. | yes      | -e su=PHVzZXI+OjxoYXNoZWRfcHdkPg== | If not set (e.g. for a test run), it defaults to login = '`node admin`' / pwd = '`manager admin password!`' |

## Ports

- `-p 3030:3030` is the port to access the RUDI Catalog module (ex-API)
- `-p 3031:3031` is the port to access the RUDI Storage module (ex-Media)
- `-p 3033:3033` sets the default port to access the RUDI Manager module.

The UI of the RUDI node can be accessed by default at http://localhost:3033

## Volumes

Here is a list of volume you might want to bind mount to access data from the container:

- `-v "${HOME}/data/db":/data/db:Z`: location of the Catalog MongoDB database as well as the RUDI Manager SQLite user database
- `-v "${HOME}/data/dump":/data/dump:Z`: folder for dumping the RUDI Catalog MongoDB database
- `-v "${HOME}/data/media":/data/media:Z`: storage of the media files for the RUDI Storage module
- `-v "${HOME}/data/conf":$WK_DIR/conf:Z`: folder to set custom configuration files for a RUDI module (Catalog, Storage or Manager)

# Testing the running container

### Basic API tests

- GET http://localhost:3033/api/open/test : answers "test"
- GET http://localhost:3033/api/open/test : answers with the current git hash of the RUDI manager module
- GET http://localhost:3033/api/open/tag : answers with the current tag of the RUDI node

### Hash credentials

An API is provided to hash credentials.

- POST http://localhost:3033/api/open/hash-credentials: a JSON body must be provided with the request
  - either the password alone, in a JSON object with "pwd" key `{"pwd":"<my password>"}`. In such case, the answer is the hashed password
  - or the username + password pair `{"usr":"<my username>", "pwd":"<my password>"}`. In such case, the anwser is a base 64 encoded pair of `<username>:<hashed password>`
