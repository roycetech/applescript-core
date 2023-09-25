#!/bin/bash

# Change Logs:
# 	September 3, 2023 3:58 PM - Use packages.

INPUT_FILE_PATH=$(echo "$1 $2 $3 $4 $5" | sed 's/ *$//')
# echo "INPUT_FILE_PATH: [$INPUT_FILE_PATH]"

BASEFILENAME=$(echo $INPUT_FILE_PATH | awk -F/ '{print $NF}' | sed 's/ *$//')
# echo "BASEFILENAME: [$BASEFILENAME]"

osacompile -o ~/Library/Script\ Libraries/core/"$BASEFILENAME.scpt" "${INPUT_FILE_PATH}.applescript"
