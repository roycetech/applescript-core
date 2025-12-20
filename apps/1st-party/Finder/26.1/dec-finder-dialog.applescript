(*
	@Purpose:


	@Project:
		applescript-core

		@Build:
		./scripts/build-lib.sh apps/1st-party/Finder/15.2/dec-finder-dialog

	@Created: Thu, Dec 18, 2025 at 04:33:57 PM
	@Last Modified: 2025-12-18 16:37:18
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
		Manual: Respond Empty Trash
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
	set sutLib to script "core/finder"
	set sut to sutLib's new()
	set sut to decorate(sut)

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's respondEmptyTrash()

	else if caseIndex is 3 then

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script FinderDialogDecorator
		property parent : mainScript

		on respondEmptyTrash()
			tell application "System Events" to tell process "Finder"
				try
					click button "Empty Trash" of front window
				end try
			end tell
		end respondEmptyTrash
	end script
end decorate
