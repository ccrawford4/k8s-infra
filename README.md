# EKS Kubernetes Cluster Infrastructure

## Features

1. Github actions (CI/CD) for deploying to **EKS**.
2. Terraform modules for deploying one EKS Cluster and two RDS instances.
3. Scripts for creating/deleting ECR repositories.
4. Kubernetes manifests for deploying three microservices.

## Microservices

The infrastrucure is designed to deploy three microservices:

1. [Next.js frontend]("https://github.com/ccrawford4/search-app")
2. [Golang SearchAPI](https://github.com/ccrawford4/search) responsible for retrieving search results from the database and for crawling web pages.
3. [Golang StatsAPI] responsible for returning the most and least frequenct words found in the database.
