variable "prefix" {
  type = string
}

variable "data_persistence_remote_state_config" {
  type = object({ bucket = string, key = string, region = string })
}

variable "provider_kms_key_id" {
  type = string
}


variable "rds_user_access_secret_arn" {
  description = "RDS User Database Login Credential Secret ID"
  type        = string
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

variable "rds_connection_heartbeat" {
  description = "If true, send a query to verify database connection is live on connection creation and retry on initial connection timeout.  Set to false if not using serverless RDS"
  type    = bool
  default = true
}

variable "rds_security_group_id" {
  description = "RDS Security Group used for access to RDS cluster"
  type        = string
  default     = ""
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

