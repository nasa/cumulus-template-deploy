# Deploy providers/collection/rules json files using Cumulus API
# Requires VPN access

# until this is Jenkinized
source ../app/.env

# Stack Setup
STACKNAME=projectname-${MATURITY}
if [ -z "$MATURITY" ]; then echo "No MATURITY Provided"; exit 1; fi
if [ -z "$AWSPROFILE" ]; then echo "No AWSPROFILE Provided"; exit 1; fi
AWSENV="--profile=$AWSPROFILE --region=$AWS_DEFAULT_REGION"
API=$(aws apigateway get-rest-apis --query "items[?name=='${STACKNAME}-cumulus-backend'].id" --output=text $AWSENV)
CUMULUS_BASEURL=$(echo "https://${API}.execute-api.${AWS_DEFAULT_REGION}.amazonaws.com/${MATURITY}")
if [ ${#API} -le 4 ]; then echo "Could not figure out API AWS for $STACKNAME using profile $AWSPROFILE" ; exit 1; fi

# Get the token URL
ORIGIN=$(dirname $CUMULUS_BASEURL)
LOGIN_URL="$CUMULUS_BASEURL/token"
BACKEND_URL="$CUMULUS_BASEURL/v1"

# create a base64 hash of your login credentials
AUTH=$(printf "$EARTHDATA_USERNAME:$EARTHDATA_PASSWORD" | base64)

# Request the Earthdata url with client id and redirect uri to use with Cumulus
echo ">>> Attempting auth @ ${LOGIN_URL}"
AUTHORIZE_URL=$(curl -s -i ${LOGIN_URL} | grep location | sed -e "s/^location: //");
if [ -z "$AUTHORIZE_URL" ]; then echo "Could not contact Auth API; CHECK VPN!"; exit 1; fi

# Request an authorization grant code
TOKEN_URL=$(curl -s -i -X POST \
  -F "credentials=${AUTH}" \
  -H "Origin: ${ORIGIN}" \
  ${AUTHORIZE_URL%$'\r'} | grep Location | sed -e "s/^Location: //")

# Request the token through the CUMULUS API url that's returned from Earthdata
TOKEN=$(curl -s ${TOKEN_URL%$'\r'} | sed 's/.*\"token\"\:\"\(.*\)\".*/\1/')
if [ ${#TOKEN} -le 10 ]; then echo "Could not get TOKEN for API Access" ; exit 1; fi
TH="--header 'Authorization: Bearer $TOKEN'"
echo ">>> Bearer token was: ${TOKEN:0:10}..."

for TYPE in providers rules collections; do 
    T_PATH=../config/$TYPE/
    echo ">>> Processing $TYPE from $T_PATH"
    for OBJECT in `ls -1 $T_PATH`; do 
    echo ">>> checking out ${TYPE}: $OBJECT"

        # Figure out the unique id         
        if [[ $TYPE =~ .*providers.* ]]; then
            ID=$(cat ${T_PATH}$OBJECT | grep '"id"' | sed 's/.*\"id\"\:[^\"]*\"\([^\"]*\)\".*/\1/')
        else
            ID=$(cat ${T_PATH}$OBJECT | grep '"name"' | sed 's/.*\"name\"\:[^\"]*\"\([^\"]*\)\".*/\1/')
        fi

        if [[ $TYPE =~ .*collection.* ]]; then
            # need to know the Version for collections
            VERSION=$(cat ${T_PATH}$OBJECT | grep '"version"' | sed 's/.*\"version\"\:[^\"]*\"\([^\"]*\)\".*/\1/')
            ID="${ID}/${VERSION}"
        fi

        URL=$BACKEND_URL/$TYPE/$ID

        # Check if this Object exists
        CREATED=$(eval $( echo curl -s $TH ${URL} ) | grep createdAt)
        if [[ $CREATED =~ .*createdAt.* ]]; then
            # Do an update
            URL=$BACKEND_URL/$TYPE/$ID
            echo ">>> Updating $TYPE ID:${ID} @ $BACKEND_URL/$TYPE/$ID"
            TH2='--header "Content-Type: application/json"'
            # echo curl -s --request PUT $TH $TH2 $URL -d @${T_PATH}$OBJECT
            UPDATEDOBJECT=$(eval $( echo curl -s --request PUT $TH $TH2 $URL -d @${T_PATH}$OBJECT ) )
            if [[ $UPDATEDOBJECT =~ .*createdAt.* ]]; then
                echo ">>> $ID Successfully Updated: $UPDATEDOBJECT"
            else
                echo ">>> Failed to update $type $ID: $UPDATEDOBJECT"
                exit 1;
            fi
        else
            # Do a Put
            echo ">>> Creating $type $ID"
            URL=$BACKEND_URL/$TYPE
            TH2='--header "Content-Type: application/json"'
            # echo curl -s --request POST $TH $TH2 $URL -d @${T_PATH}$OBJECT
            NEWOBJECT=$(eval $( echo curl -s --request POST $TH $TH2 $URL -d @${T_PATH}$OBJECT ) )
            if [[ $NEWOBJECGT =~ .*createdAt.* ]]; then
                echo ">>> $ID Successfully Created: $NEWOBJECT"
            else
                echo ">>> Failed to create $TYPE $ID: $NEWOBJECT"
                exit 1;
            fi
        fi
    done
done
