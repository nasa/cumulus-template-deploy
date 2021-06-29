terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.14.1"
    }
  }
}

locals {
  common_vars = jsondecode(file(find_in_parent_folders("common-vars.json")))
}

provider "aws" {
  region = local.common_vars.aws_region

  ignore_tags {
    key_prefixes = ["gsfc-ngap"]
  }
}

module "data_persistence" {
  source = "https://github.com/nasa/cumulus/releases/download/v8.1.0/terraform-aws-cumulus.zip//tf-modules/data-persistence"

  prefix                = var.prefix
  subnet_ids            = var.subnet_ids
  include_elasticsearch = var.include_elasticsearch

  tags = {
    Deployment = var.prefix
  }
}
