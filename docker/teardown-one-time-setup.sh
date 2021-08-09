#!/bin/bash
set -e

### TEARDOWN TEA SECRET ###

echo Cleaning up TEA secret for prefix $PREFIX

aws secretsmanager delete-secret --secret-id $PREFIX"_jwt_secret_for_tea" --force-delete-without-recovery

### TEARDOWN BUCKETS ###

echo Cleaning up buckets for prefix $PREFIX

aws s3 rb s3://$PREFIX-tf-state --force
aws s3 rb s3://$PREFIX-internal --force
aws s3 rb s3://$PREFIX-public --force
aws s3 rb s3://$PREFIX-private --force
aws s3 rb s3://$PREFIX-protected --force