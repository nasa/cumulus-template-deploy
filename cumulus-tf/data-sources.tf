data "aws_ssm_parameter" "ngap_ecs_image_id" {
  count = var.deploy_to_ngap ? 1 : 0
  name = "image_id_ecs_amz2"
}

data "aws_ssm_parameter" "aws_ecs_image_id" {
  count = var.deploy_to_ngap ? 0 : 1
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

resource "random_string" "token_secret" {
  length  = 32
  special = true
}
