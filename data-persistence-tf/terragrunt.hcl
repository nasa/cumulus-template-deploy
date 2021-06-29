dependencies {
  paths = ["../vpc"]
}

include {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs_allowed_terraform_commands = ["init", "validate"]
  mock_outputs = {
    vpc_id = "fake-vpc-id"
    subnet_ids = ["fake-subnet-1", "fake-subnet-2"]
  }
}

inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.subnet_ids
}

