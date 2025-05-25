#!/bin/bash

# @Purpose:
# 	Compile a passed AppleScript file and deploy to the user's Script Libraries/core sub directory.
#
# @Change Logs:
# 	Thu, Jul 18, 2024 at 10:06:00 PM - Use deployment type.
# 	September 3, 2023 3:58 PM - Use packages.

DEPLOY_TYPE_KEY="[app-core] Deployment Type - LOV Selected"
PLIST_PATH="$HOME/applescript-core/session.plist"
DEPLOY_TYPE=$(plutil -extract "$DEPLOY_TYPE_KEY" raw "$PLIST_PATH")
# echo "DEBUG: Deployment Type: [$DEPLOY_TYPE]"

input_file_path=$(echo "$1 $2 $3 $4 $5" | sed 's/ *$//')
# echo "DEBUG: input_file_path: [$input_file_path]"

base_filename=$(echo "$input_file_path" | awk -F/ '{print $NF}' | sed 's/ *$//')
# echo "DEBUG: base_filename: [$base_filename]"

deployment_path="$HOME/Library/Script Libraries/core/"
if [[ $DEPLOY_TYPE != *"error"* ]]; then
    if [[ $DEPLOY_TYPE == "computer" ]]; then
        deployment_path="/Library/Script Libraries/core/"
    fi
# else
#     echo "DEBUG: Deployment type was not configured, using defaults"
fi


# osacompile -o "$deployment_path$base_filename.scpt" "${input_file_path}.applescript"

staging_directory="/tmp/"
osacompile -o "$staging_directory$base_filename.scpt" "${input_file_path}.applescript"

mv "$staging_directory$base_filename.scpt" "$deployment_path$base_filename.scpt"
