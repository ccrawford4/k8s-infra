#/bin/bash

PROJECT_DIR="$(
  cd "$(dirname "$0")"/..
  pwd
)"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <docker_username>"
  exit 1
fi

DOCKER_USERNAME="$1"

# Create namespaces if they do not exist already
for n in qa uat prod ingress-nginx argo-rollouts; do
  kubectl get namespace $n || kubectl create namespace $n
done

# Install the Argo-Rollouts controller
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Deploy the ingress controller
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx

# Install Applications on each namespace
for env in qa uat prod; do
  cd $PROJECT_DIR

  # Deploy the services for the applications
  kubectl -n $env apply -f k8s/service.yaml

  # Deploy the local rollout configuration if the rollout has not been applied yet
  export ENV=$env
  export DOCKER_USERNAME=$DOCKER_USERNAME
  kubectl get rollout -n $env | envsubst <k8s/rollout-local.yaml | kubectl -n $env apply -f -

  # Update the images
  kubectl argo rollouts set image searchapi searchapi="$DOCKER_USERNAME/searchapi:latest" -n $env
  kubectl argo rollouts set image web web="$DOCKER_USERNAME/web:latest" -n $env
  kubectl argo rollouts set image statsapi statsapi="$DOCKER_USERNAME/statsapi:latest" -n $env

  # Upgrade the mysql chart or install it if it does not exist
  cd $PROJECT_DIR/charts/mysql
  helm -n $env upgrade --install \
    --set database=$env \
    --set username=admin \
    --set password=password \
    --set root_password=rootpassword \
    mysql .

  # Upgrade the redis chart or install it if it does not exist
  cd $PROJECT_DIR/charts/redis
  helm -n $env upgrade --install \
    --set password=password \
    redis .
done

# Deploy the ingress
kubectl apply -f $PROJECT_DIR/k8s/ingress-local.yaml
