terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  ignore_tags {
    key_prefixes = ["gsfc-ngap"]
  }
}

data "aws_region" "current" {}

module "data_persistence" {
  source = "https://github.com/nasa/cumulus/releases/download/v18.3.1/terraform-aws-cumulus.zip//tf-modules/data-persistence"

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
