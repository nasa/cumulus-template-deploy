#!/bin/bash
set -e

echo Cleaning up deployment for prefix $PREFIX

### TEARDOWN CUMULUS ###

echo Tearing down Cumulus

cd deploy/cumulus-tf

../../terraform destroy -auto-approve -input=false


### TEARDOWN TEA SECRET ###

aws secretsmanager delete-secret --secret-id $PREFIX"_jwt_secret_for_tea"

### TEARDOWN DATA MIGRATION ###

echo Tearing down Data Migration

cd ../data-migration1-tf

../../terraform destroy -auto-approve -input=false

### TEARDOWN DATA PERSISTENCE ###

echo Tearing down Data Persistence

set +e
cd ../data-persistence-tf

../../terraform destroy -auto-approve -input=false

# Manually delete the Dynamo tables
aws dynamodb delete-table --table-name $PREFIX-AccessTokensTable
aws dynamodb delete-table --table-name $PREFIX-AsyncOperationsTable
aws dynamodb delete-table --table-name $PREFIX-CollectionsTable
aws dynamodb delete-table --table-name $PREFIX-ExecutionsTable
aws dynamodb delete-table --table-name $PREFIX-FilesTable
aws dynamodb delete-table --table-name $PREFIX-GranulesTable
aws dynamodb delete-table --table-name $PREFIX-PdrsTable
aws dynamodb delete-table --table-name $PREFIX-ProvidersTable
aws dynamodb delete-table --table-name $PREFIX-ReconciliationReportsTable
aws dynamodb delete-table --table-name $PREFIX-RulesTable
aws dynamodb delete-table --table-name $PREFIX-SemaphoresTable

# Manually delete ES domain
aws es delete-elasticsearch-domain --domain-name $PREFIX-es-vpc
set -e


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
