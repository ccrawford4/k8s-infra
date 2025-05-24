# EKS Infrastructure with Blue/Green Deployments

Infrastructure repo for deploying microservices to Amazon EKS with blue/green deployments using Argo Rollouts.

## Overview

This repository provides infrastructure-as-code for deploying and managing a complete microservices architecture on AWS EKS. It includes:

- Terraform modules for EKS cluster and RDS database provisioning
- CI/CD pipelines using GitHub Actions
- Blue/Green deployment strategy with Argo Rollouts
- ECR repository management

## Architecture and Deployment Strategy

![AWS EKS Infra](https://github.com/user-attachments/assets/f84f969a-cc31-4095-8144-f6d51fd05bab)

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

## Quick Start

### Prerequisites

Ensure you have the following tools installed:

```bash
# Required tools
aws --version        # AWS CLI v2.0+
terraform --version  # Terraform v1.0+
kubectl version      # kubectl v1.22+
docker --version     # Docker Desktop

# Optional but recommended
brew install argoproj/tap/argo-rollouts  # Argo Rollouts CLI
```

### Local Development Setup

**Step 1: Clone and Configure**

```bash
git clone https://github.com/ccrawford4/k8s-infra.git
cd k8s-infra

# Configure your Docker credentials
docker login
```

**Step 2: Build and Deploy Locally**

```bash
# Build all microservice images and push to your Docker Hub
./make.sh build-all <your-docker-username>

# Ensure you are using the correct Docker context. If using docker desktop:
kubectl config use-context docker-desktop

# Deploy the complete stack locally
./make.sh kube-local <your-docker-username>
```

**Step 3: Access the Applications**

```bash
# Start the Argo Rollouts dashboard
kubectl argo rollouts dashboard &

# Access your applications
open http://qa.localhost      # QA environment
open http://uat.localhost     # UAT environment  
open http://localhost         # Production environment
open http://localhost:3100    # Argo Rollouts dashboard
```

**Step 4: Seed Test Data**

```bash
# Add sample data to each environment
curl -X POST http://qa.localhost/crawl \
  -H "Content-Type: application/json" \
  -d '{"Host": "https://example.com"}'

curl -X POST http://uat.localhost/crawl \
  -H "Content-Type: application/json" \
  -d '{"Host": "https://news.ycombinator.com"}'
```

> **Note**: Large websites may overwhelm local containers. Use smaller sites for testing.

**Step 5: Cleanup**

```bash
# Remove local cluster and resources
./make.sh destroy-local
```

## Production Deployment

### AWS Infrastructure Setup

**Step 1: Configure Secrets**

Create `infra/secrets.auto.tfvars` from the example:

```bash
cd infra
cp secrets.auto.tfvars.example secrets.auto.tfvars
```

Edit the secrets file:

```hcl
# Database Configuration
db_username    = "admin"
db_password    = "your-secure-password-here"
db_port_number = "3306"

# Optional Overrides
project_name   = "my-awesome-project"  # Default: eks-blue-green  
region         = "us-west-2"           # Default: us-east-1
```

**Step 2: GitHub Repository Configuration**

Configure these secrets in your GitHub repository settings:

**Environment Secrets** (create for `qa`, `uat`, `prod`):

```
DSN=mysql://username:password@hostname:3306/database
HOSTNAME=qa.yourdomain.com
```

**Repository Secrets**:

```
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_ACCOUNT=123456789012
AWS_EKS_CLUSTER_NAME=eks-cluster
```

**Step 3: Deploy Infrastructure**

```bash
# Initialize ECR repositories
make setup

# Validate Terraform configuration  
make tf-validate

# Deploy AWS infrastructure
make tf-apply

# Configure kubectl access
make kube-config
```

> **Shell Compatibility**: If you encounter bash substitution errors, use a newer bash version:
>
> ```bash
> brew install bash
> /opt/homebrew/bin/bash make.sh setup
> ```

### Deployment Pipeline

**Initial Deployment Flow:**

1. Update the cluster issuer email in `k8s/cluster-issuer.yaml` (line 8)
2. Push code changes to microservice repositories
3. Images are automatically built and pushed to ECR
4. Trigger "Nightly Build" workflow for QA deployment
5. Monitor rollout progress in Argo dashboard

**Environment Promotion:**

1. Navigate to GitHub Actions → "Promote" workflow
2. Configure promotion parameters:
   - **Target Environment**: `uat` or `prod`
   - **SearchAPI Tag**: `v1.2.3`
   - **Frontend Tag**: `v1.2.3`
   - **StatsAPI Tag**: `v1.2.3`
3. Execute workflow and monitor deployment

## Monitoring and Operations

### Deployment Monitoring

```bash
# Watch specific rollout
kubectl argo rollouts get rollout search-api -n production --watch

# List all rollouts across namespaces
kubectl argo rollouts list rollouts --all-namespaces

# View rollout history
kubectl argo rollouts history rollout search-api -n production
```

### Common Operations

**Manual Rollout Control:**

```bash
# Promote to next step
kubectl argo rollouts promote search-api -n production

# Abort rollout
kubectl argo rollouts abort search-api -n production

# Restart rollout
kubectl argo rollouts restart search-api -n production
```

**Health Checks:**

```bash
# Check cluster status
kubectl get nodes

# Verify all pods
kubectl get pods --all-namespaces

# Check ingress status
kubectl get ingress --all-namespaces
```

## Configuration Reference

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `AWS_PROFILE` | AWS CLI profile name | `default` | No |
| `AWS_REGION` | AWS deployment region | `us-east-1` | No |
| `PROJECT_NAME` | Infrastructure project name | `eks-blue-green` | No |
| `CLUSTER_NAME` | EKS cluster identifier | `eks-cluster` | No |

### Terraform Variables

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `db_username` | string | RDS master username | Required |
| `db_password` | string | RDS master password | Required |
| `db_port_number` | string | Database port | `3306` |
| `project_name` | string | Resource naming prefix | `eks-blue-green` |
| `region` | string | AWS region | `us-east-1` |

## Troubleshooting

### Common Issues and Solutions

| Problem | Symptoms | Solution |
|---------|----------|----------|
| **EKS Access Denied** | `kubectl` commands fail with permission errors | Run `make kube-config` to update credentials |
| **Rollout Stuck** | Deployment hangs at analysis phase | Check health checks and promote manually if needed |
| **Database Connection** | Apps can't connect to RDS | Verify security groups and DSN format |
| **Image Pull Errors** | Pods stuck in `ImagePullBackOff` | Confirm ECR permissions and image tags |
| **Local DNS Issues** | Can't access `*.localhost` domains | Ensure Docker Desktop's Kubernetes is enabled |

### Debug Commands

```bash
# Get detailed pod information
kubectl describe pod <pod-name> -n <namespace>

# View application logs
kubectl logs -f deployment/<app-name> -n <namespace>

# Check rollout events
kubectl describe rollout <rollout-name> -n <namespace>

# Validate ingress configuration
kubectl get ingress -o yaml -n <namespace>
```

### Resource Cleanup

```bash
# Remove all infrastructure 
make tf-destroy. 
