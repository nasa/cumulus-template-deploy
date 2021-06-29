variable "create_vpc" {
  type = false
}

variable "vpc_availability_zones" {
  type = list(string)
}

variable "vpc_tag_name" {
    default = "*"
}

variable "subnet_tag_name" {
    default = "*"
}
