#!/usr/bin/osascript
# Created: September 28, 2023 3:26 PM

(* Browse the CLI into config so it can be referenced by user scripts. *)


set homePath to do shell script "echo ${HOME}"

try
	set chosenCli to choose file with prompt "Please select the intellij-cli:" default location POSIX file (homePath & "/Library/Application Support/JetBrains/Toolbox/scripts/idea")
on error the errorMessage number the errorNumber
	log errorMessage
end try

do shell script "plutil -replace 'IntelliJ CLI' -string \"" & (POSIX path of chosenCli) & "\" ~/applescript-core/config-system.plist"
log "CLI Set to: " & chosenCli
