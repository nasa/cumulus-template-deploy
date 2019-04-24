# Create some required ENV to be used as part of the deployment

# Cumulus Deployment
export STACKNAME=sirc-ingest-${MATURITY}
export KES=$(echo "./node_modules/.bin/kes")
export deploy=$(echo "$KES cf deploy --kes-folder app --template node_modules/@cumulus/deployment/app --deployment ${STACKNAME}-deployment $AWSENV")

# AWS lookups
export VPCID=$(aws $AWSENV ec2 describe-vpcs --query "Vpcs[*].VpcId" --filters "Name=tag:Name,Values=Application VPC" --output text)
export SUBNETID=$(aws $AWSENV ec2 describe-subnets --query "Subnets[?VpcId=='$VPCID'].{ID:SubnetId}[0]" --filters "Name=tag:Name,Values=Private*" --output=text)
export SUBNETZONE=$(aws $AWSENV ec2 describe-subnets --query "Subnets[?VpcId=='$VPCID'].{AV:AvailabilityZone}[0]" --filters "Name=tag:Name,Values=Private*" --output=text )
export AWS_ACCOUNT_ID=$(aws $AWSENV sts get-caller-identity --query "Account" --output=text)
