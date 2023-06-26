(*
	Usage:
		use std : script "std"
		
		Do not use logger here because it will result in circular dependency.

	@Deployment:
		make compile-lib SOURCE=macOS-version/12-monterey/std
*)

use scripting additions

use loggerFactory : script "logger-factory"

property logger : missing value
property username : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me, "std")
	
	try
		noo
	on error the errorMessage number the errorNumber
		-- catch("spotCheck-std", errorNumber, errorMessage)
		catch("spotCheck-std", errorNumber, "is not allowed to send keystrokes")
	end try
	
	logger's infof("Username: {}", getUsername())
	logger's infof("App Exists no: {}", appExists("Magneto"))
	logger's infof("App Exists yes: {}", appExists("Script Editor"))
	return
	
	assertThat given condition:1 + 3 < 10, messageOnFail:"failed on first assertion"
	assertThat given condition:1 + 3 < 4, messageOnFail:"failed on second assertion"
end spotCheck


(* My general catch handler for all my scripts. Used as top most only. *)
on catch(source, errorNumber, errorMessage)
	loggerFactory's inject(me, "std")
	
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


-- on appExists(bundleId)
-- 	try
-- 		tell application "Finder" to get application file id bundleId
-- 		return true
-- 	end try
-- 	false
-- end appExists


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


on assertThat given condition:condition as boolean, messageOnFail:message : missing value
	loggerFactory's inject(me, "std")
	
	if condition is false then
		-- set loggerLib to script "logger"
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
