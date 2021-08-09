variable "db_admin_username" {
  description = "Username for RDS database authentication"
  type = string
}

variable "db_admin_password" {
  description = "Password for RDS database authentication"
  type = string
}

variable "region" {
  description = "Region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID for the Cumulus Deployment"
  type        = string
}

variable "subnets" {
  description = "Subnets for database cluster.  Requires at least 2 across multiple AZs"
  type    = list(string)
}

variable "deletion_protection" {
  description = "Flag to prevent terraform from making changes that delete the database in CI"
  type        = bool
  default     = true
}

variable "cluster_identifier" {
  description = "DB identifier for the RDS cluster that will be created"
  type        = string
  default     = "cumulus-rds-serverless-default-cluster"
}

variable "snapshot_identifier" {
  description = "Optional database snapshot for restoration"
  type = string
  default = null
}

variable "tags" {
  description = "Tags to be applied to RDS cluster resources that support tags"
  type        = map(string)
  default     = {}
}

variable "engine_version" {
  description = "Postgres engine version for Serverless cluster"
  type        = string
  default     = "10.12"
}

### Required for user/database provisioning
variable "provision_user_database" {
  description = "true/false flag to configure if the module should provision a user and database using default settings"
  type = bool
  default = false
}

variable "prefix" {
  type = string
  default = "cumulus-rds-tf"
}

variable "permissions_boundary_arn" {
  type    = string
  default = ""
}

variable "rds_user_password" {
  type    = string
  default = "changeme"
}
