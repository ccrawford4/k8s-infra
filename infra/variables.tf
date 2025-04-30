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
