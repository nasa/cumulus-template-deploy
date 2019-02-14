FROM debian:stable

#-- Update and install necessary software for our container(s)

RUN apt-get update && apt-get install -y awscli curl gnupg vim git virtualenv python-pip zip && \
    curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get install -y nodejs && \
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash && \
    /bin/bash -c 'source /root/.bashrc && nvm install 8.10 && nvm install 8.11'

#-- App name as input

ARG APPNAME
ENV APPNAME $APPNAME
ENV AWSPROFILE defualt

#-- Clone Deployment from Git and install
RUN git clone https://github.com/nasa/template-deploy $APPNAME-deploy && \
    cd $APPNAME-deploy && \
    npm install && \
    cp -r ./node_modules/@cumulus/deployment/app.example ./app 

#-- Object creation script
RUN echo '#!/bin/bash'                                                                    >  create_aws_objects.sh && \
    echo 'if [ ! -d git/ ]; then mkdir git/; fi'                                          >> create_aws_objects.sh && \
    echo 'echo "... Cloning Cumulus Repo"'                                                >> create_aws_objects.sh && \
    echo 'cd git/ && git clone https://github.com/nasa/template-deploy $APPNAME-deploy'   >> create_aws_objects.sh && \
    echo 'cd $APPNAME-deploy && npm install'                                              >> create_aws_objects.sh && \
    echo 'cp -r ./node_modules/@cumulus/deployment/app.example ./app'                     >> create_aws_objects.sh && \
    echo 'RUN=$(base64 /dev/urandom | tr -d '/+' |  fold -w 8 | head -1)'                 >> create_aws_objects.sh && \
    echo 'STACKNAME=$(echo "${APPNAME}-${RUN}" | tr "[:upper:]" "[:lower:]")'             >> create_aws_objects.sh && \
    echo 'JWTTOKEN=$(base64 /dev/urandom | tr -d '/+' |  fold -w 32 | head -1)'           >> create_aws_objects.sh && \
    echo 'echo "... Run will be $STACKNAME"'                                              >> create_aws_objects.sh && \
    echo 'IF=U1RBQ0tOQU1FLUlBTToKICBwcmVmaXg6IFNUQUNLTkFNRQogIHN0YWNrTmFtZTogU1RBQ0tOQU1FLWlhbXMKICBzeXN0ZW1fYnVja2V0OiB7e2J1Y2tldHMuaW50ZXJuYWwubmFtZX19CiAgdXNlTmdhcFBlcm1pc3Npb25Cb3VuZGFyeTogdHJ1ZQogIGJ1Y2tldHM6CiAgICBpbnRlcm5hbDoKICAgICAgICBuYW1lOiBTVEFDS05BTUUtaW50ZXJuYWwKICAgICAgICB0eXBlOiBpbnRlcm5hbAogICAgcHJpdmF0ZToKICAgICAgICBuYW1lOiBTVEFDS05BTUUtcHJpdmF0ZQogICAgICAgIHR5cGU6IHByaXZhdGUKICAgIHByb3RlY3RlZDogCiAgICAgICAgbmFtZTogU1RBQ0tOQU1FLXByb3RlY3RlZAogICAgICAgIHR5cGU6IHByb3RlY3RlZAogICAgcHVibGljOgogICAgICAgIG5hbWU6IFNUQUNLTkFNRS1wdWJsaWMKICAgICAgICB0eXBlOiBwdWJsaWMK' >> create_aws_objects.sh && \
    echo 'CF="U1RBQ0tOQU1FLWRlcGxveW1lbnQ6CiAgc3RhY2tOYW1lOiBTVEFDS05BTUUtY3VtdWx1cwogIHN0YWNrTmFtZU5vRGFzaDogU1RBQ0tOQU1FQ3VtdWx1cwoKICBhcGlTdGFnZTogZGV2CgogIHZwYzoKICAgIHZwY0lkOiBWUENJRAogICAgc3VibmV0czoKICAgICAgLSBTVUJORVRJRAoKICBlY3M6CiAgICBpbnN0YW5jZVR5cGU6IHQyLm1pY3JvCiAgICBkZXNpcmVkSW5zdGFuY2VzOiAwCiAgICBhdmFpbGFiaWxpdHlab25lOiBTVUJORVRaT05FCgogIGJ1Y2tldHM6CiAgICBpbnRlcm5hbDoKICAgICAgbmFtZTogU1RBQ0tOQU1FLWludGVybmFsCiAgICAgIHR5cGU6IGludGVybmFsCiAgICBwcml2YXRlOgogICAgICBuYW1lOiBTVEFDS05BTUUtcHJpdmF0ZQogICAgICB0eXBlOiBwcml2YXRlCiAgICBwcm90ZWN0ZWQ6CiAgICAgIG5hbWU6IFNUQUNLTkFNRS1wcm90ZWN0ZWQKICAgICAgdHlwZTogcHJvdGVjdGVkCiAgICBwdWJsaWM6CiAgICAgIG5hbWU6IFNUQUNLTkFNRS1wdWJsaWMKICAgICAgdHlwZTogcHVibGljCgogIGlhbXM6CiAgICBlY3NSb2xlQXJuOiBhcm46YXdzOmlhbTo6QUNDT1VOVElEOnJvbGUvU1RBQ0tOQU1FLWVjcwogICAgbGFtYmRhQXBpR2F0ZXdheVJvbGVBcm46IGFybjphd3M6aWFtOjpBQ0NPVU5USUQ6cm9sZS9TVEFDS05BTUUtbGFtYmRhLWFwaS1nYXRld2F5CiAgICBsYW1iZGFQcm9jZXNzaW5nUm9sZUFybjogYXJuOmF3czppYW06OkFDQ09VTlRJRDpyb2xlL1NUQUNLTkFNRS1sYW1iZGEtcHJvY2Vzc2luZwogICAgc3RlcFJvbGVBcm46IGFybjphd3M6aWFtOjpBQ0NPVU5USUQ6cm9sZS9TVEFDS05BTUUtc3RlcHJvbGUKICAgIGluc3RhbmNlUHJvZmlsZTogYXJuOmF3czppYW06OkFDQ09VTlRJRDppbnN0YW5jZS1wcm9maWxlL1NUQUNLTkFNRS1lY3MKICAgIGRpc3RyaWJ1dGlvblJvbGVBcm46IGFybjphd3M6aWFtOjpBQ0NPVU5USUQ6cm9sZS9TVEFDS05BTUUtZGlzdHJpYnV0aW9uLWFwaS1sYW1iZGEKICAgIHNjYWxpbmdSb2xlQXJuOiBhcm46YXdzOmlhbTo6QUNDT1VOVElEOnJvbGUvU1RBQ0tOQU1FLXNjYWxpbmctcm9sZQogICAgbWlncmF0aW9uUm9sZUFybjogYXJuOmF3czppYW06OkFDQ09VTlRJRDpyb2xlL1NUQUNLTkFNRS1taWdyYXRpb24tcHJvY2Vzc2luZwoKCiAgdXJzX3VybDogaHR0cHM6Ly91YXQudXJzLmVhcnRoZGF0YS5uYXNhLmdvdi8gI21ha2Ugc3VyZSB0byBpbmNsdWRlIHRoZSB0cmFpbGluZyBzbGFzaAoKICAjIGlmIG5vdCBzcGVjaWZpZWQgdGhlIHZhbHVlIG9mIHRoZSBhcGlnYXRld2F5IGJhY2tlbmQgZW5kcG9pbnQgaXMgdXNlZAogICMgYXBpX2JhY2tlbmRfdXJsOiBodHRwczovL2FwaWdhdGV3YXktdXJsLXRvLWFwaS1iYWNrZW5kLyAjbWFrZSBzdXJlIHRvIGluY2x1ZGUgdGhlIHRyYWlsaW5nIHNsYXNoCgogICMgaWYgbm90IHNwZWNpZmllZCB0aGUgdmFsdWUgb2YgdGhlIGFwaWdhdGV3YXkgZGlzdCB1cmwgaXMgdXNlZAogICMgYXBpX2Rpc3RyaWJ1dGlvbl91cmw6IGh0dHBzOi8vYXBpZ2F0ZXdheS11cmwtdG8tZGlzdHJpYnV0aW9uLWFwcC8gI21ha2Ugc3VyZSB0byBpbmNsdWRlIHRoZSB0cmFpbGluZyBzbGFzaAoKICAjIFVSUyB1c2VycyB3aG8gc2hvdWxkIGhhdmUgYWNjZXNzIHRvIHRoZSBkYXNoYm9hcmQgYXBwbGljYXRpb24uCiAgdXNlcnM6CiAgICAtIHVzZXJuYW1lOiBVUlNJRAo="' >> create_aws_objects.sh && \
    echo 'EF="Q01SX1VTRVJOQU1FPUNNUlVTUk5BTUUKQ01SX1BBU1NXT1JEPUNNUlBBU1NXT1JECkVBUlRIREFUQV9DTElFTlRfSUQ9RURMQ0xJRU5USUQKRUFSVEhEQVRBX0NMSUVOVF9QQVNTV09SRD1FRExDTElFTlRQV0QKVlBDX0lEPVZQQ0lECkFXU19TVUJORVQ9U1VCTkVUSUQKQVdTX0FDQ09VTlRfSUQ9QUNDT1VOVElEClRPS0VOX1NFQ1JFVD1KV1RUT0tFTgo="'          >> create_aws_objects.sh && \
    echo 'echo "... Making Buckets"'                                                      >> create_aws_objects.sh && \
    echo 'AWSENV=$(echo "--profile $AWSPROFILE --region us-east-1")'                      >> create_aws_objects.sh && \
    echo 'KES=$(echo "./node_modules/.bin/kes")'                                          >> create_aws_objects.sh && \
    echo 'for BN in internal private protected public ; do aws s3 $AWSENV mb s3://${STACKNAME}-${BN}; done'                                         >> create_aws_objects.sh && \
    echo 'echo "... Building IAM template iam/config.yml"'                                >> create_aws_objects.sh && \
    echo 'echo $IF | base64 --decode | sed "s/STACKNAME/${STACKNAME}/g" > iam/config.yml' >> create_aws_objects.sh && \
    echo 'echo "... Deploying IAM Template to AWS"'                                       >> create_aws_objects.sh && \
    echo '$KES cf deploy --kes-folder iam --deployment ${STACKNAME}-IAM --template node_modules/@cumulus/deployment/iam $AWSENV'                    >> create_aws_objects.sh && \
    echo 'echo "... Getting AWS Environment info"'                                        >> create_aws_objects.sh && \
    echo 'VPCID=$(aws $AWSENV ec2 describe-vpcs --query "Vpcs[*].VpcId" --filters "Name=tag:Name,Values=Application VPC" --output text)'            >> create_aws_objects.sh && \
    echo 'SUBNETID=$(aws $AWSENV ec2 describe-subnets --query "Subnets[?VpcId=='"'"'$VPCID'"'"'].{ID:SubnetId}[0]" --filters "Name=tag:Name,Values=Private*" --output=text)'            >> create_aws_objects.sh && \
    echo 'SUBNETZONE=$(aws $AWSENV ec2 describe-subnets --query "Subnets[?VpcId=='"'"'$VPCID'"'"'].{AV:AvailabilityZone}[0]" --filters "Name=tag:Name,Values=Private*" --output=text )' >> create_aws_objects.sh && \ 
    echo 'ACCOUNTID=$(aws $AWSENV sts get-caller-identity --query "Account" --output=text)' >> create_aws_objects.sh && \
    echo 'echo "... Writing out Config file"'                                             >> create_aws_objects.sh && \
    echo 'echo $CF | base64 --decode | sed "s/STACKNAME/${STACKNAME}/g" | sed "s/VPCID/${VPCID}/g" | sed "s/ACCOUNTID/${ACCOUNTID}/g" | sed "s/SUBNETID/${SUBNETID}/g" | sed "s/SUBNETZONE/${SUBNETZONE}/g" | sed "s/URSID/${URSID}/g" | sed "s/\(.*stackNameNoDash.*\)-\\(.*\)/\1\2/g" > app/config.yml'                              >> create_aws_objects.sh && \
    echo 'echo "Writing out URS Auth ENV File"'                                           >> create_aws_objects.sh && \
    echo 'echo $EF | base64 --decode | sed "s/VPCID/${VPCID}/g" | sed "s/SUBNETID/${SUBNETID}/g" | sed "s/ACCOUNTID/${ACCOUNTID}/g" | sed "s/CMRUSRNAME/${CMR_USERNAME}/g" | sed "s/CMRPASSWORD/${CMR_PASSWORD}/g" | sed "s/EDLCLIENTID/${EARTHDATA_CLIENT_ID}/g"| sed "s/EDLCLIENTPWD/$EARTHDATA_CLIENT_PASSWORD/g" | sed "s/JWTTOKEN/${JWTTOKEN}/g" > app/.env' >> create_aws_objects.sh && \
    echo 'echo "... Deploying Cumulus to AWS!"'                                           >> create_aws_objects.sh && \
    echo '$KES cf deploy --kes-folder app --template node_modules/@cumulus/deployment/app --deployment ${STACKNAME}-deployment $AWSENV'             >> create_aws_objects.sh && \
    echo 'echo "... getting API path"'                                                    >> create_aws_objects.sh && \
    echo 'API=$(aws $AWSENV apigateway get-rest-apis --query "items[?name=='"'"'${STACKNAME}-cumulus-backend'"'"'].id" --output=text)' >> create_aws_objects.sh && \
    echo 'APIROOT=$(echo "https://${API}.execute-api.us-east-1.amazonaws.com/dev/")'      >> create_aws_objects.sh && \
    echo 'echo "... Creating Dashboard Website"'                                          >> create_aws_objects.sh && \
    echo 'aws s3 $AWSENV mb s3://${STACKNAME}-dashboard'                                  >> create_aws_objects.sh && \
    echo 'aws s3 $AWSENV website s3://${STACKNAME}-dashboard --index-document index.html' >> create_aws_objects.sh && \
    echo 'echo "... Building Dashboard"'                                                  >> create_aws_objects.sh && \
    echo 'nvm use && npm install -g yarn'                                                 >> create_aws_objects.sh && \
    echo 'cd /git/ && git clone https://github.com/nasa/cumulus-dashboard $APPNAME-dash'  >> create_aws_objects.sh && \
    echo 'cd $APPNAME-dash && nvm use && yarn install'                                    >> create_aws_objects.sh && \
    echo 'sed -i "s|https.*com|$APIROOT|g" app/scripts/config/config.js'                  >> create_aws_objects.sh && \
    echo 'nvm use && yarn run build'                                                      >> create_aws_objects.sh && \
    echo 'echo "... Pushing dashboard to S3"'                                             >> create_aws_objects.sh && \
    echo 'aws $AWSENV s3 sync dist s3://${STACKNAME}-dashboard --acl public-read'         >> create_aws_objects.sh && \
    echo 'echo "... Starting LOCAL Dashboard"'                                            >> create_aws_objects.sh && \
    echo 'yarn serve &'                                                                   >> create_aws_objects.sh && \
    echo 'echo "Done!"'                                                                   >> create_aws_objects.sh && \
    chmod +x create_aws_objects.sh

