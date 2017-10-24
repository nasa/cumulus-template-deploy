#!/bin/sh

set -evx

DOCKER_UID=$(id -u)
DOCKER_GID=$(id -g)

mkdir -p tmp
cat > tmp/build.sh <<EOS
#!/bin/sh

set -evx

apt-get update
apt-get install -y \
  git \
  rsync

rsync -a --exclude node_modules --exclude .git /source/cumulus/ /build/cumulus/
rsync -a --exclude node_modules --exclude .git /source/template-deploy/ /build/template-deploy/

(
  set -evx
  cd /build/cumulus
  npm install
  npm run ybootstrap
  npm run build
)

(
  set -evx
  cd /build/template-deploy
  npm install
)

tar -czf /dist/release.tgz --exclude tmp/build.sh -C /build cumulus template-deploy
chown "${DOCKER_UID}:${DOCKER_GID}" /dist/release.tgz
EOS
chmod +x tmp/build.sh

mkdir -p dist build

set +e
docker run \
  --rm \
  --volume=$(pwd)/../:/source:ro \
  --volume=$(pwd)/build:/build \
  --volume=$(pwd)/dist:/dist \
  node:6-slim /source/template-deploy/tmp/build.sh
RESULT="$?"
set -e

docker run \
  --rm \
  --volume=$(pwd):/template-deploy \
  node:6-slim rm -rf /template-deploy/build

exit "$RESULT"
