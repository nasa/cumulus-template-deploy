output "application_vpc" {
  value = data.aws_vpc.application_vpc
}

output "subnets_ids" {
  value = sort(data.aws_subnet_ids.subnet_ids.ids)
}

output "lambda_function_arn" {
  value = data.aws_lambda_function.lambda_function.arn
}