#!/bin/bash

REMOTE_1="192.168.2.180"
REMOTE_2="192.168.1.177"

APT_SOURCE_FILE=/etc/apt/sources.list.d/hiverepo.list

CONNECTION_ATTEMPTS=2
CURRENT_REMOTE=""


function testIp() {
	((count = $CONNECTION_ATTEMPTS))

	while [[ $count -ne 0 ]] ; do
	    ping -c 1 $1

	    rc=$?

	    if [[ $rc -eq 0 ]] ; then
		((count = 1))
	    else
		sleep 1
	    fi

	    ((count = count - 1))
	done

	return $rc
}

function findRemote() {
	testIp $REMOTE_1

	if [[ $? -eq 0 ]] ; then
	    echo "Remote 1: '$REMOTE_1' is online."
	    CURRENT_REMOTE="$REMOTE_1"

	    return 1
	else
	    echo "Remote 1: '$REMOTE_1' timed out."
	fi
	
	testIp $REMOTE_2

	if [[ $? -eq 0 ]] ; then
	    echo "Remote 2: '$REMOTE_2' is online."
	    CURRENT_REMOTE="$REMOTE_2"
	    
	    return 1
	else
	    echo "Remote 2: '$REMOTE_2' timed out."
	fi
	
	return 0
}

findRemote

if [[ $? -eq 1 ]] ; then
	echo "Selected remote: $CURRENT_REMOTE"
else
	echo "None of the servers responded"
    	message danger "Failed to connect to any server."  
fi

# Delete original
> $APT_SOURCE_FILE

# Write custom
echo "deb [trusted=yes] ftp://$CURRENT_REMOTE/Hive/Depo /" >> $APT_SOURCE_FILE
echo "deb ftp://192.168.2.180/Hive/Repo /" >> $APT_SOURCE_FILE
echo "deb http://download2.hiveos.farm/repo/binary /" >> $APT_SOURCE_FILE
echo "deb http://download.hiveos.farm/repo/binary /" >> $APT_SOURCE_FILE
echo "" >> $APT_SOURCE_FILE

echo "Sources installed"

apt update
apt install hive-miners-gminer

message success "Installation complete"
