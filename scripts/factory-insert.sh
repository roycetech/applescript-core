#!/bin/bash

# Purpose:
# 	Adds an override to a script instance so that the actual instance returned is an enhanced object via decoration.
#
# Created: August 9, 2023 7:33 PM

list_key=$1
new_decorator=$2

# list_key="Test Instance"
# new_decorator="dec-test-only"

file_path=~/applescript-core/config-lib-factory.plist

list_present=$(plutil -extract "$list_key" raw $file_path)
if [[ $list_present != *"error"* ]];
then
	echo "List [$list_key] found"
else
	echo "Creating a new list"
	plutil -replace  "$list_key" -xml '<array></array>' $file_path
fi

result=`awk "/>$list_key</,/<\\/array>/" $file_path | tail -n +2 | grep "$new_decorator"`

if [[ -n "$result" ]]; #
then
	echo "Already installed: $new_decorator";

else
	echo "Appending: $new_decorator for $list_key"
	plutil -insert "$list_key" -string "$new_decorator" -append $file_path

fi
