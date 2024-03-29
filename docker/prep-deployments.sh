#!/bin/bash
set -e

echo region $AWS_REGION
echo prefix $PREFIX

aws configure set region $AWS_REGION
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY

AWS_ACCOUNT_ID=$(aws sts get-caller-identity | grep "Account" | sed -E 's/.*"([^"]+)",/\1/')

echo Using prefix $PREFIX
INTERNAL_BUCKET=$PREFIX-internal
TFSTATE_BUCKET=$PREFIX-tf-state

# Create the tf state bucket if it does not exist
set +e

aws s3api head-bucket --bucket $TFSTATE_BUCKET

if [[ $? != 0 ]]; then
  echo Creating TF state bucket $TFSTATE_BUCKET
  set -e
  if [[ $AWS_REGION = "us-east-1" ]]; then
    aws s3api create-bucket --bucket $TFSTATE_BUCKET
  else
    aws s3api create-bucket --bucket $TFSTATE_BUCKET --create-bucket-configuration LocationConstraint=$AWS_REGION
  fi
fi

set -e

### SETUP RDS CLUSTER ###

echo Initialize RDS cluster deployment

RDS_CLUSTER_KEY="$PREFIX/rds-cluster/terraform.tfstate"

cd deploy/rds-cluster-tf
echo "terraform {
  backend \"s3\" {
    bucket = \"$TFSTATE_BUCKET\"
    key    = \"$RDS_CLUSTER_KEY\"
    region = \"$AWS_REGION\"
  }
}" >> terraform.tf

# Replace values in main.tf with the values coming from vpcConfig.tf
sed -e 's/var.vpc_id/data.aws_vpc.application_vpcs.id/g' main.tf >> main.tf.tmp && mv main.tf.tmp main.tf
sed -e 's/var.subnets/data.aws_subnet_ids.subnet_ids.ids/g' main.tf >> main.tf.tmp && mv main.tf.tmp main.tf

../../terraform init

prefix_no_dash=$(echo $PREFIX | sed -e 's/-//g')

echo "
  cluster_identifier = \"$PREFIX-cumulus-rds-serverless\"
  db_admin_username = \"$prefix_no_dash"username"\"
  db_admin_password = \"$PREFIX-password\"
  rds_user_password = \"$prefix_no_dash"password"\"
  region = \"$AWS_REGION\"
  deletion_protection = false
  provision_user_database = true
  permissions_boundary_arn = \"arn:aws:iam::$AWS_ACCOUNT_ID:policy/NGAPShNonProdRoleBoundary\"
  prefix     = \"$PREFIX\"
  engine_version = \"10.serverless_14\"
  vpc_id=\"\"
  subnets=[\"\"]
" >> terraform.tfvars

cd ../..

### SETUP DATA PERSISTENCE ###

echo Initialize data persistence deployment

DATA_PERSISTENCE_KEY="$PREFIX/data-persistence/terraform.tfstate"

cd deploy/data-persistence-tf
# Ensure remote state is configured for the deployment
echo "terraform {
  backend \"s3\" {
    bucket = \"$TFSTATE_BUCKET\"
    key    = \"$DATA_PERSISTENCE_KEY\"
    region = \"$AWS_REGION\"
  }
}" >> terraform.tf

# Replace values in main.tf with the values coming from vpcConfig.tf
sed -e 's/var.vpc_id/data.aws_vpc.application_vpcs.id/g' main.tf >> main.tf.tmp && mv main.tf.tmp main.tf
sed -e 's/var.subnet_ids/data.aws_subnet_ids.subnet_ids.ids/g' main.tf >> main.tf.tmp && mv main.tf.tmp main.tf

# Use the RDS cluster outputs for the RDS variables
echo "
  data \"terraform_remote_state\" \"rds_cluster\" {
    backend   = \"s3\"
    config    = {
      bucket = \"$TFSTATE_BUCKET\"
      key    = \"$RDS_CLUSTER_KEY\"
      region = \"$AWS_REGION\"
    }
    workspace = terraform.workspace
  }
" >> main.tf

sed -e 's/var.rds_security_group/lookup(data.terraform_remote_state.rds_cluster.outputs, "security_group_id", "")/g' main.tf >> main.tf.tmp && mv main.tf.tmp main.tf
sed -e 's/var.rds_user_access_secret_arn/lookup(data.terraform_remote_state.rds_cluster.outputs, "user_credentials_secret_arn", "")/g' main.tf >> main.tf.tmp && mv main.tf.tmp main.tf

