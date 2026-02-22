(*
	@Version:
		1.1 - For macOS Ventura.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Console/v1.1/console

	@Created: Tuesday, September 26, 2023 at 1:16:23 PM
	@Last Modified: 2026-02-20 13:16:18
*)
use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Manual: Toggle Now
		Manual: Clear Console
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()
	if caseIndex is 1 then
		sut's nowModeToggle(false)
		sut's nowModeToggle(true)

	else if caseIndex is 2 then
		sut's clearConsole()

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)

	script ConsoleInstance
		on nowModeToggle(flag)
			-- Let's toggle the "Now" here.
			tell application "System Events" to tell process "Console"
				-- set nowCheckbox to checkbox 1 of group 1 of toolbar 1 of front window  -- Monterey.
				try
					set nowCheckbox to checkbox 1 of toolbar 1 of front window
					if value of nowCheckbox is 0 and flag or not flag and value of nowCheckbox is 1 then
						click nowCheckbox
					end if
				end try
			end tell
		end nowModeToggle

		on clearConsole()
			tell application "System Events" to tell process "Console"
				try
					click button "Clear" of toolbar 1 of front window
				end try
			end tell
		end clearConsole
	end script
end new
