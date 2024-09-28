#!/usr/bin/osascript

(*
	DEPRECATED: User scripts should create a library, import that instead.

	Browse the AppleScript Core project path so it can referenced by user
	scripts for testing.

	@Prerequisites:
		Project must be checked out consistently with the same folder as the
		repository name. (e.g. https://gh.com/org/project must be cloned with a folder
		named "project".

	@Plists:
		config-system.plist
			key: AppleScript Core Project Path
			check: plutil -extract "AppleScript Core Project Path" raw ~/applescript-core/config-system.plist
		config-user.plist
			AppleScript Projects Path(list)
			Project applescript-core (project path)

	@Uninstall:
		plutil -remove 'AppleScript Core Project Path' ~/applescript-core/config-system.plist
*)

use scripting additions

use textUtil : script "core/string"
use listUtil : script "core/list"

use loggerLib : script "core/logger"
use plutilLib : script "core/plutil"

set logger to loggerLib's new("setup-applescript-core-project-path")
set plutil to plutilLib's new()

set username to short user name of (system info)
set PROJECT_PATH_KEY to "AppleScript Core Project Path"

tell application "System Events"
	set posixPath to POSIX path of (path to me)
end tell

set projectPath to textUtil's replace(result, "/scripts/setup-applescript-core-project-path.applescript", "")
if posixPath ends with "/" and length of posixPath is greater than 1 then set posixPath to text 1 thru -2 of posixPath

do shell script "plutil -replace '" & PROJECT_PATH_KEY & "' -string \"" & projectPath & "\" ~/applescript-core/config-system.plist"


set projectKey to "Project applescript-core"
set configUser to plutil's new("config-user")
if configUser's hasValue(projectKey) then
	logger's infof("The project: {} is already registered", projectKey)
	return
end if

configUser's setValue(projectKey, projectPath)

set projectList to configUser's getList("AppleScript Projects Path")
if projectList is missing value then set projectList to {}
set end of projectList to projectPath
configUser's setValue("AppleScript Projects Path", projectList)
logger's infof("The project: {} is now registered", projectPath)
