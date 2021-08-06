#!/bin/bash
echo Cleaning up deployment for prefix $PREFIX

### TEARDOWN CUMULUS ###

echo Tearing down Cumulus

cd deploy/cumulus-tf

../../terraform destroy -auto-approve -input=false

### TEARDOWN TEA SECRET ###

aws secretsmanager delete-secret --secret-id $PREFIX"_jwt_secret_for_tea" --force-delete-without-recovery

### TEARDOWN DATA MIGRATION ###

echo Tearing down Data Migration

cd ../data-migration1-tf

../../terraform destroy -auto-approve -input=false

### TEARDOWN DATA PERSISTENCE ###

echo Tearing down Data Persistence

# Use a separate directory with no configuration to work around prevent_destroy lifecycle config
mkdir ../data-persistence-delete
cd ../data-persistence-delete

TFSTATE_BUCKET=$PREFIX-tf-state
DATA_PERSISTENCE_KEY="$PREFIX/data-persistence/terraform.tfstate"

# Ensure remote state is configured for the deployment
echo "terraform {
  backend \"s3\" {
    bucket = \"$TFSTATE_BUCKET\"
    key    = \"$DATA_PERSISTENCE_KEY\"
    region = \"$AWS_REGION\"
  }
}" >> terraform.tf

# Initialize remote state and apply empty configuration
../../terraform init
../../terraform apply -auto-approve -input=false

### TEARDOWN RDS CLUSTER ###

echo Tearing down the RDS cluster

cd ../rds-cluster-tf

../../terraform destroy -auto-approve -input=false

### TEARDOWN BUCKETS ###

aws s3 rb s3://$PREFIX-tf-state --force
aws s3 rb s3://$PREFIX-internal --force
aws s3 rb s3://$PREFIX-public --force
aws s3 rb s3://$PREFIX-private --force
aws s3 rb s3://$PREFIX-protected --force

### TEARDOWN CLEANUP ###

rm -rf ../data-persistence-delete
