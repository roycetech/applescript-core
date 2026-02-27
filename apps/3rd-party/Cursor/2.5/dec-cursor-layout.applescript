(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Cursor/2.5/dec-cursor-layout

	@Created: Wed, Feb 25, 2026 at 02:26:39 PM
	@Last Modified: 2026-02-25 16:41:52
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
		Manual: Single file layout
		Manual: Two columns layout
		Manual: Two rows layout
		Manual: Grid layout

		Dummy
		Dummy
		Dummy
		Dummy
		Dummy
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
	set sutLib to script "core/cursor"
	set sut to sutLib's new()
	set sut to decorate(sut)

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's singleFileLayout()

	else if caseIndex is 3 then
		sut's twoColumnsLayout()

	else if caseIndex is 4 then
		sut's twoRowsLayout()

	else if caseIndex is 5 then
		sut's gridLayout()

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script CursorLayoutDecorator
		property parent : mainScript

		(*
			Move to dec-cursor-layout.applescript
		*)
		on singleFileLayout()
			if running of application "Cursor" is false then return

			tell application "System Events" to tell process "Cursor"
				set frontmost to true -- Requires focus

				try
					click menu item "Single" of menu 1 of menu item "Editor Layout" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
		end singleFileLayout


		on twoColumnsLayout()
			if running of application "Cursor" is false then return

			tell application "System Events" to tell process "Cursor"
				set frontmost to true -- Requires focus

				try
					click menu item "Two Columns" of menu 1 of menu item "Editor Layout" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
		end twoColumnsLayout


		on twoRowsLayout()
			if running of application "Cursor" is false then return

			tell application "System Events" to tell process "Cursor"
				set frontmost to true -- Requires focus

				try
					click menu item "Two Rows" of menu 1 of menu item "Editor Layout" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
		end twoRowsLayout


		on gridLayout()
			if running of application "Cursor" is false then return

			tell application "System Events" to tell process "Cursor"
				set frontmost to true -- Requires focus

				try
					click menu item "Grid (2x2)" of menu 1 of menu item "Editor Layout" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
		end gridLayout
	end script
end decorate
