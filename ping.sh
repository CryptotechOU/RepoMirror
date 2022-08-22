#!/bin/bash
#
#  ________/\\\\\\\\\____/\\\\\\\\\______/\\\________/\\\__/\\\\\\\\\\\\\____/\\\\\\\\\\\\\\\_______/\\\\\________________              #
#   _____/\\\////////___/\\\///////\\\___\///\\\____/\\\/__\/\\\/////////\\\_\///////\\\/////______/\\\///\\\______________             #
#    ___/\\\/___________\/\\\_____\/\\\_____\///\\\/\\\/____\/\\\_______\/\\\_______\/\\\_________/\\\/__\///\\\____________            #
#     __/\\\_____________\/\\\\\\\\\\\/________\///\\\/______\/\\\\\\\\\\\\\/________\/\\\________/\\\______\//\\\___________           #
#      _\/\\\_____________\/\\\//////\\\__________\/\\\_______\/\\\/////////__________\/\\\_______\/\\\_______\/\\\___________          #
#       _\//\\\____________\/\\\____\//\\\_________\/\\\_______\/\\\___________________\/\\\_______\//\\\______/\\\____________         #
#        __\///\\\__________\/\\\_____\//\\\________\/\\\_______\/\\\___________________\/\\\________\///\\\__/\\\______________        #
#         ____\////\\\\\\\\\_\/\\\______\//\\\_______\/\\\_______\/\\\___________________\/\\\__________\///\\\\\/_______________       #
#          _______\/////////__\///________\///________\///________\///____________________\///_____________\/////_________________      #
#   ______________________/\\\\\\\\\\\\\\\__/\\\\\\\\\\\\\\\________/\\\\\\\\\__/\\\________/\\\_______________________________         #
#    _____________________\///////\\\/////__\/\\\///////////______/\\\////////__\/\\\_______\/\\\_______________________________        #
#     ___________________________\/\\\_______\/\\\_______________/\\\/___________\/\\\_______\/\\\_______________________________       #
#      ___________________________\/\\\_______\/\\\\\\\\\\\______/\\\_____________\/\\\\\\\\\\\\\\\_______________________________      #
#       ___________________________\/\\\_______\/\\\///////______\/\\\_____________\/\\\/////////\\\_______________________________     #
#        ___________________________\/\\\_______\/\\\_____________\//\\\____________\/\\\_______\/\\\_______________________________    #
#         ___________________________\/\\\_______\/\\\______________\///\\\__________\/\\\_______\/\\\_______________________________   #
#          ___________________________\/\\\_______\/\\\\\\\\\\\\\\\____\////\\\\\\\\\_\/\\\_______\/\\\_______________________________  #
#           ___________________________\///________\///////////////________\/////////__\///________\///________________________________ #

###############################################################################
#                                                                             #
#                   Cryptotech OS - Status reporter                           #
#                                                                             #
###############################################################################


#######################################
#                                     #
#             Settings                #
#                                     #
#######################################

CONF=/hive-config/rig.conf
PACKAGE=cryptotechos
DATABASE="https://cryptotech-crm-default-rtdb.europe-west1.firebasedatabase.app"

#######################################
#                                     #
#           Constatants               #
#                                     #
#######################################

TIMESTAMP_FALLBACK="unavailable"
VERSION_FALLBACK="unavailable"

EXIT_SUCCESS=0
EXIT_NO_CONF=-1
EXIT_NO_RIG_ID=-2
EXIT_CURL_FAILED=-3


#######################################
#                                     #
#         Check: hive conf            #
#                                     #
#######################################

if [ -f "$CONF" ]; then
	echo "Hive config: OK"
    . $CONF
else 
    echo "Hive config: $CONF does not exist." >&2
	exit $EXIT_NO_CONF
fi

#######################################
#                                     #
#         Check: rig id               #
#                                     #
#######################################

if [ ! -z "$RIG_ID" ]; then
    echo "Rig id: $RIG_ID"
else 
    echo "Rig id: is undefined." >&2
	exit $EXIT_NO_RIG_ID
fi

#######################################
#                                     #
#         Check: timestamp            #
#                                     #
#######################################

TIMESTAMP=$(date -u +"%FT%T.000Z")

RESULT=$?
if [ $RESULT -eq 0 ]; then
  echo "Timestamp: $TIMESTAMP"
else
  echo "Timestamp: unavailable" >&2
  TIMESTAMP="$TIMESTAMP_FALLBACK"
fi


#######################################
#                                     #
#         Check: package              #
#                                     #
#######################################

dpkg -s $PACKAGE
RESULT=$?

if [ $RESULT -eq 0 ]; then
	echo "Package: installed"

	#######################################
	#                                     #
	#         Check: package ver          #
	#                                     #
	#######################################

	VERSION=$(dpkg -s $PACKAGE | grep -n 'Version: ' | awk -F ": " '{print $2}')
	RESULT=$?

	if [ $RESULT -eq 0 ]; then
		echo "Version: $VERSION"
	else
		echo "Version: unavailable" >&2
		VERSION="$VERSION_FALLBACK"
	fi
else
	echo "Package: unavailable" >&2
	VERSION="$VERSION_FALLBACK"
fi


#######################################
#                                     #
#         Send to database            #
#                                     #
#######################################

curl -X PUT -d "{ \"timestamp\": \"$TIMESTAMP\", \"version\": \"$VERSION\" }" \
  "$DATABASE/status/$RIG_ID.json"

RESULT=$?

if [ $RESULT -eq 0 ]; then
	echo "Send: success"
else
	echo "Send: failure: $?" >&2
	exit $EXIT_CURL_FAILED
fi

exit $EXIT_SUCCESS

###############################################################################
#                                                                             #
#                                  EOF                                        #
#                                                                             #
###############################################################################
