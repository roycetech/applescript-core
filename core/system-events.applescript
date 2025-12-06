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
		./scripts/build-lib.sh core/system-events

	@Change Logs:
		Tue, Nov 18, 2025, at 09:34:12 AM - Added #getFrontAppDisplayedName()
*)

use std : script "core/std"
use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"

use decoratorLib : script "core/decorator"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	set caseId to "system-events-spotCheck"
	logger's start()

	set cases to listUtil's splitByLine("
		INFO
		Manual: Get Front Window
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(caseId, cases)
	set {caseIndex, caseDesc} to spot's start()

	set sut to new()
	delay 2
	logger's infof("Front App Name: {}", sut's getFrontAppName())
	logger's infof("Front App Displayed Name: {}", sut's getFrontAppDisplayedName())

	if caseIndex is 2 then
		logger's logObj("Front Window:", sut's getFrontWindow())

	else if caseIndex is 2 then

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


		(*
			Some apps like Sublime Text, Electron, IntelliJ has different name than its display name.
		*)
		on getFrontAppDisplayedName()
			set frontAppName to missing value
			tell application "System Events"
				try
					set frontApp to first application process whose frontmost is true
					set frontAppName to displayed name of frontApp
				end try
			end tell

			frontAppName
		end getFrontAppDisplayedName
	end script

	set decorator to decoratorLib's new(result)
	decorator's decorate()
end new
