output "vpc_id" {
  value = var.create_vpc ? module.main_vpc[0].vpc_id : data.aws_vpc.application_vpc[0].id
}

output "subnet_ids" {
  value = var.create_vpc ? module.main_vpc[0].private_subnets : sort(data.aws_subnet_ids.subnet_ids[0].ids)
}

output "vpc_cidr_block" {
  value = var.create_vpc ? module.main_vpc[0].vpc_cidr_block : data.aws_vpc.application_vpc[0].ipv6_cidr_block
}
