terraform {
  required_providers {
    aws  = ">= 3.5.0"
  }
}

provider "aws" {
  region = var.aws_region

  ignore_tags {
    key_prefixes = ["gsfc-ngap"]
  }
}

module "data_persistence" {
  source = "https://github.com/nasa/cumulus/releases/download/v5.0.0/terraform-aws-cumulus.zip//tf-modules/data-persistence"

  prefix                     = var.prefix
  subnet_ids                 = var.subnet_ids
  include_elasticsearch      = var.include_elasticsearch

  elasticsearch_config = {
    domain_name    = "es"
    instance_count = 2
    instance_type  = "t2.small.elasticsearch"
    version        = "5.3"
    volume_size    = 10
  }

  tags = {
    Deployment = var.prefix
  }
}
