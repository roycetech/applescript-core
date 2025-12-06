#!/bin/bash

# @Purpose:
# 	Compile a passed AppleScript file and deploy to the user's Script Libraries/core sub directory.
#
# @Change Logs:
#   Tue, Nov 25, 2025, at 02:39:49 PM
#       - Use the all_arguments $*.
#       - Detect test scripts and deploy under <script libraries>/core/test

# 	Thu, Jul 18, 2024 at 10:06:00 PM - Use deployment type.
# 	September 3, 2023 3:58 PM - Use packages.

DEPLOY_TYPE_KEY="[app-core] Deployment Type - LOV Selected"
PLIST_PATH="$HOME/applescript-core/session.plist"
DEPLOY_TYPE=$(plutil -extract "$DEPLOY_TYPE_KEY" raw "$PLIST_PATH")
# echo "DEBUG: Deployment Type: [$DEPLOY_TYPE]"

all_arguments="$*"
input_file_path=${all_arguments// *$//}
# echo "DEBUG: input_file_path: [$input_file_path]"

base_filename=$(echo "$input_file_path" | awk -F/ '{print $NF}' | sed 's/ *$//')
# echo "DEBUG: base_filename: [$base_filename]"

deployment_path="$HOME/Library/Script Libraries/core"
if [[ $DEPLOY_TYPE != *"error"* ]]; then
    if [[ $DEPLOY_TYPE == "computer" ]]; then
        deployment_path="/Library/Script Libraries/core"
    fi
# else
#     echo "DEBUG: Deployment type was not configured, using defaults"
fi

deploy_subpath=""
if [[ "$all_arguments" == test/* ]]; then
    deploy_subpath="/test"
fi

# NOTE: Compiling directly to the deployment target results in permission error.
# Using a staging directory resolves that issue.
staging_directory="/tmp"
osacompile -o "${staging_directory}/${base_filename}.scpt" "${input_file_path}.applescript"

mv "${staging_directory}/${base_filename}.scpt" "${deployment_path}/${deploy_subpath}/${base_filename}.scpt"
