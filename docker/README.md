# Deploying a basic Cumulus backend deployment via Docker

The purpose of this is to easily deploy a bare bones Cumulus with minimal configuration. This is meant for prototyping and exploration purposes and not meant to be operational. There will be additional configuration necessary to deploy an operational Cumulus.

This bare bones deployment does not include:
- CMR integration
- NASA Launchpad
- Data direct S3 distribution access
- Locking your Terraform state as you deploy

## Prerequisites

- Docker
- docker-compose (if running Linux)
- Credentials to an NGAP AWS Account (Long Term Access Keys)
- SSH key (https://nasa.github.io/cumulus/docs/deployment/deployment-readme#set-up-ec2-key-pair-optional)
- Earthdata Login username and password
- Earthdata application client id and password

## How to deploy

### Set environment variables

The deployment uses locally defined environment variables to generate all of the variables used for deployments. Define the following variables:

- AWS_ACCOUNT_ID
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_REGION
- PREFIX (the deployment prefix you want to use, there are length limits so keep it on the shorter side)
- EARTHDATA_CLIENT_ID (from the Earthdata application)
- EARTHDATA_CLIENT_PASSWORD
- SSH_KEY (name of your key pair after following these steps: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)
- OPERATOR_API_USER (Your Earthdata Login Id, which will be used to access the API and dashboard)

### Build the docker container

`docker-compose build`

The build command:
- Installs requirements (`requirements.sh`)
- Copies deployment files to the docker container in the /deploy folder
- Sets up your AWS credentials
- Creates a Terraform state bucket if it does not exist
- Initializes the RDS cluster deployment, the data persistence deployment, the data migration deployment, and the cumulus deployment
  - Generates the `terraform.tf` file based on environment variables
  - Generates the `terraform.tfvars` file based on environment variables
  - Runs `terraform init`

After this runs, a bucket named <PREFIX>-tf-state will have been created in your AWS account.

### Initialize a bash shell in your container

`docker-compose run deploy /bin/bash`

This will create a shell running inside your docker container. All subsequent commands should be run from this shell, unless otherwise noted.

### Run one-time setup commands

_Before_ your first deployment, run the following:

`sh build/deployment-one-time-setup.sh`

Using your prefix, this will
- Create buckets:
  - <PREFIX>-internal
  - <PREFIX>-private
  - <PREFIX>-public
  - <PREFIX>-protected
- Create the TEA JWT secret

You will not need to run this on repeat deployments.

Upon completion, you can validate that the above buckets were created in your AWS account.

### Deploy all

`sh build/deploy-all.sh`

This deploys the following deployment layers in order:
- RDS Cluster
- Data persistence - database tables and Elasticsearch
- Data migration
- Cumulus

Deployment output and any errors will be printed to the console.

### Connect to backend API

`sh print-connection-commands.sh`

This will print out something like:
```
# API Connection via tunneling
## Create local port:
aws ssm start-session --target i-000000000000 --document-name AWS-StartPortForwardingSession --parameters portNumber=22,localPortNumber=4343

## Configure with path to keypair and run in a separate terminal to create the tunnel:
ssh -p 4343 -N -L 8000:abcdefghij.execute-api.us-east-1.amazonaws.com:443 ec2-user@localhost -i path/to/keypair

## Add to your /etc/hosts file:
127.0.0.1       abcdefghij.execute-api.us-east-1.amazonaws.com

## Test your endpoint
curl https://abcdefghij.execute-api.us-east-1.amazonaws.com:8000/dev/version

## Add the redirect API to your Earthdata Login application
https://abcdefghij.execute-api.us-east-1.amazonaws.com:8000/dev/token

## APIROOT for your dashboard
APIROOT=https://abcdefghij.execute-api.us-east-1.amazonaws.com:8000/dev/
```

## Inspect your deployment files

_Outside_ of the Docker container, in a separate terminal, run

```
CONTAINER_ID=$(docker ps -alq) && docker cp $CONTAINER_ID:/deploy ./deploy
```

This will copy all of the files used for deployment to a `deploy/` folder so you can view them. These files can be used to configure and update your deployment from your local machine.

## Teardown

To save money and resources, when finished with your Cumulus deployment you can tear it down by running:

`sh build/teardown.sh`

then, upon success:

`sh build/teardown-one-time-setup.sh`

Teardown output can be viewed in the console.

# Scripts

## deploy-all.sh

This deploys the following deployment layers in order:
- RDS Cluster
- Data persistence - database tables and Elasticsearch
- Data migration
- Cumulus

## deploy-cumulus.sh

This just deploys the Cumulus module. The RDS cluster, data persistence, and data migration deployments rarely change, so generally Cumulus is the one that would be redeployed.

## deploy-one-time-setup.sh

Execute one-time setup steps for the deployment.

## teardown.sh

Tears down all resources deployed by `deploy-all.sh`.

## teardown-one-time-setup.sh

Tears down all resources deployed by `build/deployment-one-time-setup.sh`. This is separate from `teardown.sh` to make sure the teardown function is complete before tearing down buckets, particularly the tf-state bucket.

## print-connection-commands.sh

Print the commands needed to connect to your API.

Example:
```
# API Connection via tunneling
## Create local port:
aws ssm start-session --target i-000000000000 --document-name AWS-StartPortForwardingSession --parameters portNumber=22,localPortNumber=4343

## Run in a separate terminal to create the tunnel:
ssh -p 4343 -N -L 8000:abcdefghij.execute-api.us-east-1.amazonaws.com:443 ec2-user@localhost

## Add to your /etc/hosts file:
127.0.0.1       abcdefghij.execute-api.us-east-1.amazonaws.com

## Test your endpoint
curl https://abcdefghij.execute-api.us-east-1.amazonaws.com:8000/dev/version

## Add the redirect API to your Earthdata Login application
https://abcdefghij.execute-api.us-east-1.amazonaws.com:8000/dev/token

## APIROOT for your dashboard
APIROOT=https://abcdefghij.execute-api.us-east-1.amazonaws.com:8000/dev/
```
