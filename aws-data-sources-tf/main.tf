data "aws_vpc" "application_vpc" {
  tags = {
    Name = var.vpc_tag_name
  }
}

data "aws_subnet_ids" "subnet_ids" {
  vpc_id = data.aws_vpc.application_vpc.id
   filter {
    name   = "tag:Name"
    values = ["${var.subnet_tag_name} *"]
  }
}

data "aws_lambda_function" "sts_credentials" {
  function_name = var.sts_credentials_function_name
}