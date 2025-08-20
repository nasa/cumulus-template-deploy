output "dynamo_tables" {
  value = module.data_persistence.dynamo_tables
}

output "rds_security_group" {
  value = var.rds_security_group
}

output "rds_user_access_secret_arn" {
  value = var.rds_user_access_secret_arn
}
