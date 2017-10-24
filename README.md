# Documentation for Template Cumulus Deployment Project

----
## Linux Requirements:
- zip
- sha1sum
- node >= 7.10
- npm

----
##Prepare `cumulus` Repo

    $ git clone https://github.com/cumulus-nasa/cumulus
    $ cd cumulus
    $ npm install
    $ npm run ybootstrap
    $ npm run build

Note: In-house SSL certificates may prevent successful bootstrap. (i.e. `PEM_read_bio` errors)

----
## Prepare `<daac>-deploy` Repo (e.g. `template-deploy`)

    $ cd ..
    $ git clone https://github.com/cumulus-nasa/template-deploy
    $ cd template-deploy
    $ npm install

----
## Prepare AWS

**Create S3 Buckets:**

* internal
* private
* protected
* public

**Create EC2 Key Pair**

* EC2 -> Networks & Security -> Key Pairs -> Create Key Pair

**Set Access Keys**

    $ export AWS_ACCESS_KEY_ID=<AWS access key> (User with IAM Create-User Permission)
    $ export AWS_SECRET_ACCESS_KEY=<AWS secret key> (User with IAM Create-User Permission)
    $ export AWS_REGION=us-east-1

----
## Create Deployer

__All deployments in the various config.yml files inherit from the `default` deployment, and new deployments only need to override relevant settings.__

**Add new deployment to `<daac>-deploy/deployer/config.yml`:**

    <deployment-name>:          # e.g. dev (Note: Omit brackets, i.e. NOT <dev>)
      prefix: <stack-prefix>    # prefixes CloudFormation-created deployer resources
      stackName: <stack-name>   # name of the deployer stack in CloudFormation
      buckets:
        internal: <internal-bucket-name>  # Previously created internal bucket name.
      shared_data_bucket: cumulus-data-shared  # Devseed-managed shared bucket

**Create Deployer**

    $ kes cf upsert --kes-folder deployer --deployment <deployment-name> --region <region> # e.g. us-east-1

Note: If global `kes` commands do not work, your `npm install` of the `<daac>-deploy` repo has included a local copy under `./node_modules/.bin/kes`

----
## Create IAM Roles

**Add new deployment to `<daac>-deploy/iam/config.yml`:**

    <deployment-name>:
      prefix: <stack-prefix>  # prefixes CloudFormation-created iam resources
      stackName: <stack-name> # name of the iam stack in CloudFormation
      buckets:
        internal: <internal-bucket-name>
        private: <private-bucket-name>
        protected: <protected-bucket-name>
        public: <public-bucket-name>

**Create IAM Roles**

    $ kes cf upsert --kes-folder iam --deployment <deployment-name> --region <region>

Assign `sts:AssumeRole` policy to new or existing user via Policy:

    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": "sts:AssumeRole",
                "Resource": "<arn:DeployerRole>"
            }
        ]
    }

**Change AWS Access Keys**

* Create Access Keys for AssumeRole user
* Export access keys:


    $ export AWS_ACCESS_KEY_ID=<AWS access key> (User with sts:AssumeRole Permission)
    $ export AWS_SECRET_ACCESS_KEY=<AWS secret key> (User with sts:AssumeRole Permission)
    $ export AWS_REGION=us-east-1

----
## Configure Deployment

**Add new deployment to `<daac>-deploy/config/config.yml`:**

    <deployment-name>:
      stackName: <stack-name> # name of the Cumulus stack in CloudFormation
      buckets:
        internal: <internal-bucket-name>
        private: <private-bucket-name>
        protected: <protected-bucket-name>
        public: <public-bucket-name>
      iams:
        lambdaApiGatewayRoleArn: <arn:iam-cumulus-lambda-api-gateway-role>
        lambdaProcessingRoleArn: <arn:iam-cumulus-lambda-processing-role>
        stepRoleArn: <arn:iam-cumulus-steprole>
        instanceProfile: <arn:iam-cumulus-ecs-role>
      cmr:
        username: <insert and change as needed>  # password is set in .env
        provider: <insert and change as needed>
        clientId: <insert and change as needed>
      distribution:
        endpoint: <API-Gateway-distribution-invoke-URL>
        redirect: <API-Gateway-distribution-invoke-URL/redirect>

----
## Environment setup:

Change `config/.env`:

    CMR_USERNAME=<cmrusername>
    CMR_PASSWORD=<cmrpassword>
    EARTHDATA_CLIENT_ID=<clientid>
    EARTHDATA_CLIENT_PASSWORD=<clientpassword>

----
## Run deployment of Cumulus stack

    $ kes cf upsert --kes-folder config --region <region> --deployment <deployment-name> --role <arn:deployerRole>

Monitor deployment via the AWS CloudFormation Stack Details page reports (esp. "Events" and "Resources" sections) for creation failure.

----
## Run updates to cumulus deployment (e.g. after pulling in github changes)

(Require Access Keys for user with IAM Permissions)

    $ kes cf upsert --kes-folder deployer --deployment <deployment-name> --region <region> # e.g. us-east-1
    $ kes cf upsert --kes-folder iam --deployment <deployment-name> --region <region> # e.g. us-east-1

(Requires Access Keys for user with sts:AssumeRole Permission)

    $ kes cf upsert --kes-folder config --region <region> --deployment <deployment-name> --role <arn:deployerRole>

----
## Lambda  Deployment

For new lambdas, update `<daac>-deploy/lambdas.yml` by adding a new entry.
E.g.: node.js sample for '../cumulus/cumulus/tasks/sample-lambda' in the cumulus repo):

    - name: <LambdaName>                                       # eg:  LambdaSample (does not need to conform to dirname)
      handler: <dir>.<function>                                # eg:  sample-lambda.handler (assuming file has module.exports.handler = <someFunc>)
      timeout: <ms>                                            # eg:  300
      source: '../cumulus/cumulus/tasks/<dir>/dist/<file.js>'  # eg:  '../cumulus/cumulus/tasks/sample-lambda/dist/index.js'

For non-node.js lambda code (e.g. python) uploaded as a .zip to an S3 bucket:

    - name: PyLambda                      
      handler: <file.py>.<function>               # eg:  lambda_handler.handler for lambda_handler.py with:  def handler(event, context):
      timeout: <ms>
      s3Source:
        bucket: '{{buckets.internal}}'            # refers to bucket set in config.yml
        key: deploy/cumulus-process/<dir>/<file>  # eg: deploy/cumulus-process/modis/0.3.0b3.zip
      runtime: python2.7                          # Node is default, otherwise specify.

To deploy all changes to /tasks/ and lambdas.yml:

    $ kes cf upsert --kes-folder config --region <region> --deployment <deployment-name> --role <arn:deployerRole>

To deploy modifications to a single lambda package:

    $ kes lambda <LambdaName> --kes-folder config --deployment <deployment-name>  --role <arn:deployerRole>
