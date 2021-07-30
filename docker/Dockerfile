FROM python:3.7

ARG AWS_ACCESS_KEY_ID
ARG AWS_ACCOUNT_ID
ARG AWS_REGION
ARG AWS_SECRET_ACCESS_KEY
ARG PREFIX
ARG EARTHDATA_CLIENT_ID
ARG EARTHDATA_CLIENT_PASSWORD
ARG SSH_KEY
ARG OPERATOR_API_USER

COPY .terraform-version /build/
COPY docker/requirements.sh /build/
COPY docker/deployment-one-time-setup.sh /build/
COPY docker/prep-deployments.sh /build/
COPY docker/deploy-cumulus.sh /build/
COPY docker/teardown.sh /build/
COPY docker/deploy-all.sh /build/
COPY docker/print-connection-commands.sh /

RUN apt-get update
RUN apt-get -y install vim-tiny
RUN apt-get -y install jq
RUN bash /build/requirements.sh

COPY rds-cluster-tf/ /deploy/rds-cluster-tf
COPY docker/vpcConfigMultiAz.tf /deploy/rds-cluster-tf

COPY data-persistence-tf/ /deploy/data-persistence-tf
COPY docker/vpcConfig.tf /deploy/data-persistence-tf

COPY data-migration1-tf/ /deploy/data-migration1-tf
COPY docker/vpcConfig.tf /deploy/data-migration1-tf

COPY cumulus-tf/ /deploy/cumulus-tf
COPY docker/vpcConfig.tf /deploy/cumulus-tf

RUN bash /build/prep-deployments.sh


