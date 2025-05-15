#/bin/bash

# Downloads all the source codes and builds the docker images
PROJECT_DIR="$(
  cd "$(dirname "$0")"/..
  pwd
)"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <docker_username>"
  exit 1
fi

DOCKER_USERNAME="$1"

# Login to docker hub
docker login

# Declare a map to configure the repos and their associated docker image names
declare -A repo_map
repo_map["search-app"]="web"
repo_map["search"]="searchapi"
repo_map["stats"]="statsapi"

# Download each source code, build the docker image, and tag it
for repo in search-app search stats; do
  git clone "https://github.com/ccrawford4/$repo"
  cd "$PROJECT_DIR/$repo"
  image_name="$DOCKER_USERNAME/${repo_map[$repo]}"
  echo "image_name: $image_name"
  docker build -t "$image_name" .
  docker push "$image_name:latest"
done
