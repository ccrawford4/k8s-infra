#!/bin/bash
MICROSERVICES=("web" "searchapi", "statsapi")
# AWS variables
AWS_PROFILE=default
AWS_REGION=us-east-1
PROJECT_DIR="$(
  cd "$(dirname "$0")"
  pwd
)"
export AWS_PROFILE AWS_REGION PROJECT_NAME PROJECT_DIR

# Default values
COMMAND=""
DOCKER_USERNAME=""
DATADOG_ENABLED=false
DATADOG_API_KEY=""

log() { echo -e "\e[30;47m ${1^^} \e[0m ${@:2}"; }          # $1 uppercase background white
info() { echo -e "\e[48;5;28m ${1^^} \e[0m ${@:2}"; }       # $1 uppercase background green
warn() { echo -e "\e[48;5;202m ${1^^} \e[0m ${@:2}" >&2; }  # $1 uppercase background orange
error() { echo -e "\e[48;5;196m ${1^^} \e[0m ${@:2}" >&2; } # $1 uppercase background red
# https://unix.stackexchange.com/a/22867
export -f log info warn error

# log $1 in underline then $@ then a newline
under() {
  local arg=$1
  shift
  echo -e "\033[0;4m${arg}\033[0m ${@}"
  echo
}

usage() {
  under usage 'call the Makefile directly: make dev
      or invoke this file directly: ./make.sh <command> [docker_username] [options]
      
      Commands:
        setup         Initialize terraform and ECR repositories
        build-all     Build all microservice containers
        kube-local    Initialize local Kubernetes cluster
        destroy-local Destroy local Kubernetes resources
        delete-all    Delete all resources
        tf-validate   Validate and format terraform files
        tf-apply      Plan and apply terraform changes
        kube-config   Setup kubectl config for EKS
        destroy       Full destroy: EKS + terraform + ECR
      
      Options:
        --datadog-api-key=<key>      Enable Datadog monitoring with API key
        --datadog-api-key-file=<path> Read Datadog API key from file
      
      Examples:
        ./make.sh kube-local myuser --datadog-api-key=abc123def456
        ./make.sh kube-local myuser --datadog-api-key-file=./secrets/datadog.key'
}

# Parse command line arguments
parse_args() {
  # Store the command (first argument) before parsing
  COMMAND="$1"
  shift

  # Store docker username if provided and not an option
  if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
    DOCKER_USERNAME="$1"
    shift
  fi

  # Parse remaining options
  while [[ $# -gt 0 ]]; do
    case $1 in
    --datadog-api-key=*)
      DATADOG_API_KEY="${1#*=}"
      DATADOG_ENABLED=true
      shift
      ;;
    --datadog-api-key-file=*)
      local key_file="${1#*=}"
      if [[ -f "$key_file" ]]; then
        DATADOG_API_KEY=$(cat "$key_file" | tr -d '\n\r')
        DATADOG_ENABLED=true
        info "datadog" "API key loaded from file: $key_file"
      else
        error "error" "Datadog API key file not found: $key_file"
        exit 1
      fi
      shift
      ;;
    --help | -h)
      usage
      exit 0
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
      error "error" "Datadog API key cannot be empty"
      exit 1
    fi
    if [[ ${#DATADOG_API_KEY} -lt 32 ]]; then
      warn "warning" "Datadog API key seems too short (expected 32+ characters)"
    fi
    info "datadog" "Datadog monitoring enabled"
  fi
}

setup() {
  # terraform init
  cd "$PROJECT_DIR/infra"
  terraform init
  cd "$PROJECT_DIR"
  bash scripts/ecr-create.sh "${MICROSERVICES[@]}"
}

build-all() {
  cd "$PROJECT_DIR"
  bash scripts/build.sh "$DOCKER_USERNAME"
}

kube-local() {
  cd "$PROJECT_DIR"
  if [[ "$DATADOG_ENABLED" == "true" ]]; then
    info "datadog" "Initializing Kubernetes with Datadog monitoring"
    bash scripts/kube-init.sh "$DOCKER_USERNAME" --datadog-api-key="$DATADOG_API_KEY"
  else
    info "k8s" "Initializing Kubernetes without monitoring"
    bash scripts/kube-init.sh "$DOCKER_USERNAME"
  fi
}

destroy-local() {
  cd "$PROJECT_DIR"
  bash scripts/kube-destroy.sh
}

delete-all() {
  cd "$PROJECT_DIR"
  bash scripts/delete.sh
}

# terraform validate
tf-validate() {
  cd "$PROJECT_DIR/infra"
  terraform fmt -recursive
  terraform validate
}

# terraform plan + terraform apply
tf-apply() {
  cd "$PROJECT_DIR/infra"
  terraform plan
  terraform apply -auto-approve
}

# setup kubectl config
kube-config() {
  cd "$PROJECT_DIR/infra"
  aws eks update-kubeconfig \
    --name $(terraform output -raw cluster_name) \
    --region $(terraform output -raw region)
}

# delete eks content + terraform destroy + delete ecr repository
destroy() {
  # delete eks content
  NAMESPACES=("qa" "uat" "prod" "ingress-nginx")
  for NAMESPACE in "${NAMESPACES[@]}"; do
    # Check if namespace exists
    if kubectl get namespace "$NAMESPACE" &>/dev/null; then
      echo "Cleaning up namespace: $NAMESPACE"
      kubectl delete deployments --all --namespace "$NAMESPACE"
      kubectl delete services --all --namespace "$NAMESPACE"
      kubectl delete namespace "$NAMESPACE"
      echo "Completed cleanup of namespace: $NAMESPACE"
    else
      echo "Namespace $NAMESPACE does not exist, skipping"
    fi
  done
  echo "Cleanup process completed"
  # terraform destroy
  cd "$PROJECT_DIR/infra"
  terraform destroy -auto-approve
  # Destroy the ECR repositories
  cd "$PROJECT_DIR"
  bash scripts/ecr-delete.sh "${MICROSERVICES[@]}"
}

# Parse arguments and execute command
parse_args "$@"

# Execute the specified function if it exists
# compgen -A 'function' lists all declared functions
# https://stackoverflow.com/a/2627461
FUNC=$(compgen -A 'function' | grep "^${COMMAND}$")
[[ -n $FUNC ]] && {
  info execute "$COMMAND"
  eval "$COMMAND"
} || {
  if [[ -n "$COMMAND" ]]; then
    error "error" "Unknown command: $COMMAND"
  fi
  usage
}
exit 0
