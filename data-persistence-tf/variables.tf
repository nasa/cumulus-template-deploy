variable "prefix" {
  type = string
}


variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "include_elasticsearch" {
  type    = bool
  default = true
}