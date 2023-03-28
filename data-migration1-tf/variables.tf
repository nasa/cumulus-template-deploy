variable "prefix" {
  type = string
}

variable "data_persistence_remote_state_config" {
  type = object({ bucket = string, key = string, region = string })
}

variable "provider_kms_key_id" {
  type = string
}

# Optional

variable "lambda_subnet_ids" {
  type = list(string)
  default = []
}

variable "permissions_boundary_arn" {
  type    = string
  default = null
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "tags" {
  description = "Tags to be applied to Cumulus resources that support tags"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  type    = string
  default = null
}

variable "cloudwatch_log_retention_periods" {
  type = map(number)
  description = "retention periods for the respective cloudwatch log group, these values will be used instead of default retention days"
  default = {
    data-migration-1 = 10, #data-migration1 module
  }
}

variable "default_log_retention_days" {
  type = number
  default = 15
  description = "default value that user chooses for their log retention periods"
}
