# Required

variable "cmr_client_id" {
  type = string
}

variable "deploy_to_ngap" {
  description = "true if deploying to an NGAP environment"
  type = bool
}

variable "cumulus_message_adapter_version" {
  description = "Version of Cumulus Message Adapter to download"
  type = string
}

variable "cmr_environment" {
  type = string
}

variable "cmr_password" {
  type = string
}

variable "cmr_provider" {
  type = string
}

variable "cmr_username" {
  type = string
}
variable "cmr_oauth_provider" {
  type    = string
  default = "earthdata"
}

variable "csdap_client_id" {
  type        = string
  default     = null
  description = "The csdap client id"
}

variable "csdap_client_password" {
  type        = string
  default     = null
  description = "The csdap client password"
}

variable "csdap_host_url" {
  type        = string
  default     = null
  description = "The csdap host url"
}

variable "ecs_cluster_instance_subnet_ids" {
  type    = list(string)
  default = []
}

variable "lambda_subnet_ids" {
  type    = list(string)
  default = []
}

variable "launchpad_api" {
  type    = string
  default = "launchpadApi"
}

variable "launchpad_certificate" {
  type    = string
  default = "launchpad.pfx"
}

variable "launchpad_passphrase" {
  type    = string
  default = ""
}

variable "oauth_provider" {
  type    = string
  default = "earthdata"
}

variable "oauth_user_group" {
  type    = string
  default = "N/A"
}

variable "data_persistence_remote_state_config" {
  type = object({ bucket = string, key = string, region = string })
}

variable "s3_replicator_config" {
  type        = object({ source_bucket = string, source_prefix = string, target_bucket = string, target_prefix = string })
  default     = null
  description = "Configuration for the s3-replicator module. Items with prefix of source_prefix in the source_bucket will be replicated to the target_bucket with target_prefix."
}

variable "prefix" {
  type = string
}

variable "saml_entity_id" {
  type    = string
  default = "N/A"
}

variable "saml_assertion_consumer_service" {
  type    = string
  default = "N/A"
}

variable "saml_idp_login" {
  type    = string
  default = "N/A"
}

variable "saml_launchpad_metadata_url" {
  type    = string
  default = "N/A"
}

variable "system_bucket" {
  type = string
}

variable "thin_egress_jwt_secret_name" {
  type        = string
  description = "Name of AWS secret where keys for the Thin Egress App JWT encode/decode are stored"
}

variable "urs_client_id" {
  type = string
}

variable "urs_client_password" {
  type = string
}

variable "vpc_id" {
  type = string
}

# Optional

variable "api_gateway_stage" {
  type        = string
  default     = "dev"
  description = "The archive API Gateway stage to create"
}

variable "buckets" {
  type    = map(object({ name = string, type = string }))
  default = {}
}

variable "cumulus_distribution_url" {
  type        = string
  default     = null
  description = "The url of cumulus distribution API Gateway endpoint"
}

variable "tea_distribution_url" {
  type        = string
  default     = null
  description = "The url of TEA API Gateway endpoint"
}

variable "deploy_distribution_s3_credentials_endpoint" {
  description = "Whether or not to include the S3 credentials endpoint in the Thin Egress App"
  type        = bool
  default     = true
}

variable "distribution_url" {
  type    = string
  default = null
}

variable "ecs_cluster_instance_image_id" {
  type        = string
  description = "AMI ID of ECS instances"
  default = null
}

variable "key_name" {
  type    = string
  default = null
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "permissions_boundary_arn" {
  type    = string
  default = null
}

variable "aws_profile" {
  type    = string
  default = null
}

variable "log_api_gateway_to_cloudwatch" {
  type        = bool
  default     = false
  description = "Enable logging of API Gateway activity to CloudWatch."
}

variable "log_destination_arn" {
  type        = string
  default     = null
  description = "Remote kinesis/destination arn for delivering logs. Requires log_api_gateway_to_cloudwatch set to true."
}

variable "api_users" {
  type    = list(string)
  default = []
}

variable "urs_url" {
  description = "The URL of the Earthdata login (URS) site"
  type        = string
  default     = "https://uat.urs.earthdata.nasa.gov"
}

variable "archive_api_port" {
  type    = number
  default = null
}

variable "private_archive_api_gateway" {
  type    = bool
  default = true
}

variable "metrics_es_host" {
  type    = string
  default = null
}

variable "metrics_es_password" {
  type    = string
  default = null
}

variable "metrics_es_username" {
  type    = string
  default = null
}

variable "additional_log_groups_to_elk" {
  type    = map(string)
  default = {}
}

variable "tags" {
  description = "Tags to be applied to Cumulus resources that support tags"
  type        = map(string)
  default     = {}
}

variable "deploy_cumulus_distribution" {
  description = "If true, does not deploy the TEA distribution API"
  type        = bool
  default     = false
}

variable "cloudwatch_log_retention_periods" {
  type = map(number)
  description = "retention periods for the respective cloudwatch log group, these values will be used instead of default retention days"
  default = {
    thin-egress-app-EgressLambda = 7
    ApiEndpoints = 7
    AsyncOperationEcsLogs = 7
    DiscoverPdrs = 7
    DistributionApiEndpoints = 7
    EcsLogs = 7
    granuleFilesCacheUpdater = 7
    HyraxMetadataUpdates = 7
    ParsePdr = 7
    PostToCmr = 7
    PrivateApiLambda = 7
    publishExecutions = 7
    publishGranules = 7
    QueuePdrs = 7
    QueueWorkflow = 7
    replaySqsMessages = 7
    SyncGranule = 7
    UpdateCmrAccessConstraints = 7
  }
}

variable "default_log_retention_days" {
  type = number
  default = 14
  description = "default value that user chooses for their log retention periods"
}
