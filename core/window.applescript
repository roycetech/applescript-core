(*
	@Last Modified: 2025-01-21 14:28:27

	@Project:
		applescript-core

	@Build:
		make build-lib SOURCE=core/window
*)

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	set spotScript to script "core/spot-test"
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		INFO:
		Manual: Has Window (Check absence, presence, and on another desktop)
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()
	logger's infof("Has Window: {}", sut's hasWindow("Safari"))
	if caseIndex is 1 then

	else if caseIndex is 2 then
	end if

	spot's finish()
	logger's finish()
end spotCheck


on new()
	script WindowInstance
		on hasWindow(appName)
			hasAllWindows({appName})
		end hasWindow

		(*
			Purpose?

			@appNames list of app names
		*)
		on hasAllWindows(appNames)
			set calcAppNames to appNames
			if class of appNames is text then set calcAppNames to {appNames}

			repeat with nextAppName in calcAppNames
				if running of application nextAppName is false then return false

				tell application "System Events" to tell process nextAppName
					if (count of windows) is 0 then return false
				end tell
			end repeat

			true
		end hasAllWindows
	end script
end new
