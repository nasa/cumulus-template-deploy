
remote_state {
  backend = "s3"
  generate = {
    path      = "terraform.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = "nncpp-dev-tf-state"
    key = "${get_env("prefix")}/${path_relative_to_include()}/terraform.tfstate"
    region         = "${get_env("AWS_REGION")}"
    encrypt        = true
    dynamodb_table = "nncpp-dev-tf-locks"
  }
}

inputs = {
  prefix = get_env("prefix")
  aws_region = get_env("AWS_REGION")
}
