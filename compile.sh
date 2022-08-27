#!/bin/bash

BASEFILENAME=$(echo $1 | awk -F/ '{print $NF}')
# echo "BASEFILENAME: $BASEFILENAME"
echo "~/Library/Script\ Libraries/$BASEFILENAME.scpt $1.applescript"

osacompile -o osacompile -o ~/Library/Script\ Libraries/$BASEFILENAME.scpt $1.applescript
