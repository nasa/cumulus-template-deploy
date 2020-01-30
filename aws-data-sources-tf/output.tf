output "application_vpc" {
  value = data.aws_vpc.application_vpc
}

output "subnets_ids" {
  value = sort(data.aws_subnet_ids.subnet_ids.ids)
}

output "lambda_sts_credentials" {
  value = data.aws_lambda_function.sts_credentials
}