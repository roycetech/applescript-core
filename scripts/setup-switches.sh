#!/bin/bash

# @Purpose:
#   Creates a placeholder list for the key 'Switches' in the config-user.plist

# SWITCHES=$(plutil -extract "Switches" raw ~/applescript-core/config-user.plist)

# if [[ $SWITCHES == *"error"* ]];
# then
#     echo "Installing Switches array in config-user..."
# 	plutil -replace 'Switches' -xml '<array></array>' ~/applescript-core/config-user.plist
#     echo "Switch installation done"
# else
#     echo "Switches array is already installed"
# fi

PLIST_KEY=Switches
PLIST_PATH=~/applescript-core/config-user.plist

# echo "D: PLIST_PATH: ${PLIST_PATH}"

switches=$(plutil -extract "$PLIST_KEY" raw "$PLIST_PATH" 2>/dev/null)
# shellcheck disable=SC2181
if [[ $? -ne 0 ]]; then
    echo "I: Installing Switches array in config-user..."
    plutil -replace "$PLIST_KEY" -xml '<array></array>' "$PLIST_PATH"
    echo "I: Switch installation done"

else
    echo "D: Switches: $switches"
    echo "I: Switches array is already installed"
fi
