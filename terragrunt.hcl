remote_state {
  backend = "s3"
  generate = {
    path      = "terraform.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = "nncpp-dev-tf-state"
    key = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "nncpp-dev-tf-locks"
  }
}
