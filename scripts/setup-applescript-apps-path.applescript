#!/usr/bin/osascript

(* 
	Browse the AppleScript subdirector from the user's Applications directory so it can referenced by user 
	scripts for testing. *)

set username to short user name of (system info)
set USER_APPS_PATH_KEY to "AppleScript Apps path"

set currentPath to missing value
try
	set currentPath to do shell script "plutil -extract '" & USER_APPS_PATH_KEY & "' raw ~/applescript-core/config-system.plist"
end try

if currentPath is not missing value and currentPath is not "" then
	set defaultPosixPath to currentPath
else
	set defaultPosixPath to "/Users/" & username & "/Applications/AppleScript/"
end if

set chosenFolder to choose folder with prompt "Please select the AppleScript apps destination folder:" default location POSIX file defaultPosixPath
set posixPath to (POSIX path of chosenFolder)

if posixPath ends with "/" and length of posixPath is greater than 1 then set posixPath to text 1 thru -2 of posixPath

do shell script "plutil -replace '" & USER_APPS_PATH_KEY & "' -string \"" & posixPath & "\" ~/applescript-core/config-system.plist"
