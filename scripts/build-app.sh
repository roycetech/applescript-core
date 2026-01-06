#!/bin/bash

# INPUT_FILE_PATH=$(echo "$1 $2 $3" | sed 's/ *$//')
# echo "INPUT_FILE_PATH: $INPUT_FILE_PATH"

all_arguments="$*"
input_file_path=${all_arguments// *$//}
echo "DEBUG: input_file_path: $input_file_path"

# BASEFILENAME=$(echo $INPUT_FILE_PATH | awk -F/ '{print $NF}' | sed 's/ *$//')
filename_base=$(echo "$input_file_path" | awk -F/ '{print $NF}' | sed 's/ *$//')
echo "DEBUG: filename_base: $filename_base"

filename_dashed="${filename_base// /-}"
echo "DEBUG: filename_dashed: $filename_dashed"

filename_dashed_and_lowercase=$(echo "$filename_dashed" | tr '[:upper:]' '[:lower:]')
echo "DEBUG: filename_dashed_and_lowercase: $filename_dashed_and_lowercase"

# Hard code to computer scope.
deployment_path="/Library/Script Libraries/core/app"

echo "DEBUG: deployment_path: $deployment_path"

# TODO: Compile to the temporary staging location
# osacompile -o "${HOME}/Applications/AppleScript/$filename_base.app" "${input_file_path}.applescript"
staging_directory="/tmp"
osacompile -o "${staging_directory}/${filename_dashed_and_lowercase}.scpt" "${input_file_path}.applescript"
mv "${staging_directory}/${filename_dashed_and_lowercase}.scpt" "${deployment_path}/${filename_dashed_and_lowercase}.scpt"
