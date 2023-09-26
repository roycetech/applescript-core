(*
	@Version:
		1.1 - For macOS Ventura.

	@Project:
		applescript-core

	@Build:
		make build-console

	@Created: Tuesday, September 26, 2023 at 1:16:23 PM
	@Last Modified: 2023-09-26 13:26:56
*)

use listUtil : script "core/list"
use loggerFactory : script "core/logger-factory"

use spotScript : script "core/spot-test"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Toggle Now
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
		sut's nowModeToggle(false)
		sut's nowModeToggle(true)

	else if caseIndex is 2 then

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)

	script LibraryInstance
		on nowModeToggle(flag)
			-- Let's toggle the "Now" here.
			tell application "System Events" to tell process "Console"
				-- set nowCheckbox to checkbox 1 of group 1 of toolbar 1 of front window  -- Monterey.
				set nowCheckbox to checkbox 1 of toolbar 1 of front window
				if value of nowCheckbox is 0 and flag or not flag and value of nowCheckbox is 1 then
					click nowCheckbox
				end if
			end tell
		end nowModeToggle
	end script
end new
