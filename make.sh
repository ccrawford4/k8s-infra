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

log() { echo -e "\e[30;47m ${1^^} \e[0m ${@:2}"; }          # $1 uppercase background white
info() { echo -e "\e[48;5;28m ${1^^} \e[0m ${@:2}"; }       # $1 uppercase background green
warn() { echo -e "\e[48;5;202m ${1^^} \e[0m ${@:2}" >&2; }  # $1 uppercase background orange
error() { echo -e "\e[48;5;196m ${1^^} \e[0m ${@:2}" >&2; } # $1 uppercase background red

# https://unix.stackexchange.com/a/22867
export -f log info warn error

DOCKER_USERNAME="$2"

# log $1 in underline then $@ then a newline
under() {
  local arg=$1
  shift
  echo -e "\033[0;4m${arg}\033[0m ${@}"
  echo
}

usage() {
  under usage 'call the Makefile directly: make dev
      or invoke this file directly: ./make.sh dev'
}

setup() {
  # terraform init
  cd "$PROJECT_DIR/infra"
  terraform init

  cd "$PROJECT_DIR"
  bash scripts/ecr-create.sh "${MICROSERVICES[@]}"
}

build-all() {
  cd $PROJECT_DIR
  bash scripts/build.sh $DOCKER_USERNAME
}

kube-local() {
  cd $PROJECT_DIR
  bash scripts/kube-init.sh $DOCKER_USERNAME
}

delete-all() {
  cd $PROJECT_DIR
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

# if `$1` is a function, execute it. Otherwise, print usage
# compgen -A 'function' list all declared functions
# https://stackoverflow.com/a/2627461
FUNC=$(compgen -A 'function' | grep $1)
[[ -n $FUNC ]] && {
  info execute $1
  eval $1
} || usage
exit 0
