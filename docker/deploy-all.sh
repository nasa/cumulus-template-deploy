#!/bin/bash
set -e

echo Deploying the RDS cluster

cd deploy/rds-cluster-tf

../../terraform apply -auto-approve -input=false

echo Deploying Data Persistence

cd ../data-persistence-tf

../../terraform apply -auto-approve -input=false

echo deploying Cumulus

cd ../..

sh build/deploy-cumulus.sh