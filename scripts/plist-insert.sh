#!/bin/bash

# Purpose:
# 	Adds a new element to an array in a plist.
#
# Updated from factory-insert.sh
# Created: Tue, Aug 6, 2024 at 2:17:16 PM

plist_path=$1
array_key=$2
new_array_element=$3

# plist_path=~/applescript-core/config-poc.plist
# array_key="[app-notes] User-Scoped Projects"
# new_array_element="applescript-notes"

array_present=$(plutil -extract "$array_key" raw $plist_path)
if [[ $array_present != *"error"* ]];
then
	echo "Array [$array_key] found"
else
	echo "Creating a new array: $array_key"
	plutil -replace  "$array_key" -xml '<array></array>' $plist_path
fi

if xmllint --xpath "//dict/key[text()='$array_key']/following-sibling::array/string[text()='$new_array_element']" $plist_path > /dev/null 2>&1;
then
	echo "Array element is already installed: $new_array_element";

else
	echo "Appending: $new_array_element for $array_key"
	plutil -insert "$array_key" -string "$new_array_element" -append $plist_path
fi
