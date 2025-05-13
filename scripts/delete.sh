#/bin/bash

PROJECT_DIR="$(
  cd "$(dirname "$0")"/..
  pwd
)"

# Download each source code, build the docker image, and tag it
for repo in search-app search stats; do
  cd $PROJECT_DIR
  rm -rf $repo
done
