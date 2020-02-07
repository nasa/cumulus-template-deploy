data "aws_vpc" "application_vpc" {
  tags = {
    Name = var.vpc_tag_name
  }
}

data "aws_subnet_ids" "subnet_ids" {
  vpc_id = data.aws_vpc.application_vpc.id
   filter {
    name   = "tag:Name"
    values = [var.subnet_tag_name]
  }

}

data "aws_lambda_function" "lambda_function" {
  function_name = var.lambda_function_name
}