#!/usr/bin/osascript

(* Browse the Sublime Text CLI into config so it can be referenced by user scripts. *)

set chosenCli to choose file with prompt "Please select the subl (or aliased to sublime):" default location POSIX file "/usr/local/bin/sublime"
do shell script "plutil -replace 'Sublime Text CLI' -string \"" & (POSIX path of chosenCli) & "\" ~/applescript-core/config-system.plist"
