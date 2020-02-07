# AWS data sources 
## About

This module can be used to fetch a lambda ARN, VPC id and subnet id using Terraform filter


## How to use
```bash
in your terraform file declare the module

module "aws-data-source" {
  source = "./aws-data-sources-tf"

  vpc_tag_name                = <VPC name tag. Default '*'>
  subnet_tag_name            = <Subnet name tag. Default '*'>
  lambda_function_name       = <lambda function name. Default "" >
}


To use it within your custom module

module "cumulus" {
  source = "https://github.com/nasa/cumulus/releases/download/v1.17.0/terraform-aws-cumulus.zip//tf-modules/cumulus"
  vpc_id            = module.aws-data-source.application_vpc.id
  lambda_subnet_ids = list(module.aws-data-source.subnets_ids)
  sts_credentials_lambda_function_arn = module.aws-data-source.lambda_function_arn
  ...
 }
  
``` 




