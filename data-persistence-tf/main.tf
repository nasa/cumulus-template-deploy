
module "aws-data-source" {
  source = "../aws-data-sources-tf"
}


module "data_persistence" {
  source = "https://github.com/nasa/cumulus/releases/download/v1.17.0/terraform-aws-cumulus.zip//tf-modules/data-persistence"

  prefix                = var.prefix
  subnet_ids            = list(module.aws-data-source.subnets_ids[0])
  include_elasticsearch = var.include_elasticsearch
}



provider "aws" {
  region = var.aws_region
}



