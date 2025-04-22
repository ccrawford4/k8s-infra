module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"
  cluster_name    = var.project_name
  cluster_version = "1.31"
  subnet_ids      = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  eks_managed_node_groups = {
    worker-group-1 = {
      instance_types             = ["t2.small"]
      desired_size               = 2
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
    }

    worker-group-2 = {
      instance_types             = ["t2.medium"]
      desired_size               = 1
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_two.id]
    }
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
