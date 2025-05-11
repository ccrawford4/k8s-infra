.SILENT:

help:
	{ grep --extended-regexp '^[a-zA-Z0-9._-]+:.*#[[:space:]].*$$' $(MAKEFILE_LIST) || true; } \
	| awk 'BEGIN { FS = ":.*#[[:space:]]*" } { printf "\033[1;32m%-17s\033[0m%s\n", $$1, $$2 }'

setup: # npm install + terraform init + create ecr repository
	./make.sh setup

dev: # local development
	./make.sh dev

tf-validate: # terraform validate
	./make.sh tf-validate

tf-apply: # terraform plan + terraform apply
	./make.sh tf-apply

kube-config: # setup kubectl config
	./make.sh kube-config

destroy: # delete eks content + terraform destroy + delete ecr repository
	./make.sh destroy
