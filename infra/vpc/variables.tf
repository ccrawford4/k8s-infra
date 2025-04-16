variable "aws_region" {
  type = string
}
variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
}
variable "subnet_count" {
    description = "Number of subnets"
    type = map(number)
}
variable "public_subnet_cidr_blocks" {
  description = "Available CIDR blocks for public subnets"
  type        = list(string)
}
variable "private_subnet_cidr_blocks" {
  description = "Available CIDR blocks for private subnets"
  type        = list(string)
}
