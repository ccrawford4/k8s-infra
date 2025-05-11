# EKS Infrastructure with Blue/Green Deployments

Infrastructure repo for deploying microservices to Amazon EKS with blue/green deployments using Argo Rollouts.

## Overview

This repository provides infrastructure-as-code for deploying and managing a complete microservices architecture on AWS EKS. It includes:

- Terraform modules for EKS cluster and RDS database provisioning
- CI/CD pipelines using GitHub Actions
- Blue/Green deployment strategy with Argo Rollouts
- ECR repository management

## Architecture

![Architecture Diagram](https://via.placeholder.com/800x400?text=Architecture+Diagram)

### Components

| Component | Description |
|-----------|-------------|
| **EKS Cluster** | Kubernetes cluster for orchestrating containerized applications |
| **RDS Instances** | Two MySQL database instances for different environments |
| **ECR Repositories** | Container registries for microservice images |
| **Argo Rollouts** | Controller for progressive delivery and blue/green deployments |
| **Redis Cache** | In-memory data store for caching |

### Microservices

The infrastructure is designed to deploy three microservices:

1. [Next.js Frontend](https://github.com/ccrawford4/search-app) - Web interface
2. [Golang SearchAPI](https://github.com/ccrawford4/search) - Search functionality
3. [Golang StatsAPI](https://github.com/ccrawford4/stats) - Analytics and statistics

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform (>= 1.0.0)
- kubectl (>= 1.22.0)
- Argo Rollouts plugin (`brew install argoproj/tap/argo-rollouts`)
- GitHub account with access to the microservice repositories

## Setup Instructions

### 1. Repository Configuration

Configure the following GitHub repository secrets:

**Environment Secrets** (for each of: `qa`, `uat`, and `prod`):

- `DSN` - Database connection string
- `HOSTNAME` - Environment hostname (e.g., `qa.example.com`)

**Repository Secrets**:

- `AWS_ACCESS_KEY_ID` - AWS access key
- `AWS_SECRET_ACCESS_KEY` - AWS secret key
- `AWS_ACCOUNT` - AWS account ID
- `AWS_EKS_CLUSTER_NAME` - EKS cluster name (default: `eks-cluster`)

### 2. Local Setup

```bash
# Clone the repository
git clone https://github.com/ccrawford4/k8s-infra.git
cd k8s-infra

# Configure AWS profile and region in make.sh
# Edit AWS_PROFILE and AWS_REGION variables

# Create and populate secrets file
cd infra
cp secrets.auto.tfvars.example secrets.auto.tfvars
```

Edit `secrets.auto.tfvars` with your configuration:

```hcl
# Required
db_username    = "admin"
db_password    = "your-secure-password"
db_port_number = "3306"

# Optional
project_name   = "your-project"  # Default: eks-blue-green
region         = "us-east-1"     # Default: us-east-1
```

### 3. Infrastructure Deployment

```bash
# Initialize and create ECR repositories
make setup

# Validate Terraform configuration
make tf-validate

# Deploy infrastructure
make tf-apply

# Update kubectl configuration
make kube-config
```

> **Note**: If you encounter a shell error like:
>
> ```
> /make.sh: line 17: \e[48;5;28m ${1^^} \e[0m ${@:2}: bad substitution
> ```
>
> Use a newer version of bash:
>
> ```bash
> brew install bash
> /opt/homebrew/bin/bash make.sh setup
> ```

## Deployment Workflow

### Initial Deployment

1. Push changes to microservice repositories to trigger builds and ECR pushes
2. Trigger the "Nightly Build" workflow in GitHub Actions to deploy to QA

### Monitoring Deployments

```bash
# Install Argo Rollouts plugin (if not already installed)
brew install argoproj/tap/argo-rollouts

# Monitor rollout status
kubectl argo rollouts get rollout <rollout-name> -n <namespace>

# Start dashboard
kubectl argo rollouts dashboard
```

Access the dashboard at <http://localhost:3100>

### Promoting to Higher Environments

1. Navigate to GitHub Actions
2. Select the "Promote" workflow
3. Use the following inputs:
   - **Environment**: `uat` or `prod`
   - **Tag of searchapi**: Latest tag
   - **Tag of web image**: Latest tag
   - **Tag of statsapi**: Latest tag
4. Monitor the deployment in the Argo Rollouts dashboard

## Maintenance

### Cleaning Up Resources

```bash
# Destroy infrastructure
make tf-destroy
```

### Updating Dependencies

Periodically update provider versions in `versions.tf` to maintain security and access new features.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| EKS connection issues | Ensure `make kube-config` was run successfully |
| Deployment failures | Check GitHub Actions logs and Argo Rollouts status |
| Database connectivity | Verify security groups and the `DSN` secret |

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request
