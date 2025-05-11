variable "project_name" {
  default = "eks-blue-green"
}

variable "region" {
  default = "us-east-1"
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

variable "db_port_number" {
  type = string
}
