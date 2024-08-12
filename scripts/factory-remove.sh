#!/bin/bash

# Purpose:
# 	Removes an override to a script instance. This is the reverse of the
# 	factory-insert.sh script.
#
# Created: August 9, 2023 7:57 PM

list_key=$1
new_decorator=$2

# list_key="Test Instance"
# new_decorator="dec-test-only"

file_path=~/applescript-core/config-lib-factory.plist

list_present=$(plutil -extract "$list_key" raw $file_path)
if [[ $list_present != *"error"* ]];
then
	echo "List [$list_key] was found"
else
	echo "Decorator $new_decorator was not found"
	exit 1
fi

result=`awk "/>$list_key</,/<\\/array>/" $file_path | tail -n +2 | grep "$new_decorator"`
if [[ -n "$result" ]];
then
	echo "Removing: $new_decorator from $list_key"
	escaped_decorator=$(echo "$new_decorator" | sed 's/[.*\/]/\\&/g')
	cleaned_list=$(awk "/>$list_key</,/<\\/array>/" $file_path | tail -n +2 | sed "/$escaped_decorator/d")

	trimmed=$(echo $cleaned_list | sed 's/ //g')
	if [[ $trimmed == "<array></array>" ]];
	then
		plutil -remove "$list_key" $file_path

	else
		plutil -replace "$list_key" -xml "$cleaned_list" $file_path
	fi

else
	echo "Could not find: $new_decorator";
fi
