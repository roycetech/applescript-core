(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/FileZilla/3.68.x/file-zilla

	@Created: Wednesday, January 15, 2025 at 9:46:35 AM
	@Last Modified: 2025-05-08 06:42:29
*)

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Reconnect Latest
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

	else if caseIndex is 2 then
		sut's reconnectlatest()
	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)

	script FileZillaInstance
		on reconnectlatest()
			if running of application "FileZilla" is false then return

			tell application "System Events" to tell process "FileZilla"
				set quickConnectDropdown to button 2 of window 1
				click quickConnectDropdown
				delay 0.1
				try
					click menu item 4 of menu 1 of quickConnectDropdown
				end try
			end tell
		end reconnectlatest
	end script
end new
