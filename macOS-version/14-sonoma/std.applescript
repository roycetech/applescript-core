(*
	Usage:
		set std to script "core/std"

		Do not use logger here because it will result in circular dependency.  <- FOR REVIEW.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh macOS-version/14-sonoma/std
*)

use scripting additions
use loggerFactory : script "core/logger-factory"

property logger : missing value

property username : missing value

(* Cache the system info *)
property systemInfo : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)

	logger's infof("Username: {}", getUsername())

	try
		noo
	on error the errorMessage number the errorNumber
		-- catch("spotCheck-std", errorNumber, errorMessage)
		catch("spotCheck-std", errorNumber, "is not allowed to send keystrokes")
	end try

	logger's infof("App Exists no: {}", appExists("Magneto"))
	logger's infof("App Exists yes: {}", appExists("Script Editor"))
	logger's infof("Find app (unicorn): {}", findApp("Unicorn"))
	logger's infof("Find app (Finder): {}", findApp("Finder"))
	logger's infof("Find user app (Menu Case): {}", findApp("Menu Case"))
	return

	assertThat given condition:1 + 3 < 10, messageOnFail:"failed on first assertion"
	assertThat given condition:1 + 3 < 4, messageOnFail:"failed on second assertion"
end spotCheck



(* My general catch handler for all my scripts. Used as top most only. *)
on catch(source, errorNumber, errorMessage)
	loggerFactory's injectBasic(me)

	if errorMessage contains "user canceled" or errorMessage contains "abort" then
		logger's warn(errorMessage)
		say "aborted"
		return
	end if

	if errorMessage contains "Scripting Component Error" then
		logger's warn(errorMessage)
		return
	end if

	if errorMessage contains "is not allowed to send keystrokes" or errorMessage contains "is not allowed assistive access" then
		logger's warn(errorMessage)

		try
			activate application "System Settings"
			delay 1 -- required or else set current pane will fail

			tell application "System Settings"
				set current pane to pane id "com.apple.settings.PrivacySecurity.extension"
				anchors of current pane
				reveal anchor "Privacy_Accessibility" of current pane
			end tell
		end try

		return
	end if

	if class of source is text then
		set scriptName to source
	else
		set scriptName to name of source
	end if
	logger's fatal(scriptName & ":Error: " & errorMessage)
	display dialog scriptName & ":Error: " & the errorNumber & ". " & the errorMessage with title "AS: Standard Library(Auto-closes in 10s)" buttons {"OK"} giving up after 10
end catch


on appWithIdExists(bundleId)
	try
		tell application "Finder" to get application file id bundleId
		return true
	end try
	false
end appWithIdExists


on appExists(appName)
	try
		do shell script "osascript -e 'id of application \"" & appName & "\"'"
		return true
	on error
		tell application "System Events"
			try
				return exists (first process whose name is appName)
			end try -- Why do we need this?
		end tell
	end try
	false
end appExists


(*
	@returns the app name if it exists. It checks the user app name, which is a
	custom convention in the form of username.appname, if it exists instead.
*)
on findApp(appName)
	if appExists(appName) then return appName

	set userAppName to getUsername() & "." & appName
	if appExists(userAppName) then return userAppName

	missing value
end findApp


on getUsername()
	if my username is missing value then set my username to short user name of my _systemInfo()
	if my username is equal to "root" then set my username to do shell script "whoami"
	my username
end getUsername


on getComputerName()
	computer name of my _systemInfo()
end getComputerName


on assertThat given condition:condition as boolean, messageOnFail:message : missing value

	if condition is false then
		if message is missing value then set message to "Assertion failed"

		tell me to error message
		logger's fatal(message)
	end if
end assertThat


(*  *)
on ternary(condition, ifTrue, otherwise)
	if condition then return ifTrue

	otherwise
end ternary


(*  *)
on nvl(nonMissingValue, ifMissingValue)
	if nonMissingValue is missing value then return ifMissingValue

	nonMissingValue
end nvl

(*
	Intended to quiet the replies a little mit.
*)
on _systemInfo()
	if my systemInfo is missing value then set my systemInfo to (system info)
	my systemInfo
end _systemInfo
