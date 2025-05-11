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

## Usage

### Prerequisites

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
