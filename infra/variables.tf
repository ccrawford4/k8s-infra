variable "aws_region" {
  type = string
}

# ------------ VPC -------------------
variable "vpc_cidr_block" {
  type = string    
}

variable "subnet_count" {
  type = map(number) 
}

variable "public_subnet_cidr_blocks" {
  type = list(string)
}

variable "private_subnet_cidr_blocks" {
  type = list(string)
}
