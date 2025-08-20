variable "prefix" {
  type = string
}

variable "rds_security_group" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "rds_user_access_secret_arn" {
  description = "AWS Secrets Manager secret ARN containing a JSON string of DB credentials (containing at least host, password, port as keys)"
  type        = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "permissions_boundary_arn" {
  type    = string
  default = null
}
