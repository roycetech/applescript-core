#!/bin/bash

INPUT_FILE_PATH=$(echo "$1 $2 $3" | sed 's/ *$//')
BASEFILENAME=$(echo $INPUT_FILE_PATH | awk -F/ '{print $NF}' | sed 's/ *$//')
osacompile -o /Applications/AppleScript/"$BASEFILENAME.app" "${INPUT_FILE_PATH}.applescript"
