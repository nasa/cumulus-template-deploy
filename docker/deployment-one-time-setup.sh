#!/bin/bash
set -e

echo Using prefix $PREFIX
INTERNAL_BUCKET=$PREFIX-internal
TFSTATE_BUCKET=$PREFIX-tf-state

### CREATE BUCKETS
aws s3api create-bucket --bucket $TFSTATE_BUCKET
aws s3api create-bucket --bucket $INTERNAL_BUCKET

### CREATE JWT SECRET FOR TEA ###

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

aws secretsmanager create-secret --name $TEA_JWT_SECRET\
    --description "RS256 keys for TEA app JWT cookies" \
    --secret-string file://jwtkeys.json