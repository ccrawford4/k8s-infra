provider "aws" {
  region = var.aws_region
}

# Get all the availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Create the VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = true 
}

# Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

# Create a public subnet
resource "aws_subnet" "public_subnet" {
  count = var.subnet_count.public
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.public_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}

# Create the private subnet
resource "aws_subnet" "private_subnet" {
  count = var.subnet_count.private
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.private_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

# Create a public route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Create the private route table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id
}

# Associate the public route table with the public subnets
resource "aws_route_table_association" "public" {
  count          = var.subnet_count.public
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public_subnet[count.index].id
}

resource "aws_route_table_association" "private" {
  count          = var.subnet_count.private
  route_table_id = aws_route_table.private_rt.id
  subnet_id      = aws_subnet.private_subnet[count.index].id
}
