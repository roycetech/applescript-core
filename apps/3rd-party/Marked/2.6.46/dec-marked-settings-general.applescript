(*
	@Purpose:

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Marked/2.6.46/dec-marked-settings-general

	@Created: Mon, Oct 13, 2025 at 07:14:54 AM
	@Last Modified: 2025-10-13 07:32:09
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
		Manual: Set Raise Window on Update ON
		Manual: Set Raise Window on Update OFF
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
		sut's setRaiseWindowOnUpdate(true)

	else if caseIndex is 3 then
		sut's setRaiseWindowOnUpdate(false)

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script MarkedSettingsGeneralDecorator
		property parent : mainScript

		on setRaiseWindowOnUpdate(newValue)
			if running of application "Marked 2" is false then return

			tell application "System Events" to tell process "Marked 2"
				try
					click (first menu item of menu 1 of menu bar item "Marked 2" of menu bar 1 whose title starts with "Preferences")
				end try
				delay 0.1
				click button "General" of toolbar 1 of front window
				set currentValue to value of checkbox "Raise window on update" of front window
				logger's debugf("currentValue: {}", currentValue)
				if currentValue is 0 and newValue or currentValue is 1 and newValue is false then
					click checkbox "Raise window on update" of front window
					delay 0.1
				end if
				click (first button of front window whose description is "close button")
			end tell
		end setRaiseWindowOnUpdate
	end script
end decorate
