provider "aws" {
  region = var.region
}

module "container_service_cluster" {
  source = "github.com/azavea/terraform-aws-ecs-cluster?ref=2.0.0"

  cloud_config_content = var.cloud_config_content
  key_name             = var.key_name
  private_subnet_ids   = var.subnet_ids
  vpc_id               = var.vpc_id
}
