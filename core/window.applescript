(*
	@Last Modified: 2023-07-24 18:18:24

	@Build:
		make compile-lib SOURCE=core/window
*)

use listUtil : script "list"

use loggerFactory : script "logger-factory"

use spotScript : script "spot-test"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	set cases to listUtil's splitByLine("
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
	if caseIndex is 1 then
		logger's infof("Has Window: {}", sut's hasWindow("Safari"))

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


		(* @appNames list of app names *)
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
