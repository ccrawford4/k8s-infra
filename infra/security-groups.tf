
resource "aws_security_group" "worker_group_mgmt_one" {
  name_prefix = "worker_group_mgmt_one"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }

  ingress {
    from_port = var.db_port_number
    to_port   = var.db_port_number
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "worker_group_mgmt_two" {
  name_prefix = "worker_group_mgmt_two"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "192.168.0.0/16",
    ]
  }
}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }

  ingress {
    from_port = var.db_port_number
    to_port   = var.db_port_number
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_security_group" {
  name_prefix = "rds-security-group"
  vpc_id      = module.vpc.vpc_id

  # Allow MySQL traffic from worker group 1
  ingress {
    from_port       = var.db_port_number
    to_port         = var.db_port_number
    protocol        = "tcp"
    security_groups = [aws_security_group.worker_group_mgmt_one.id]
    description     = "Allow MySQL traffic from worker group 1"
  }

  # Allow MySQL traffic from worker group 2
  ingress {
    from_port       = var.db_port_number
    to_port         = var.db_port_number
    protocol        = "tcp"
    security_groups = [aws_security_group.worker_group_mgmt_two.id]
    description     = "Allow MySQL traffic from worker group 2"
  }

  # Required for RDS to communicate with AWS services
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
