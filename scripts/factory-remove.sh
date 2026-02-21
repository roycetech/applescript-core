#!/bin/bash

# Purpose:
# 	Removes an override to a script instance. This is the reverse of the
# 	factory-insert.sh script.
#
# Created: August 9, 2023 7:57 PM

script_name=$0
list_key=$1
new_decorator=$2

# list_key="Test Instance"
# new_decorator="dec-test-only"

file_path=~/applescript-core/config-lib-factory.plist

list_present=$(plutil -extract "$list_key" raw $file_path)
if [[ $list_present != *"error"* ]];
then
	: # Do nothing.
	# echo "D: ${script_name}: List [$list_key] was found"
else
	# echo "D: ${script_name}: Decorator $new_decorator was not found"
	exit 1
fi

result=$(awk "/>$list_key</,/<\\/array>/" $file_path | tail -n +2 | grep "$new_decorator")
if [[ -n "$result" ]];
then
	echo "${script_name}: Removing: $new_decorator from $list_key"
	escaped_decorator=$(echo "$new_decorator" | sed 's/[.*\/]/\\&/g')
	cleaned_list=$(awk "/>$list_key</,/<\\/array>/" $file_path | tail -n +2 | sed "/$escaped_decorator/d")

	# trimmed=$(echo "$cleaned_list" | sed 's/ //g')
	trimmed=${cleaned_list// /}
	if [[ $trimmed == "<array></array>" ]];
	then
		plutil -remove "$list_key" $file_path

	else
		plutil -replace "$list_key" -xml "$cleaned_list" $file_path
	fi

else
	: # Do nothing.
	# echo "D: ${script_name}: Could not find: $new_decorator";
fi
