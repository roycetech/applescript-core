#!/bin/bash

# @Created: Tue, Sep 10, 2024 at 6:23:38 PM
# Delete the core folder under /Library/Script Libraries for computer scope,
# and the core folder under ~/Library/Script Libraries for the user scope.

dir_user="$HOME/Library/Script Libraries/core"
dir_computer='/Library/Script Libraries/core'
found=0

if [ -d "$dir_user" ]; then
	echo "User-scoped deployment detected"
	found=1
	rm -rf "$dir_user"

	echo "Uninstalled from the user library"
fi

if [ -d "$dir_computer" ]; then
	found=1
	echo "Computer-scoped deployment detected"
	sudo rm -rf "$dir_computer"
	echo "Uninstalled from the computer library"
fi

if [ $found -eq 0 ]
then
	echo "AppleScript Core installation was not found."
fi
