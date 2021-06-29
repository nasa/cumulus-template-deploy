output "vpc_id" {
  value = var.create_vpc ? module.main_vpc.vpc_id : data.aws_vpc.application_vpc.id
}

output "subnet_ids" {
  value = var.create_vpc ? module.main_vpc.private_subnets : sort(data.aws_subnet_ids.subnet_ids.ids)
}

output "vpc_cidr_block" {
  value = var.create_vpc ? module.main_vpc.vpc_cidr_block : data.aws_vpc.application_vpc.ipv6_cidr_block
}
