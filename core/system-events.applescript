(*
	This library contains commonly used system event functions.
	For additional functions related to the inspection of a process or a window, see inspector.applescript.
	For additional functions related to a process/app, see process.applescript.

	@Usage:
		use systemEventsLib : script "core/system-events")

		property systemEvents : systemEventsLib's new()

	Or type: sset systemEvents

	@Project:
		applescript-core

	@Build:
		make build-lib SOURCE=core/system-events
*)

use std : script "core/std"
use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"

use spotScript : script "core/spot-test"

use decoratorLib : script "core/decorator"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	set caseId to "system-events-spotCheck"
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Get Front Window
		Manual: Get Front App Name
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(caseId, cases)
	set {caseIndex, caseDesc} to spot's start()

	set sut to new()

	if caseIndex is 1 then
		logger's logObj("Front Window:", sut's getFrontWindow())

	else if caseIndex is 2 then
		logger's infof("Front App Name: {}", sut's getFrontAppName())

	end if
	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's injectBasic(me)

	script SystemEventsInstance
		on getFrontWindow()
			tell application "System Events"
				try
					set frontApp to first application process whose frontmost is true
					set frontAppName to name of frontApp

					tell process frontAppName
						return 1st window whose value of attribute "AXMain" is true
					end tell
				end try
			end tell

			missing value
		end getFrontWindow


		on getFrontWindowTitle()
			tell application "System Events"
				try
					return title of my getFrontWindow()
				end try
			end tell

			missing value
		end getFrontWindowTitle


		on getFrontAppName()
			set frontAppName to missing value
			tell application "System Events"
				try
					set frontApp to first application process whose frontmost is true
					set frontAppName to name of frontApp
				end try
			end tell

			frontAppName
		end getFrontAppName
	end script

	set decorator to decoratorLib's new(result)
	decorator's decorate()
end new
