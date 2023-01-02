#!/bin/bash

SWITCHES=$(plutil -extract "Switches" raw ~/applescript-core/config-user.plist)

if [[ $SWITCHES == *"error"* ]];
then
    echo "Installing Switches in config-user..."
	plutil -replace 'Switches' -xml '<array></array>' ~/applescript-core/config-user.plist
    echo "Done"
else
    echo "Switches array is already installed"
fi
