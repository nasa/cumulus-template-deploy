terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.14.1"
    }
  }
}

provider "aws" {
  region = var.aws_region

  ignore_tags {
    key_prefixes = ["gsfc-ngap"]
  }
}

module "data_persistence" {
  source = "https://github.com/nasa/cumulus/releases/download/v9.0.0/terraform-aws-cumulus.zip//tf-modules/data-persistence"

  prefix                         = var.prefix
  subnet_ids                     = var.subnet_ids
  include_elasticsearch          = var.include_elasticsearch
  
  vpc_id                         = var.vpc_id
  rds_security_group_id          = var.rds_security_group
  rds_user_access_secret_arn     = var.rds_user_access_secret_arn
  permissions_boundary_arn       = var.permissions_boundary_arn


  tags = {
    Deployment = var.prefix
  }
}
