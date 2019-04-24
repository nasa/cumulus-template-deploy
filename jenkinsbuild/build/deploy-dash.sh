# configure and deploy cumulus dashboard

cd $WORKSPACE/dash

# Grab some ENV's we can't get since we're not currently using cumulus creds
eval "$(grep API ../deploy/app/.env)"
eval "$(grep REGION ../deploy/app/.env)"
eval "$(grep STACKNAME ../deploy/app/.env)"

# Setup Dash Bucket
echo "Setup dashboard Bucket"
if aws s3api head-bucket --bucket "${STACKNAME}-dash" 2>/dev/null; then
   echo "Bucket s3://${STACKNAME}-dash exists"
else
   echo "Creating missing bucket s3://${STACKNAME}-dash"
   aws s3 mb s3://${STACKNAME}-dash
   aws s3 website s3://${STACKNAME}-dash --index-document index.html
fi

echo " > Configure Dashboard"
echo "APIROOT will be $APIROOT"
cat app/scripts/config/config.js
sed -i "s|https.*com|$APIROOT|g" app/scripts/config/config.js
cat app/scripts/config/config.js
grep "https" app/scripts/config/config.js
npm run build
if [ $? -ne 0 ]; then echo "Dashboard Configure failed."; exit 1; fi

echo " > Upload Dashboard"
aws s3 cp dist/index.html s3://${STACKNAME}-dash --acl public-read
aws s3 sync dist s3://${STACKNAME}-dash --acl public-read

