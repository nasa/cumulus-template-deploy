data "aws_ssm_parameter" "ngap_ecs_image_id" {
  count = var.ecs_cluster_instance_image_id == null && var.deploy_to_ngap ? 1 : 0
  name = "/ngap/amis/image_id_ecs_al2023_x86"
}

data "aws_ssm_parameter" "aws_ecs_image_id" {
  count = var.ecs_cluster_instance_image_id == null && var.deploy_to_ngap ? 0 : 1
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended"
}

resource "random_string" "token_secret" {
  length  = 32
  special = true
}
