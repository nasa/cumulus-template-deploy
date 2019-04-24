# Create buckets, deploy cumulus, 

# Get our env set
source $PWD/build/env.sh
cd $PWD/deploy/

# Loop through bucket creation
for BUCKETTYPE in internal private protected public; do
   echo "Checking if bucket s3://${STACKNAME}-${BUCKETTYPE} exists..."
   if aws s3api head-bucket --bucket "${STACKNAME}-${BUCKETTYPE}" 2>/dev/null; then
      echo "Bucket s3://${STACKNAME}-${BUCKETTYPE} exists"
   else
      echo "Creating missing bucket s3://${STACKNAME}-${BUCKETTYPE}"
      aws s3 mb s3://${STACKNAME}-${BUCKETTYPE}
   fi
done

export AWSENV="--region=$AWS_DEFAULT_REGION"

# Ugly Hack 
#FIXME
#YUCK
echo " >>> Copying in IAM Template permissions fix hack..."
cp -v ../hacks/cloudformation.template.yml './node_modules/@cumulus/deployment/iam/'

# Deploy IAM stack
echo " >>> Deploying IAM stack"
echo " Running: '$KES cf deploy --kes-folder iam --deployment projectname-IAM --template node_modules/@cumulus/deployment/iam $AWSENV'"
$KES cf deploy --kes-folder iam --deployment projectname-IAM --template node_modules/@cumulus/deployment/iam $AWSENV

# Bomb out if deployment failed.
if [ $? -eq 0 ]; then echo "IAM Deployment was successful"; else echo "IAM Deployment Failed."; exit 1; fi

# Upload iam/cloudformation.yml
cat iam/cloudformation.yml
aws s3 cp iam/cloudformation.yml s3://projectname-dev-internal/iam/cloudformation.yml

# Deploy Cumulus Stack
echo " >>> Deploying Ingest stack"
echo " Running: '$KES cf deploy --kes-folder app --template node_modules/@cumulus/deployment/app --deployment projectname-deployment $AWSENV'"
$KES cf deploy --kes-folder app --template node_modules/@cumulus/deployment/app --deployment projectname-deployment $AWSENV

# Bomb out if deployment failed.
if [ $? -eq 0 ]; then echo "Deployment was successful"; else echo "Stack Deployment Failed."; exit 1; fi

# Grab some output and dump it into the app/.env
API=$(aws apigateway get-rest-apis --query "items[?name=='${STACKNAME}-cumulus-backend'].id" --output=text)
APIROOT=$(echo "https://${API}.execute-api.us-east-1.amazonaws.com/${MATURITY}/")
echo "API=$API" >> app/.env 
echo "APIROOT=$APIROOT" >> app/.env

# Query Stack for SSM Parameter and Update
# This bit is workflow specific. If you don't need dynamic workflow config, you can drop this whole part. 
SSMPARAM=$(aws $AWSENV cloudformation describe-stacks --stack-name=${STACKNAME}-cumulus --query 'Stacks[0].Outputs[?OutputKey==`AppConfig`].OutputValue' --output text)
echo Running "aws $AWSENV ssm put-parameter --name $SSMPARAM --overwrite --type 'String' --value 'cat app/workflow_config.json'"
aws $AWSENV ssm put-parameter --name $SSMPARAM --overwrite --type "String" --value "`cat app/workflow_config.json`"
if [ $? -ne 0 ]; then echo "Could not update SSM Param $SSMPARAM."; exit 1; fi

