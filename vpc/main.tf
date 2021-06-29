data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  common_vars = jsondecode(file(find_in_parent_folders("common-vars.json")))
}

module "main_vpc" {
  count = var.create_vpc ? 1 : 0
  source     = "terraform-aws-modules/vpc/aws"
  version    = "2.21.0"
  name       = "${local.common_vars.prefix}-vpc"
  cidr       = "10.50.160.0/22"

  azs                          = var.vpc_availability_zones
  private_subnets              = ["10.50.161.0/25", "10.50.160.128/25", "10.50.162.0/25", "10.50.162.128/25"]
  # public_subnets               = ["10.50.160.0/25", "10.50.161.128/25", "10.50.163.0/25", "10.50.163.128/25"]
  enable_nat_gateway           = true
  single_nat_gateway           = true
  enable_dns_hostnames         = true
  enable_dns_support           = true
}

data "aws_vpc" "application_vpc" {
  count = var.create_vpc ? 0 : 1
  tags = {
    Name = var.vpc_tag_name
  }
}

data "aws_subnet_ids" "subnet_ids" {
  count = var.create_vpc ? 0 : 1
  vpc_id = data.aws_vpc.application_vpc.id
  filter {
    name   = "tag:Name"
    values = [var.subnet_tag_name]
  }
}
