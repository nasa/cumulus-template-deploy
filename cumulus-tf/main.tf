terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.14.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 2.1"
    }
    archive = {
      source = "hashicorp/archive"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile

  ignore_tags {
    key_prefixes = ["gsfc-ngap"]
  }
}

locals {
  tags                            = merge(var.tags, { Deployment = var.prefix })
  elasticsearch_alarms            = lookup(data.terraform_remote_state.data_persistence.outputs, "elasticsearch_alarms", [])
  elasticsearch_domain_arn        = lookup(data.terraform_remote_state.data_persistence.outputs, "elasticsearch_domain_arn", null)
  elasticsearch_hostname          = lookup(data.terraform_remote_state.data_persistence.outputs, "elasticsearch_hostname", null)
  elasticsearch_security_group_id = lookup(data.terraform_remote_state.data_persistence.outputs, "elasticsearch_security_group_id", "")
  protected_bucket_names          = [for k, v in var.buckets : v.name if v.type == "protected"]
  public_bucket_names             = [for k, v in var.buckets : v.name if v.type == "public"]
  rds_security_group              = lookup(data.terraform_remote_state.data_persistence.outputs, "rds_security_group", "")
  rds_credentials_secret_arn      = lookup(data.terraform_remote_state.data_persistence.outputs, "database_credentials_secret_arn", "")
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "terraform_remote_state" "data_persistence" {
  backend   = "s3"
  config    = var.data_persistence_remote_state_config
  workspace = terraform.workspace
}


module "cumulus" {

  cumulus_message_adapter_lambda_layer_version_arn = var.cumulus_message_adapter_lambda_layer_version_arn

  prefix = var.prefix

  # DO NOT CHANGE THIS VARIABLE UNLESS DEPLOYING OUTSIDE NGAP
  deploy_to_ngap = true

  vpc_id            = var.vpc_id
  lambda_subnet_ids = var.lambda_subnet_ids

  ecs_cluster_instance_image_id   = var.ecs_cluster_instance_image_id
  ecs_cluster_instance_subnet_ids = length(var.ecs_cluster_instance_subnet_ids) == 0 ? var.lambda_subnet_ids : var.ecs_cluster_instance_subnet_ids
  ecs_cluster_min_size            = 1
  ecs_cluster_desired_size        = 1
  ecs_cluster_max_size            = 2
  key_name                        = var.key_name

  rds_security_group         = local.rds_security_group
  rds_user_access_secret_arn = local.rds_credentials_secret_arn
  rds_connection_heartbeat   = var.rds_connection_heartbeat

  urs_url             = var.urs_url
  urs_client_id       = var.urs_client_id
  urs_client_password = var.urs_client_password

  metrics_es_host     = var.metrics_es_host
  metrics_es_password = var.metrics_es_password
  metrics_es_username = var.metrics_es_username

  cmr_client_id   = var.cmr_client_id
  cmr_environment = var.cmr_environment
  cmr_username    = var.cmr_username
  cmr_password    = var.cmr_password
  cmr_provider    = var.cmr_provider

  cmr_oauth_provider = var.cmr_oauth_provider

  launchpad_api         = var.launchpad_api
  launchpad_certificate = var.launchpad_certificate
  launchpad_passphrase  = var.launchpad_passphrase

  oauth_provider   = var.oauth_provider
  oauth_user_group = var.oauth_user_group

  saml_entity_id                  = var.saml_entity_id
  saml_assertion_consumer_service = var.saml_assertion_consumer_service
  saml_idp_login                  = var.saml_idp_login
  saml_launchpad_metadata_url     = var.saml_launchpad_metadata_url

  permissions_boundary_arn = var.permissions_boundary_arn

  system_bucket = var.system_bucket
  buckets       = var.buckets

  elasticsearch_alarms            = local.elasticsearch_alarms
  elasticsearch_domain_arn        = local.elasticsearch_domain_arn
  elasticsearch_hostname          = local.elasticsearch_hostname
  elasticsearch_security_group_id = local.elasticsearch_security_group_id

  dynamo_tables = data.terraform_remote_state.data_persistence.outputs.dynamo_tables

  # Archive API settings
  token_secret                = var.token_secret
  archive_api_users           = var.api_users
  archive_api_port            = var.archive_api_port
  private_archive_api_gateway = var.private_archive_api_gateway
  api_gateway_stage           = var.api_gateway_stage

  # Thin Egress App settings
  # Remove if using Cumulus Distribution
  # must match stage_name variable for thin-egress-app module
  tea_api_gateway_stage = local.tea_stage_name

  tea_rest_api_id               = module.thin_egress_app.rest_api.id
  tea_rest_api_root_resource_id = module.thin_egress_app.rest_api.root_resource_id
  tea_internal_api_endpoint     = module.thin_egress_app.internal_api_endpoint
  tea_external_api_endpoint     = module.thin_egress_app.api_endpoint

  # Cumulus Distribution settings. Uncomment the following line and remove/comment the above variables if using the Cumulus Distribution API instead of TEA.
  # tea_external_api_endpoint = var.cumulus_distribution_url

  log_destination_arn          = var.log_destination_arn
  additional_log_groups_to_elk = var.additional_log_groups_to_elk

  deploy_distribution_s3_credentials_endpoint = var.deploy_distribution_s3_credentials_endpoint

  tags = local.tags
}
