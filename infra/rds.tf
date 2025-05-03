module "db" {
  source = "terraform-aws-modules/rds/aws"

  # vpc        = module.vpc.id
  identifier = var.environment

  engine            = "mysql"
  engine_version    = "8.0.41"
  instance_class    = "db.t4g.micro"
  allocated_storage = 5

  db_name  = var.environment
  username = var.db_username
  password = var.db_password
  port     = var.db_port_number

  iam_database_authentication_enabled = true

  vpc_security_group_ids = [aws_security_group.worker_group_mgmt_one.id, aws_security_group.worker_group_mgmt_two.id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  subnet_ids             = module.vpc.private_subnets
  create_db_subnet_group = true

  # DB parameter group
  family = "mysql8.0"

  # DB option group
  major_engine_version = "8.0"

  # Database Deletion Protection
  deletion_protection = false
}
