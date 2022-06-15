#!/bin/bash

BASE_DIRECTORY="/volume1/Hive"
ORIGINAL_DIRECTORY="$BASE_DIRECTORY/Repo"
UPDATED_DIRECTORY="$BASE_DIRECTORY/Depo"
TEMP_DIRECTORY="$BASE_DIRECTORY/tmp"

INJECTED_CODE="/volume1/Hive/Scripts/injected.sh"

function package_cleanup() {
	echo "[PACKAGE] [CLEANUP] Starting: $TEMP_DIRECTORY"

	rm -rf $TEMP_DIRECTORY

	code=$?

	if [[ $code -ne 0 ]]; then
		echo "Failure: $code"

		exit 1
	fi
}

function package_extract() {
	echo "[PACKAGE] [EXTRACT] Starting: $1"

	dpkg-deb -R $ORIGINAL_DIRECTORY/$1 $TEMP_DIRECTORY

	code=$?

	if [[ $code -ne 0 ]]; then
		echo "Failure: $code"

		package_cleanup
		exit 1
	else
		echo "[PACKAGE] [EXTRACT] Done"
	fi
}

function package_alter() {
	target=$TEMP_DIRECTORY/hive/miners/gminer/h-run.sh

	gminer_call_line=`cat $target | grep -n ^./gminer | awk -F':' '{ printf $1 }'`

	echo "[PACKAGE] [ALTER] Gminer call is on line: $gminer_call_line"

	sed -e "${gminer_call_line}s/$/ \$(echo \$configuration)/" $target > /tmp/temp.txt
	mv /tmp/temp.txt $target

	cat $target | head -n $((gminer_call_line - 1)) > /tmp/temp.txt
	cat $INJECTED_CODE >> /tmp/temp.txt
	cat $target | tail -n $((2)) >> /tmp/temp.txt

	mv /tmp/temp.txt $target
}

function package_reversion() {
	control="$TEMP_DIRECTORY/DEBIAN/control"

	current_version_full=`awk -F'Version: ' '{ printf $2 }' $control`
	current_version=`echo $current_version_full | awk -F'0.6-' '{ printf $2 }'`
	echo "[PACKAGE] [REVERSION] Current version: $current_version_full"

	new_version=$((current_version + 1000))
	new_version_full="0.6-$new_version"
	echo "[PACKAGE] [REVERSION] New version: $new_version_full"

	awk '{sub("'"$current_version_full"'","'"$new_version_full"'")}1' $control > /tmp/temp.txt && mv /tmp/temp.txt $control
}

function package_build() {
	echo "[PACKAGE] [BUILD] Starting: $1"

	dpkg-deb -b $TEMP_DIRECTORY $UPDATED_DIRECTORY

	if [[ $code -ne 0 ]]; then
		echo "Failure: $code"

		package_cleanup
		exit 1
	else
		echo "[PACKAGE] [BUILD] Done"
	fi
}

function package_process() {
	echo "[PACKAGE] Starting processing: $1"

	package_cleanup
	package_extract $1
	package_alter
	package_reversion
	package_build $1
	package_cleanup
}

function repository_reindex() {
	echo "[REPOSITORY] [REINDEX] Starting: $UPDATED_DIRECTORY"

	cd $UPDATED_DIRECTORY

	dpkg-scanpackages --multiversion . /dev/null > Release

	if [[ $code -ne 0 ]]; then
		echo "Failure: $code"

		exit 1
	else
		echo "[REPOSITORY] [REINDEX] Done"
	fi
}

function main() {
	mkdir -p $BASE_DIRECTORY
	mkdir -p $ORIGINAL_DIRECTORY
	mkdir -p $UPDATED_DIRECTORY
	mkdir -p $TEMP_DIRECTORY

	cd $ORIGINAL_DIRECTORY

	for package in *.deb; do
		if [[ $package == hive-miners-gminer_0.6-*.deb ]]; then
			package_process $package
		fi
	done


	# Run in docker instead of here
	#repository_reindex
}

main

# EOF
