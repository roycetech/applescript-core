(*
	Usage:
		set std to script "std"
		
		IMPORTANT: Do not remove the init() at the start of each handler. This 
		is critical in this library, because this library is loaded differently from the rest.
		
		Do not use logger here because it will result in circular dependency.
*)


property logger : loggerLib's new("")
property username : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	
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

(*
	Loads a script library from the users Library/Script Library folder.

	@return the reference to the loaded library.
*)
on import(moduleName)
	init() -- do not remove.
	
	set theScript to script moduleName
	try -- in case init is not defined. Other errors not expected.
		-- logger's debug(moduleName & " " & (initialized of theScript))
		
		if not initialized of theScript then
			-- logger's debug("Initializing script: " & moduleName)
			theScript's init()
		end if
	end try
	
	theScript
end import


on applyMappedOverride(scriptObj)
	set scriptName to the name of the scriptObj
	set factory to missing value
	try
		set factory to do shell script "plutil -extract '" & scriptName & "' raw ~/applescript-core/config-lib-factory.plist"
		-- set csv to do shell script "/usr/libexec/PlistBuddy -c \"Print :'" & scriptName & "'\" ~/applescript-core/config-lib-factory.plist | awk '/^[[:space:]]/' | awk 'NF {$1=$1;print $0}' | paste -s -d, -"
		
		set oldDelimiters to AppleScript's text item delimiters
		set AppleScript's text item delimiters to ","
		set array to every text item of csv
		set AppleScript's text item delimiters to oldDelimiters
		repeat with nextElement in the array
			try
				set factoryScript to import(nextElement)
				set scriptObj to factoryScript's decorate(scriptObj)
			end try
			
		end repeat
		return scriptObj
	end try
	
	if factory is not missing value then
		set factoryScript to import(factory)
		return factoryScript's decorate(scriptObj)
	end if
	
	scriptObj
end applyMappedOverride


(* My general catch handler for all my scripts. Used as top most only. *)
on catch(source, errorNumber, errorMessage)
	init() -- do not remove.
	
	if errorMessage contains "user canceled" or errorMessage contains "abort" then
		logger's warn(errorMessage)
		say "aborted"
		return
	end if
	
	if errorMessage contains "is not allowed to send keystrokes" or errorMessage contains "is not allowed assistive access" then
		
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



on init()
	if initialized of me then return
	set initialized of me to true
	
	set logger to script "logger"
	logger's init()
	set logger to logger's new("std")
end init
