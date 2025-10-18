(*
	@Purpose:
		Handlers that access features from the menu bar.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Marked/2.6.46/dec-marked-menu

	@Known Issues:
		Sun, Oct 12, 2025, at 05:25:57 AM - Menu can be out of sync with reality. Re-toggle manually from the Marked 2 app menu to fix.

	@Created: Sat, Oct 11, 2025 at 09:13:12 AM
	@Last Modified: 2025-10-12 05:26:32
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Toggle Dark Mode
		Turn On Dark Mode
		Turn On Light Mode
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	-- activate application ""
	set sutLib to script "core/marked"
	set sut to sutLib's new()
	set sut to decorate(sut)

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's toggleDarkMode()

	else if caseIndex is 3 then
		sut's turnOnDarkMode()

	else if caseIndex is 4 then
		sut's turnOnLightMode()

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script MarkedMenuDecorator
		property parent : mainScript

		on turnOnDarkMode()
			if running of application "Marked 2" is false then return

			tell application "System Events" to tell process "Marked 2"
				-- try
				set isChecked to value of attribute "AXMenuItemMarkChar" of menu item "Dark Mode" of menu 1 of menu bar item "Preview" of menu bar 1 is not missing value
				if isChecked then return

				-- end try
			end tell

			toggleDarkMode()
		end turnOnDarkMode


		on turnOnLightMode()
			tell application "System Events" to tell process "Marked 2"
				set frontmost to true
				try
					if value of attribute "AXMenuItemMarkChar" of menu item "Dark Mode" of menu 1 of menu bar item "Preview" of menu bar 1 is missing value then return
				end try
			end tell

			toggleDarkMode()
		end turnOnLightMode


		on toggleDarkMode()
			logger's debug("Toggling Dark Mode...")

			tell application "System Events" to tell process "Marked 2"
				set frontmost to true
				delay 0.01
				try
					click menu item "Dark Mode" of menu 1 of menu bar item "Preview" of menu bar 1
				end try
			end tell
		end toggleDarkMode
	end script
end decorate
