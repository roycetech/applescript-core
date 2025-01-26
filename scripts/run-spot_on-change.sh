#!/bin/bash

fswatch -o -e ".*" -i ".*\\.applescript$" -i "Makefile" . | xargs -n1 -I{} make spot
