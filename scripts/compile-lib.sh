#!/bin/bash

INPUT_FILE_PATH=$(echo "$1 $2 $3" | sed 's/ *$//')
# echo "INPUT_FILE_PATH: [$INPUT_FILE_PATH]"

BASEFILENAME=$(echo $INPUT_FILE_PATH | awk -F/ '{print $NF}' | sed 's/ *$//')
# echo "BASEFILENAME: [$BASEFILENAME]"

osacompile -o ~/Library/Script\ Libraries/"$BASEFILENAME.scpt" "${INPUT_FILE_PATH}.applescript"
