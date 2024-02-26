#!/bin/bash

# osacompile is not working, so let's simply copy the entire directory.

SOURCE=$1
SOURCE="core/Text Utilities" # for spot checking.

BASEFILENAME=$(echo $SOURCE | awk -F/ '{print $NF}')
cp -r "$SOURCE.scptd" ~/Library/Script\ Libraries/core/
