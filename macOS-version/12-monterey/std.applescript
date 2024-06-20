(*
	Usage:
		use std : script "core/std"

		Do not use logger here because it will result in circular dependency.

	@Build:
		make build-lib SOURCE=macOS-version/12-monterey/std
*)

use scripting additions

use loggerFactory : script "core/logger-factory"

-- property logger : loggerFactory's newBasic("std") -- Problematic. Assignment outcome is unpredictable.
property logger : missing value
property username : short user name of (system info)

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)

	try
		-- noo
	on error the errorMessage number the errorNumber
		-- catch("spotCheck-std", errorNumber, errorMessage)
		catch("spotCheck-std", errorNumber, "is not allowed to send keystrokes")
	end try

	logger's infof("Username: {}", getUsername())
	logger's infof("App Exists no: {}", appExists("Magneto"))
	logger's infof("App Exists yes: {}", appExists("Script Editor"))

	assertThat given condition:1 + 3 < 10, messageOnFail:"failed on first assertion"
	-- assertThat given condition:1 + 3 < 4, messageOnFail:"failed on second assertion"
end spotCheck


(* My general catch handler for all my scripts. Used as top most only. *)
on catch(source, errorNumber, errorMessage)
	loggerFactory's injectBasic(me)

	if errorMessage contains "user canceled" or errorMessage contains "abort" then
		logger's warn(errorMessage)
		say "aborted"
		return
	end if

	if errorMessage contains "is not allowed to send keystrokes" or errorMessage contains "is not allowed assistive access" then
		try
			tell application "System Preferences"
				activate
				reveal anchor "Privacy_Accessibility" of pane id "com.apple.preference.security"
			end tell
			delay 1.5 -- 1 Failed.

			tell application "System Events" to tell process "System Preferences"
				click button "Click the lock to make changes." of window "Security & Privacy"
			end tell
			do shell script "afplay /System/Library/Sounds/Glass.aiff"
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
	end try
	false
end appExists


on getUsername()
	if my username is missing value then set my username to short user name of (system info)
	my username
end getUsername


on getComputerName()
	computer name of (system info)
end getComputerName


on assertThat given condition:condition as boolean, messageOnFail:message : missing value
	if condition is false then
		loggerFactory's injectBasic(me)

		-- set loggerLib to script "core/logger"
		-- set logger to loggerLib's new()

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
