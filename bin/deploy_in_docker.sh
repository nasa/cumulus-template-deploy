#!/bin/sh

set -evx

[ "$bamboo_AWS_ACCESS_KEY_ID" == "" ] && echo "bamboo_AWS_ACCESS_KEY_ID must be set" >&2 && exit 1
[ "$bamboo_AWS_DEFAULT_REGION" == "" ] && echo "bamboo_AWS_DEFAULT_REGION must be set" >&2 && exit 1
[ "$bamboo_AWS_SECRET_ACCESS_PASSWORD" == "" ] && echo "bamboo_AWS_SECRET_ACCESS_PASSWORD must be set" >&2 && exit 1
[ "$bamboo_CMR_CLIENT_ID" == "" ] && echo "bamboo_CMR_CLIENT_ID must be set" >&2 && exit 1
[ "$bamboo_CMR_PASSWORD" == "" ] && echo "bamboo_CMR_PASSWORD must be set" >&2 && exit 1
[ "$bamboo_CMR_PROVIDER" == "" ] && echo "bamboo_CMR_PROVIDER must be set" >&2 && exit 1
[ "$bamboo_CMR_USERNAME" == "" ] && echo "bamboo_CMR_USERNAME must be set" >&2 && exit 1
[ "$bamboo_cumulus_user_password" == "" ] && echo "bamboo_cumulus_user_password must be set" >&2 && exit 1
[ "$bamboo_EARTHDATA_CLIENT_ID" == "" ] && echo "bamboo_EARTHDATA_CLIENT_ID must be set" >&2 && exit 1
[ "$bamboo_EARTHDATA_CLIENT_PASSWORD" == "" ] && echo "bamboo_EARTHDATA_CLIENT_PASSWORD must be set" >&2 && exit 1
[ "$bamboo_STAGE" == "" ] && echo "bamboo_STAGE must be set" >&2 && exit 1

cat > config/.env <<EOS
cumulus_user_password=${bamboo_cumulus_user_password}
CMR_USERNAME=${bamboo_CMR_USERNAME}
CMR_CLIENT_ID=${bamboo_CMR_CLIENT_ID}
CMR_PASSWORD=${bamboo_CMR_PASSWORD}
CMR_PROVIDER=${bamboo_CMR_PROVIDER}
EARTHDATA_CLIENT_ID=${bamboo_EARTHDATA_CLIENT_ID}
EARTHDATA_CLIENT_PASSWORD=${bamboo_EARTHDATA_CLIENT_PASSWORD}
EOS

mkdir -p tmp
cat > tmp/deploy.sh <<EOS
#!/bin/sh

apt-get update
apt-get install -y \
  rsync \
  zip

mkdir -p /work
rsync -a /release/ /work/

(
  set -evx
  cd /work/template-deploy
  ./node_modules/.bin/kes cf update \
    --stage $bamboo_STAGE \
    --kes-class config/kes.js \
    --kes-folder config \
    --region ${bamboo_AWS_DEFAULT_REGION}
)
EOS
chmod +x tmp/deploy.sh

docker run \
  --rm \
  --env "AWS_ACCESS_KEY_ID=${bamboo_AWS_ACCESS_KEY_ID}" \
  --env "AWS_SECRET_ACCESS_KEY=${bamboo_AWS_SECRET_ACCESS_PASSWORD}" \
  --env "AWS_DEFAULT_REGION=${bamboo_AWS_DEFAULT_REGION}" \
  --volume=$(pwd)/../:/release:ro \
  node:slim /release/template-deploy/tmp/deploy.sh
