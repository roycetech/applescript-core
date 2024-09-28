#!/bin/bash

# This script will check the existence of the "core" directory under the user
# library or the computer library and set the value in the
# ~/applescript-core/config-user.plist.

echo "I: Detecting deployment type..."

dir_computer='/Library/Script Libraries/core'
dir_user="$HOME/Library/Script Libraries/core"
found=0

if [ -d "$dir_computer" ]; then
	found=1
	echo "I: Computer-scoped deployment found"
fi

if [ -d "$dir_user" ]; then
	found=1
	echo "I: User-scoped deployment found"
fi


if [ $found -eq 0 ]; then
	echo "I: AppleScript Core installation was not found."
fi
