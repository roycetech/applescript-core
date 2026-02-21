#!/bin/bash

# Purpose:
# 	Adds an override to a script instance so that the actual instance returned is an enhanced object via decoration.
#
# Created: August 9, 2023 7:33 PM

script_name=$0
list_key=$1
new_decorator=$2

# list_key="Test Instance"
# new_decorator="dec-test-only"

file_path=~/applescript-core/config-lib-factory.plist

list_present=$(plutil -extract "$list_key" raw $file_path 2>&1)

if [[ $list_present != *"error"* ]] ;
then
	: # Do nothing.
	# echo "DEBUG: list_present: $list_present"
	# echo "D: ${script_name}: List [$list_key] found"
else
	# echo "D: ${script_name}: Creating a new list"
	plutil -replace  "$list_key" -xml '<array></array>' $file_path
fi

result=$(awk "/>$list_key</,/<\\/array>/" $file_path | tail -n +2 | grep "$new_decorator")

if [[ -n "$result" ]]; #
then
	echo "I: ${script_name}: Already installed: $new_decorator";

else
	echo "I: ${script_name}: Appending: $new_decorator into $list_key"
	plutil -insert "$list_key" -string "$new_decorator" -append $file_path

fi
