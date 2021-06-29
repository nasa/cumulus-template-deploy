dependencies {
  paths = ["../vpc", "../data-persistence-tf"]
}

dependency "data_persistence" {
  config_path = "../data_persistence-tf"
}

inputs = {
  data_persistence_outputs = dependency.data_persistence.outputs
}

include {
  path = find_in_parent_folders()
}
