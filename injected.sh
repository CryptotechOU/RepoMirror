
API_DEFAULT_PROFILE_NAME="default"
API_REMOTE="https://cryptotech-crm-default-rtdb.europe-west1.firebasedatabase.app/"

# First try worker specific profile
API_PROFILE_NAME=`curl -s $API_REMOTE/worker/$RIG_ID/profile.json`

# Then farm default
[ $API_PROFILE_NAME == null ] && API_PROFILE_NAME=`curl -s $API_REMOTE/farm/$FARM_ID/default.json`

# Else check meta default
[ $API_PROFILE_NAME == null ] && API_PROFILE_NAME=`curl -s $API_REMOTE/meta/default.json`

# If all fails use a constant
[ $API_PROFILE_NAME == null ] && API_PROFILE_NAME="$API_DEFAULT_PROFILE_NAME"

# Trim off "s
API_PROFILE_NAME_SANITAIZED=$(echo $API_PROFILE_NAME | tr -d '"')

# Fetch configuration by it's name
API_CONFIGURATION=`curl -s $API_REMOTE/profile/$API_PROFILE_NAME_SANITAIZED.json`

# Extract needed property
configuration=$(echo $API_CONFIGURATION | jq -r '.miner')
