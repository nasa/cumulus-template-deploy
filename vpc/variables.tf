variable "create_vpc" {
  type = bool
}

variable "vpc_availability_zones" {
  type = list(string)
}

variable "vpc_tag_name" {
  type = string
  default = "Application VPC"
}

variable "subnet_tag_name" {
  type = string
  default = "Private application *"
}
