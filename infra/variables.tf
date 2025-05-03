variable "project_name" {
  default = "eks-blue-green"
}

variable "region" {
  default = "us-east-1"
}

variable "profile" {
  default = "default"
}

variable "iam_role_arn" {
  type = string
}

variable "environment" {
  type = string
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
