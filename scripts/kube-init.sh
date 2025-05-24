#/bin/bash

PROJECT_DIR="$(
  cd "$(dirname "$0")"/..
  pwd
)"

# Parse command line arguments
if [ $# -lt 1 ]; then
  error "error" "Docker username is required"
  usage
fi

DOCKER_USERNAME="$1"
shift

# Parse remaining arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  --datadog-api-key=*)
    DATADOG_API_KEY="${1#*=}"
    DATADOG_ENABLED=true
    shift
    ;;
  --help | -h)
    usage
    ;;
  *)
    warn "warning" "Unknown option: $1"
    shift
    ;;
  esac
done

# Validate Datadog configuration
if [[ "$DATADOG_ENABLED" == "true" ]]; then
  if [[ -z "$DATADOG_API_KEY" ]]; then
    error "error" "Datadog API key cannot be empty when Datadog is enabled"
    exit 1
  fi
  info "datadog" "Datadog monitoring will be configured"
fi

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

# Deploy Datadog if enabled
if [[ "$DATADOG_ENABLED" == "true" ]]; then
  info "datadog" "Setting up Datadog monitoring..."
  kubectl get namespace datadog || kubectl create namespace datadog

  helm repo add datadog https://helm.datadoghq.com
  helm install datadog-operator datadog/datadog-operator
  kubectl create secret generic datadog-secret --from-literal api-key=$DATADOG_API_KEY || echo "secret already exists"

  info "datadog" "Datadog monitoring setup completed"
else
  info "k8s" "Skipping Datadog setup (not enabled)"
fi

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

  # If datadog is enabled,
  if [[ "$DATADOG_ENABLED" == "true" ]]; then
    echo "Applying Datadog agent for $env environment..."
    cd "$PROJECT_DIR"
    echo "Creating Datadog agent config for $env environment..."
    kubectl -n $env apply -f k8s/datadog-agent.yaml
  fi
done

echo "Pausing for 5 seconds to allow the services to start... Do NOT Interrupt!"
sleep 5

# Deploy the ingress
kubectl apply -f $PROJECT_DIR/k8s/ingress-local.yaml
