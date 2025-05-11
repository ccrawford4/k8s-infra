# EKS Kubernetes Cluster Infrastructure and CI/CD for Blue/Green Deployments with Argo Rollouts

## Features

1. Github actions (CI/CD) for deploying to **EKS**.
2. Terraform modules for deploying one EKS Cluster and two RDS instances.
3. Scripts for creating/deleting ECR repositories.
4. Kubernetes manifests for deploying three microservices.

## Microservices

The infrastrucure is designed to deploy three microservices:

1. [Next.js frontend]("https://github.com/ccrawford4/search-app")
2. [Golang SearchAPI](https://github.com/ccrawford4/search)
3. [Golang StatsAPI](https://github.com/ccrawford4/stats)

## Additional Services

The infrastructure also deploys the following services:

1. MySQL RDS instance
2. Redis Cache

## Prerequisites

Ensure your github repo is configured with the following environment secrets:

1. Environment zero: "qa": (quality assurance)
2. Environment one: "uat" (user acceptance testing)
3. Environment two: "prod" (production)

Secrets:

- 'DSN': The Database Connection String used by the SearchAPI and StatsAPI.
- 'HOSTNAME': The hostname of the Ingress. E.g. 'qa.example.com', 'uat.example.com', 'prod.example.com'.

Repository Secrets:

- 'AWS_ACCESS_KEY_ID': AWS Access Key ID (ensure the user has permissions to manage EKS and EC2)
- 'AWS_ACCOUNT': The AWS Account ID
- 'AWS_EKS_CLUSTER_NAME': The name of your EKS cluster (default 'eks-cluster')

### Usage

Step 1: Clone the repository

```bash
git clone https://github.com/ccrawford4/k8s-infra.git
```

Step 2:
Ensure the following are set correctly in the `make.sh` file:

1. AWS_PROFILE
2. AWS_REGION

Step 3: Create a new secrets file and populate it with the correct values.

```bash
cd infra 
cp secrets.auto.tfvars.example secrets.auto.tfvars
```

Fill in the secrets.auto.tfvars file with the correct values. The secrets.auto.tfvars file is used to populate the terraform variables. The secrets.auto.tfvars file should look like this:

```hcl
db_username    = "<The database username for uat and prod>"
db_password    = "<The database password for uat and prod>"
db_port_number = "<The database port number for uat and prod>"
```

Additional variables to add (optional):

```hcl
project_name = "<The project name>" (default is eks-blue-green)
region = "<The AWS region>" (default is us-east-1)
```

Step 4. Run the setup command (will run terraform init and create the ECR repositories)

```bash
make setup
```

Note: If you get an error like this:
`/make.sh: line 17: \e[48;5;28m ${1^^} \e[0m ${@:2}: bad substitution`
You may be using an older version of bash. If on MacOS, you can upgrade bash using brew

```bash
brew install bash
```

And then call it directly:

```bash
/opt/homebrew/bin/bash make.sh setup
```

Step 5. Terraform validate

```bash
make tf-validate
```

Step 6. Terraform Apply

```bash
make tf-apply
```

Step 7. Upgrade your kubectl config

```bash
make kube-config
```

Step 8. Push a change to all of the microservice repos to trigger a build and push to their respective ECR repository.

Step 9. Deploy to QA using the "Nightly Build" workflow dispatch.

Step 10. Run argo rollouts locally to see the changes
Note: ensure you have the argo rollouts plugin installed

```bash
brew install argoproj/tap/argo-rollouts
```

Then run the following command to see the rollout status:
kubectl argo rollouts get rollout <rollout-name> -n <namespace>

```

Open it up at http://localhost:3100

Step 11. To deploy to UAT, run the "Promote" workflow disaptch on Github using the following inputs:
Environment: uat
tag of searchapi: <the latest qa-<searchapi-tag> you can find in the searchapi ECR repo>
tag of web image: <same as above but for web>
tag of statsapi: <same as above but for statsapi>

Change the namespace in argo-rollouts in the dashboard at localhost:3100 to uat and monitor the blue/green deployment.
