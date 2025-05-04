resource "aws_db_subnet_group" "uat" {
  name       = "uat-db-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "uat DB subnet group"
  }
}

# UAT RDS
resource "aws_db_instance" "uat" {
  allocated_storage      = 10
  db_name                = "uat"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  port                   = var.db_port_number
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]

  db_subnet_group_name = aws_db_subnet_group.uat.name
  identifier           = var.environment

  deletion_protection = false
}


resource "aws_db_subnet_group" "prod" {
  name       = "prod-db-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "prod DB subnet group"
  }
}


resource "aws_db_instance" "prod" {
  allocated_storage      = 10
  db_name                = "prod"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  port                   = var.db_port_number
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]
  db_subnet_group_name   = aws_db_subnet_group.prod.name
  identifier             = "prod"

  deletion_protection = false
}
