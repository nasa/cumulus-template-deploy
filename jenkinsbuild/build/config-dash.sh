# Clone/update cumulus dashboard

cd $WORKSPACE
echo "working in " `pwd`

# Grab some ENV's we can't get since we're not currently using cumulus creds
eval "$(grep API deploy/app/.env)"
eval "$(grep REGION deploy/app/.env)"
eval "$(grep STACKNAME deploy/app/.env)"

echo "Our env is:"
env

echo "Setting up dashboard repo"
if [ ! -d ./dash/ ]; then
   git clone https://github.com/nasa/cumulus-dashboard dash
   cd dash
else
   cd dash
   git reset --hard
   git pull
fi

