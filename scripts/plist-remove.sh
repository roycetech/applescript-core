#!/bin/bash

# Purpose:
# 	Removes an element under an array.  This script was derived from factory-remove.sh.
#
# Created: Tue, Aug 6, 2024 at 4:28:09 PM

plist_path=$1
array_key=$2
element_value_to_delete=$3

# Test Hard-Coded values
# plist_path=~/applescript-core/config-poc.plist
# array_key="[app-notes] User-Scoped Projects"
# element_value_to_delete="applescript-notes"

list_present=$(plutil -extract "$array_key" raw $plist_path)
if [[ $list_present != *"error"* ]];
then
	echo "List [$array_key] was found"
else
	echo "Array element $element_value_to_delete was not found"
	exit 1
fi

if xmllint --xpath "//dict/key[text()='$array_key']/following-sibling::array/string[text()='$element_value_to_delete']" $plist_path > /dev/null 2>&1;
then
	echo "Removing: $element_value_to_delete from $array_key"
	awk -v k="$array_key" -v for_deletion=">$element_value_to_delete<" \
		'BEGIN { key_found = 0 }

		key_found == 0 && index($0, k) {
			key_found = 1
		}
		key_found == 0 { print $0 }

		key_found == 1 && index($0, for_deletion) == 0 { print $0 }
		key_found == 1 && /\<\/array\>/ { key_found = 0 }
	' $plist_path > /tmp/tmpfile && mv /tmp/tmpfile $plist_path
else
	echo "Could not find: $element_value_to_delete";
fi
