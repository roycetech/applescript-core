#!/bin/bash

# This file is expected to be invoked from a Makefile.

# osacompile is not working, so let's simply copy the entire directory.

source=$1
# source="core/Text Utilities" # for spot checking.
# echo "DEBUG: Source: $source"

# base_filename=$(echo "$source" | awk -F/ '{print $NF}')

DEPLOY_TYPE=$(./scripts/get-deploy-type.sh)
# echo "DEBUG: Deployment type: $DEPLOY_TYPE"


deployment_path="$HOME/Library/Script Libraries/core/"
if [[ $DEPLOY_TYPE != *"error"* ]]; then
    if [[ $DEPLOY_TYPE == "computer" ]]; then
        deployment_path="/Library/Script Libraries/core/"
    fi
# else
    # echo "DEBUG: Deployment type was not configured, using defaults"
fi

# cp -r "$source.scptd" ~/Library/Script\ Libraries/core/
cp -r "$source.scptd" "$deployment_path"
