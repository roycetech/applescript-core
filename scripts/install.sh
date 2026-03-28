#!/bin/bash
# Created: Sat, Dec 06, 2025, at 01:14:28 PM
#
# @Purpose:
# 	Install the core libraries directly from the web.

set -e

REPO_DIR="$HOME/Projects/@roycetech/applescript-core"
REPO_URL="https://github.com/roycetech/applescript-core"

if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning lightweight repository..."
    git clone --depth=1 "$REPO_URL" "$REPO_DIR"
else
    echo "Updating lightweight repository..."
    git -C "$REPO_DIR" pull --depth=1 --rebase
fi

# Add the current user to the wheel group and allow group write access to the Script Libraries folder.
echo "Adding $(whoami) to the wheel group and allowing group write access to the Script Libraries folder..."
sudo dseditgroup -o edit -a "$(whoami)" -t user wheel \
  && sudo chmod g+w "/Library/Script Libraries" \
  && sudo chmod g+w "/Library/Script Libraries/core" \
  && sudo chmod g+w "/Library/Script Libraries/core/test" \
  && sudo chmod g+w "/Library/Script Libraries/core/app"

cd "$REPO_DIR"
make set-computer-deploy-type install
