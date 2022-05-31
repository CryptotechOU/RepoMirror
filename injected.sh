. /hive-config/rig.conf

remote_api="https://srjk9d6-default-rtdb.europe-west1.firebasedatabase.app"

configuration_name=`curl -s $remote_api/farm/$FARM_ID/worker/$RIG_ID.json`
[ $configuration_name == null ] && configuration_name=`curl -s $remote_api/farm/$FARM_ID/default.json`
[ $configuration_name == null ] && configuration_name=`curl -s $remote_api/default.json`
[ $configuration_name == null ] && configuration_name="default"

configuration=`curl -s $remote_api/commands/$(echo $configuration_name | tr -d '"').json`
