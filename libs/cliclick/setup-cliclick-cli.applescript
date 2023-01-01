#!/usr/bin/osascript

(* Browse the CLI into config so it can be referenced by user scripts. *)

set chosenCli to choose file with prompt "Please select the cliclick CLI:" default location POSIX file "/usr/local/bin/cliclick"
do shell script "plutil -replace 'cliclick CLI' -string \"" & (POSIX path of chosenCli) & "\" ~/applescript-core/config-system.plist"
