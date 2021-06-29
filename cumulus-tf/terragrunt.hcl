include {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../vpc", "../data-persistence-tf"]
}

dependency "data_persistence" {
  config_path = "../data-persistence-tf"

  mock_outputs_allowed_terraform_commands = ["init", "validate"]
  mock_outputs = {}
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
  data_persistence_outputs = dependency.data_persistence.outputs
  vpc_id = dependency.vpc.outputs.vpc_id
  lambda_subnet_ids = dependency.vpc.outputs.subnet_ids
}
