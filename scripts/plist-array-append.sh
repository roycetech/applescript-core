#!/bin/bash

# Usage:
# 	plist-array-append.sh <list-key-name> <new-element> <plist-path>

LIST_KEY_NAME=$1
NEW_ELEMENT=$2
PLIST_PATH=$3



# Usage: ./check_plist_key.sh /path/to/plist.plist key_name

if [ $# -ne 3 ]; then
  echo "Usage: ./plist-array-append.sh <list-key-name> <new-element> <plist-path>"
  exit 1
fi


# Initialize the array if LIST_KEY_NAME doesn't exist yet.
if ! plutil -extract "$LIST_KEY_NAME" xml1 -o /dev/null "$PLIST_PATH"; then
	plutil -replace "$LIST_KEY_NAME" -xml '<array></array>' $PLIST_PATH
fi

if /usr/libexec/PlistBuddy -c "Print ${LIST_KEY_NAME}" "${PLIST_PATH}" | grep -q "${NEW_ELEMENT}"; then
	echo "Already present: $NEW_ELEMENT";

else
	echo "Inserting: $NEW_ELEMENT"
	plutil -insert "$LIST_KEY_NAME" -string "$NEW_ELEMENT" -append $PLIST_PATH

fi
