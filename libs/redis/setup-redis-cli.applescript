#!/usr/bin/osascript

(* Browse the CLI into config so it can be referenced by user scripts. *)

set chosenCli to choose file with prompt "Please select the redis-cli:" default location POSIX file "/usr/local/bin/redis-cli"
do shell script "plutil -replace 'Redis CLI' -string \"" & (POSIX path of chosenCli) & "\" ~/applescript-core/config-system.plist"
