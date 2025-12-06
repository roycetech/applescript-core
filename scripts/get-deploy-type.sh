#!/bin/bash

# @Purpose:
# 	This script is invoked in the Makefile to determine the deployment type.
#
# @Change Logs:
# 	Thu, Jul 18, 2024 at 10:06:00 PM - Use deployment type.
# 	September 3, 2023 3:58 PM - Use packages.

DEPLOY_TYPE_KEY="[app-core] Deployment Type - LOV Selected"
PLIST_PATH="$HOME/applescript-core/session.plist"
DEPLOY_TYPE=$(plutil -extract "$DEPLOY_TYPE_KEY" raw "$PLIST_PATH")

if [[ $DEPLOY_TYPE != *"error"* ]]; then
    if [[ $DEPLOY_TYPE == "computer" ]]; then
        echo "computer"
    else
        echo "user"
    fi
else
    echo "user"
fi
