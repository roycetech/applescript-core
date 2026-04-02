#!/usr/bin/osascript
# Created: Tue, Mar 31, 2026, at 05:32:56 PM

(* Browse the CLI into config so it can be referenced by user scripts. *)

-- Try via brew installation
try
	set chosenCli to choose file with prompt "Please select the cursor cli:" default location POSIX file "/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
on error the errorMessage number the errorNumber
	if errorMessage is "User canceled." then
		return
	end if
	set chosenCli to choose file with prompt "Please select the cursor cli:"
end try

do shell script "plutil -replace 'Cursor CLI' -string \"" & (POSIX path of chosenCli) & "\" ~/applescript-core/config-system.plist"

