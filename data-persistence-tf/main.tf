module "data_persistence" {
  source = "https://github.com/nasa/cumulus/releases/download/v1.19.0/terraform-aws-cumulus.zip//tf-modules/data-persistence"

  prefix                     = var.prefix
  subnet_ids                 = var.subnet_ids
  include_elasticsearch      = var.include_elasticsearch

  tags = {
    Deployment = var.prefix
  }
}

variable "prefix" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "include_elasticsearch" {
  type    = bool
  default = true
}

provider "aws" {
  region = var.aws_region
}

output "dynamo_tables" {
  value = module.data_persistence.dynamo_tables
}

output "elasticsearch_domain_arn" {
  value = module.data_persistence.elasticsearch_domain_arn
}

output "elasticsearch_hostname" {
  value = module.data_persistence.elasticsearch_hostname
}

output "elasticsearch_security_group_id" {
  value = module.data_persistence.elasticsearch_security_group_id
}

output "elasticsearch_alarms" {
  value = module.data_persistence.elasticsearch_alarms
}
