#/bin/bash

PROJECT_DIR="$(
  cd "$(dirname "$0")"/..
  pwd
)"

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
  # Deploy the services for the applications
  kubectl -n $env apply -f $PROJECT_DIR/k8s/service.yaml

  # Deploy the local rollout configuration
  export ENV=$env
  envsubst <$PROJECT_DIR/k8s/rollout-local.yaml | kubectl -n $env apply -f

  # Update the images
  kubectl argo rollouts set image searchapi searchapi="searchapi:latest" -n $env
  kubectl argo rollouts set image web web="web:latest" -n $env
  kubectl argo rollouts set image statsapi statsapi="statsapi:latest" -n $env

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
