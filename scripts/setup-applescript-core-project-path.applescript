#!/usr/bin/osascript

(* 
	Browse the AppleScript Core project path so it can referenced by user 
	scripts for testing.

	@Plists:
		config-system.plist
			key: AppleScript Core Project Path
			check: plutil -extract "AppleScript Core Project Path" raw ~/applescript-core/config-system.plist
		config-user.plist
			AppleScript Projects (list)
			Project applescript-core (project path)
			
	@Uninstall:
		plutil -remove 'AppleScript Core Project Path' ~/applescript-core/config-system.plist
*)

set std to script "std"
set logger to std's import("logger")'s new("register-project")
set plutil to std's import("plutil")'s new()

set textUtil to std's import("string")

set username to short user name of (system info)
set PROJECT_PATH_KEY to "AppleScript Core Project Path"

tell application "System Events"
	set posixPath to POSIX path of (path to me)
end tell

set projectPath to textUtil's replace(result, "/scripts/setup-applescript-core-project-path.applescript", "")
if posixPath ends with "/" and length of posixPath is greater than 1 then set posixPath to text 1 thru -2 of posixPath

do shell script "plutil -replace '" & PROJECT_PATH_KEY & "' -string \"" & posixPath & "\" ~/applescript-core/config-system.plist"


set projectKey to "Project applescript-core"
set listUtil to std's import("list")
set configUser to plutil's new("config-user")
if configUser's hasValue(projectKey) then
	logger's infof("The project: {} is already registered", projectKey)
	return
end if

configUser's setValue(projectKey, projectPath)

set projectList to configUser's getList("AppleScript Projects")
if projectList is missing value then set projectList to {}
set end of projectList to projectKey
configUser's setValue("AppleScript Projects", projectList)
logger's infof("The project: {} is now registered", projectPath)
