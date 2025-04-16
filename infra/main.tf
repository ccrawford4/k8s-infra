module "vpc" {
  source = "./vpc"
  aws_region = var.aws_region
  vpc_cidr_block = var.vpc_cidr_block
  subnet_count = var.subnet_count
  public_subnet_cidr_blocks = var.public_subnet_cidr_blocks
  private_subnet_cidr_blocks = var.private_subnet_cidr_blocks
}
