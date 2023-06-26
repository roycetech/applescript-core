#!/usr/bin/osascript

(* Browse the CLI into config so it can be referenced by user scripts. *)

try
	set chosenCli to choose file with prompt "Please select the redis CLI:" default location POSIX file "/usr/local/bin/redis-cli"
on error
	set chosenCli to choose file with prompt "Please select the redis CLI:" default location POSIX file "/opt/homebrew/bin/redis-cli"
end try

do shell script "plutil -replace 'Redis CLI' -string \"" & (POSIX path of chosenCli) & "\" ~/applescript-core/config-system.plist"
