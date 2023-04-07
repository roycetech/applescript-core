#!/usr/bin/osascript

(* Browse the CLI into config so it can be referenced by user scripts. *)

try
	set chosenCli to choose file with prompt "Please select the sublime-cli:" default location POSIX file "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl"
on error
	-- Try via brew installation
	set chosenCli to choose file with prompt "Please select the redis-cli:" default location POSIX file "/opt/homebrew/bin/subl"
	
end try

do shell script "plutil -replace 'Sublime Text CLI' -string \"" & (POSIX path of chosenCli) & "\" ~/applescript-core/config-system.plist"

