variable "region" {
  type    = string
  default = "us-east-1"
}

variable "cloud_config_content" {
  type    = string
  default = "/bin/true"
}

variable "key_name" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}
