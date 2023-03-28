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

variable "include_elasticsearch" {
  type    = bool
  default = true
}

variable "permissions_boundary_arn" {
  type    = string
  default = null
}

variable "cloudwatch_log_retention_periods" {
  type = map(number)
  description = "retention periods for the respective cloudwatch log group, these values will be used instead of default retention days"
  default = {
    postgres-db-migration = 10, # data-persistence module
  }
}

variable "default_log_retention_days" {
  type = number
  default = 15
  description = "default value that user chooses for their log retention periods"
}