sed -e 's/var.rds_security_group/lookup(data.terraform_remote_state.rds_cluster.outputs, "security_group_id", "")/g' outputs.tf >> outputs.tf.tmp && mv outputs.tf.tmp outputs.tf
sed -e 's/var.rds_user_access_secret_arn/lookup(data.terraform_remote_state.rds_cluster.outputs, "user_credentials_secret_arn", "")/g' outputs.tf >> outputs.tf.tmp && mv outputs.tf.tmp outputs.tf

../../terraform init

echo "
  aws_region = \"$AWS_REGION\"
  permissions_boundary_arn = \"arn:aws:iam::$AWS_ACCOUNT_ID:policy/NGAPShNonProdRoleBoundary\"
  prefix     = \"$PREFIX\"
  rds_user_access_secret_arn = \"\"
  rds_security_group = \"\"
  vpc_id=\"\"
  subnet_ids=[\"\"]
" >> terraform.tfvars

cd ../..

### SETUP CUMULUS ###

echo Deploying Cumulus

CUMULUS_KEY="$PREFIX/cumulus/terraform.tfstate"
TEA_JWT_SECRET=$PREFIX"_jwt_secret_for_tea"

cd deploy/cumulus-tf

echo "terraform {
  backend \"s3\" {
    bucket = \"$TFSTATE_BUCKET\"
    key    = \"$CUMULUS_KEY\"
    region = \"$AWS_REGION\"
  }
}" >> terraform.tf

# Replace values in main.tf and thin_egress_app.tf with the values coming from vpcConfig.tf
sed -e 's/var.vpc_id/data.aws_vpc.application_vpcs.id/g' main.tf >> main.tf.tmp && mv main.tf.tmp main.tf
sed -e 's/var.lambda_subnet_ids/data.aws_subnet_ids.subnet_ids.ids/g' main.tf >> main.tf.tmp && mv main.tf.tmp main.tf

sed -e 's/var.vpc_id/data.aws_vpc.application_vpcs.id/g' thin_egress_app.tf >> thin_egress_app.tf.tmp && mv thin_egress_app.tf.tmp thin_egress_app.tf
sed -e 's/var.lambda_subnet_ids/data.aws_subnet_ids.subnet_ids.ids/g' thin_egress_app.tf >> thin_egress_app.tf.tmp && mv thin_egress_app.tf.tmp thin_egress_app.tf

../../terraform init

cma_version=$(curl --silent "https://api.github.com/repos/nasa/cumulus-message-adapter/releases/latest" |   # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"v([^"]+)".*/\1/'  )                                  # Pluck JSON value

echo Using CMA version $cma_version to a lambda layer

echo "
  region = \"$AWS_REGION\"
  prefix     = \"$PREFIX\"
  cumulus_message_adapter_version = \"$cma_version\"
  permissions_boundary_arn = \"arn:aws:iam::$AWS_ACCOUNT_ID:policy/NGAPShNonProdRoleBoundary\"
  buckets = {
    internal = {
      name = \"$INTERNAL_BUCKET\"
      type = \"internal\"
    }
    private = {
      name = \"$PREFIX-private\"
      type = \"private\"
    },
    protected = {
      name = \"$PREFIX-protected\"
      type = \"protected\"
    }
    public = {
      name = \"$PREFIX-public\"
      type = \"public\"
    }
  }
  system_bucket = \"$INTERNAL_BUCKET\"
  data_persistence_remote_state_config = {
    bucket = \"$TFSTATE_BUCKET\"
    key    = \"$DATA_PERSISTENCE_KEY\"
    region = \"$AWS_REGION\"
  }
  deploy_to_ngap = true
  archive_api_port = 8000
  private_archive_api_gateway = true
  deploy_distribution_s3_credentials_endpoint = false
  thin_egress_jwt_secret_name = \"$TEA_JWT_SECRET\"
  urs_client_id       = \"$EARTHDATA_CLIENT_ID\"
  urs_client_password = \"$EARTHDATA_CLIENT_PASSWORD\"
  key_name      = \"$SSH_KEY\"
  api_users = [\"$OPERATOR_API_USER\"]
  cmr_environment = \"UAT\"
  cmr_client_id = \"\"
  cmr_password = \"\"
  cmr_provider = \"\"
  cmr_username = \"\"
  vpc_id=\"\"
" >> terraform.tfvars
