#!/bin/bash

# Caveat, uses simple workaround for names with spaces. Can have as many as 9 spaces.

INPUT_FILE_PATH=$(echo "$1 $2 $3 $4 $5 $6 $7 $8 $9" | sed 's/ *$//')
echo "Input File Path: $INPUT_FILE_PATH"

BASEFILENAME=$(echo $INPUT_FILE_PATH | awk -F/ '{print $NF}' | sed 's/ *$//')
DEPLOY_PATH='/Applications/AppleScript/Stay Open/'"$BASEFILENAME.app"
echo "Deploy Path: $DEPLOY_PATH"
echo "Command: ${DEPLOY_PATH} -s ${INPUT_FILE_PATH}.applescript"

rm -rf "${DEPLOY_PATH}"
osacompile -o "${DEPLOY_PATH}" -s "${INPUT_FILE_PATH}.applescript"

