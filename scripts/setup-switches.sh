#!/bin/bash

# TODO: Document what is this array for?

SWITCHES=$(plutil -extract "Switches" raw ~/applescript-core/config-user.plist)

if [[ $SWITCHES == *"error"* ]];
then
    echo "Installing Switches array in config-user..."
	plutil -replace 'Switches' -xml '<array></array>' ~/applescript-core/config-user.plist
    echo "Switch installation done"
else
    echo "Switches array is already installed"
fi
