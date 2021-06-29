dependencies {
  paths = ["../vpc", "../data-persistence-tf"]
}

dependency "data_persistence" {
  config_path = "../data_persistence-tf"
}

dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  data_persistence_outputs = dependency.data_persistence.outputs
  vpc_id = dependency.vpc.outputs.vpc_id
  lambda_subnet_ids = dependency.vpc.outputs.subnet_ids
}

include {
  path = find_in_parent_folders()
}
