#!/bin/bash
# Created: Sat, Dec 06, 2025, at 01:14:28 PM
#
# @Purpose:
# 	Install the core libraries directly from the web.

set -e

REPO_DIR="$HOME/Projects/@roycetech/applescript-core-test"
REPO_URL="https://github.com/roycetech/applescript-core"

if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning lightweight repository..."
    git clone --depth=1 "$REPO_URL" "$REPO_DIR"
else
    echo "Updating lightweight repository..."
    git -C "$REPO_DIR" pull --depth=1 --rebase
fi

cd "$REPO_DIR"
make install
