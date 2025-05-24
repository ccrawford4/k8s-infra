#/bin/bash

PROJECT_DIR="$(
  cd "$(dirname "$0")"/..
  pwd
)"

# Destroy the repositories
cd "$PROJECT_DIR"
bash scripts/delete.sh

# Delete all the namespaces and their resources
for env in qa uat prod ingress-nginx argo-rollouts; do
  kubectl delete namespace $env --ignore-not-found
done
