# @Purpose:
#   Watch the filesystem for changes and run the specified AppleScript file,
#       usually triggering the spotCheck routine.

# @Created: Sat, May 23, 2026, at 07:46:37 AM

# fswatch -e ".*" -i ".*\\.applescript$" . | xargs -n1 sh -c 'clear; osascript "$1"' sh

# Can handle spaces in the filepath.
fswatch -e ".*" -i ".*\\.applescript$" . | while IFS= read -r filepath; do
  clear
  osascript "$filepath"
done