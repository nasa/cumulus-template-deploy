#!/bin/bash
set -e

ec2_instance_id=$(aws ec2 describe-instances --filters "Name=tag:Deployment,Values=[$PREFIX]" "Name=instance-state-name,Values=running" | jq -r ".Reservations[0].Instances[].InstanceId")

cd deploy/cumulus-tf

api_gateway_uri=$(../../terraform output | grep "archive_api_uri" | sed 's/.* = \(.*\)/\1/')

api_gateway=$(../../terraform output | grep "archive_api_uri" | sed 's/.*https:\/\/\(.*\):.*/\1/')

api_gateway_redirect_uri=$(../../terraform output | grep "archive_api_redirect_uri" | sed 's/.* = \(.*\)/\1/')

echo "
# API Connection via tunneling
## Create local port:
aws ssm start-session --target $ec2_instance_id --document-name AWS-StartPortForwardingSession --parameters portNumber=22,localPortNumber=4343

## Configure with path to keypair and run in a separate terminal to create the tunnel:
ssh -p 4343 -N -L 8000:$api_gateway:443 ec2-user@localhost -i path/to/keypair

## Add to your /etc/hosts file:
127.0.0.1       $api_gateway

## Test your endpoint
curl "$api_gateway_uri"version

## Add the redirect API to your Earthdata Login application
$api_gateway_redirect_uri

## APIROOT for your dashboard
APIROOT=$api_gateway_uri
"
