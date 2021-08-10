#!/bin/bash
set -e

echo Using prefix $prefix

### CREATE BUCKETS

echo Creating buckets

aws s3api create-bucket --bucket $PREFIX-tf-state --create-bucket-configuration LocationConstraint=$AWS_REGION
aws s3api create-bucket --bucket $PREFIX-internal --create-bucket-configuration LocationConstraint=$AWS_REGION
aws s3api create-bucket --bucket $PREFIX-public --create-bucket-configuration LocationConstraint=$AWS_REGION
aws s3api create-bucket --bucket $PREFIX-private --create-bucket-configuration LocationConstraint=$AWS_REGION
aws s3api create-bucket --bucket $PREFIX-protected --create-bucket-configuration LocationConstraint=$AWS_REGION

### CREATE JWT SECRET FOR TEA ###

echo Creating JWT

TEA_JWT_SECRET=$PREFIX"_jwt_secret_for_tea"

ssh-keygen -N '' -t rsa -b 4096 -m PEM -f ./jwtcookie.key
rsa_priv_key=$(openssl base64 -in jwtcookie.key -A)
rsa_pub_key=$(openssl base64 -in jwtcookie.key.pub -A)

cat << EOL > jwtkeys.json
{
    "rsa_priv_key": "$rsa_priv_key",
    "rsa_pub_key":  "$rsa_pub_key"
}
EOL

echo Storing JWT in secret $TEA_JWT_SECRET

aws secretsmanager create-secret --name $TEA_JWT_SECRET\
    --description "RS256 keys for TEA app JWT cookies" \
    --secret-string file://jwtkeys.json