#-- Keeps ontainers running until we tell them to stop

CMD tail -f /dev/null

######
# To Use:
#
# Name your app:
#
#   > export APPNAME=mytest
# 
# Build it:
#
#   > docker build --build-arg APPNAME=$APPNAME -f Example.dockerfile -t cumex .
# 
# Run it:
# 
#   > IMG=$(docker run -e AWSPROFILE=NGAP -d cumex)
#
#   ... Or pull in local AWS config & Env
# 
#   > echo 'AWSPROFILE=cumulus
#     URSID=YourUrsId
#     CMR_USERNAME=MyCmrUN
#     CMR_PASSWORD=MyCmrPwd
#     EARTHDATA_CLIENT_ID=MyEDLClientId
#     EARTHDATA_CLIENT_PASSWORD=MyEDLClintPwd' > docker.env
#
#   > IMG=$(docker run --env-file docker.env -v ~/.aws/:/root/.aws -d cumex)
# 
#   ... Or expose port 3000/3001 for local Dashboard access
#   
#   > IMG=$(docker run --env-file docker.env -v ~/.aws/:/root/.aws -p 3000:3000/tcp -p 3001:3001/tcp -d cumex)
#  
#   ... Potentially mount *local* git directory to save/reuse code
# 
#   > mkdir -p ~/git/
#   > IMG=$(docker run --env-file docker.env -v ~/git/:/git/ ~/.aws/:/root/.aws -p 3000:3000/tcp -p 3001:3001/tcp -d cumex)
# 
# Visit it:
# 
#   > docker exec -it $IMG /bin/bash
# 
# Build Cumulus ( execute `./create_aws_objects.sh` ): 
#  
#   > root@60df7d8d47b0:/# ./create_aws_objects.sh
#
#
# Do Development:
#
#    After Building, the Cumulus UI will start running locally and will be accessible 
#    in your local browse @ http://localhost:[3000|3001]. If you've mounted a local dir
#    do /git/, you can locally (outide of docker) update your deployment. 
#    
#    If you kill your docker container, you can always resume it by re-running these:
#
#      `docker run ... ` 
#      `docker exec ... ` 
# 
#    Just avoid ever calling `./create_aws_objects.sh` again! Instead, use Kes to 
#    push out your changes. To Restart the dashboard, cd into the Dashboard Repo and:
# 
#      > root@f812def2b82b:/git/APP-dash# nvm use && npm install -g yarn && yarn serve &
# 
#    You UI will again be accessible in your local browser
#   
# Stop it:
# 
#   > docker kill $IMG



