#/bin/bash

# Downloads all the source codes and builds the docker images
PROJECT_DIR="$(
  cd "$(dirname "$0")"/..
  pwd
)"

# Download each source code, build the docker image, and tag it
for repo in search-app search stats; do
  git clone "https://github.com/ccrawford4/$repo"
  cd "$PROJECT_DIR/$repo"
  docker build -t $repo .
done
