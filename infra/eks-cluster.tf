module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.31"
  cluster_name    = var.project_name
  cluster_version = "1.31"
  subnet_ids      = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access           = true
  cluster_endpoint_private_access          = true

  eks_managed_node_groups = {
    worker-group-1 = {
      instance_types                = ["t2.medium"]
      desired_size                  = 2
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
    }

    worker-group-2 = {
      instance_types                = ["t2.medium"]
      desired_size                  = 1
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_two.id]
    }
  }
}
