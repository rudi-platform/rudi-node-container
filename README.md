# Containerization of the "RUDI Producer Node" modules.

## Prerequisites

### Environment variable $aqmo_git_rudi_container

The environment variable `$aqmo_git_rudi_container` must be set. Its value must be a valid aqmo gitlab token that can be used to pull the needed repositories, the URLs of which are created from the partial information given in the file `./git_sources.json`.
the token should also make it possible to push the final Docker image.

## Launch

```sh
# Fetch or update the sources, then build the Docker image with podman from the Dockerfile
# - Argument 1 is the name for the docker image that is produced and defaults to 'rudi-node:release'
./1-rudi-node-build.sh rudi-node:release
```
