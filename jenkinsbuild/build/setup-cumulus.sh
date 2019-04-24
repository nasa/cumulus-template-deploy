# clone, setup, and configure cumulus and its dependancies. A
# some of this is project specific stuff

# move to the right place
cd $WORKSPACE

tree

# Create Cumulus Deployment if it doesn't exists
if [ ! -d ./deploy/ ]; then 
   git clone https://github.com/nasa/template-deploy deploy
   cd deploy 
else 
   cd deploy 
   git pull 
fi

# install? it
cp -r ../package.json ./
npm install

# Create "app-centric" dirs
for DIRNAME in app iam python_modules; do
   if [ ! -d ./$DIRNAME/ ]; then
      mkdir ./$DIRNAME/ 
   else 
      echo "./deploy/$DIRNAME/ exists"
   fi

   # Copy our bits in
   cp -r ../$DIRNAME/* ./$DIRNAME/

done 

# Debug...
echo "Looking for SQS in iam/cloudformation.yml"
grep -i sqs ./iam/cloudformation.yml

# Copy Deployment yamls
cp -r ../*.yml ./

# Build Python stuff
cd python_modules
python2.7 -m pip install --upgrade pip
python2.7 -m pip install -r requirements.txt -t .
cd ..

# Add @cumulus node deps
npm install @cumulus/post-to-cmr --save
npm install @cumulus/queue-granules --save

# Dump ENV:
source ../build/env.sh 
env > app/.env
env > iam/.env
cat app/.env


