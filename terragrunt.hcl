
remote_state {
  backend = "s3"
  generate = {
    path      = "terraform.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = get_env("TF_STATE_BUCKET")
    key = "${get_env("prefix")}/${path_relative_to_include()}/terraform.tfstate"
    region         = "${get_env("AWS_REGION")}"
    encrypt        = true
    dynamodb_table = get_env("TF_LOCKS_TABLE")
  }
}

inputs = {
  prefix = get_env("prefix")
  aws_region = get_env("AWS_REGION")
}
