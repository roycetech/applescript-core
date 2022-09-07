#!/bin/bash

BASEFILENAME=$(echo $1 | awk -F/ '{print $NF}')
osacompile -o osacompile -o ~/Library/Script\ Libraries/$BASEFILENAME.scpt $1.applescript
