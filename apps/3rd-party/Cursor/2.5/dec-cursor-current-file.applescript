(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Cursor/2.5/dec-cursor-current-file

	@Created: Thu, Feb 26, 2026 at 03:53:46 PM
	@Last Modified: 2026-02-26 16:55:01
	@Change Logs:
*)
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
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

	logger's infof("Current file path: {}", sut's getCurrentFilePath())
	if caseIndex is 1 then

	else if caseIndex is 2 then

	else if caseIndex is 3 then

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script CurrentFileDecorator
		property parent : mainScript

		on getCurrentFilePath()
			if running of application "Cursor" is false then return missing value

			tell application "System Events" to tell process "Cursor"
				set axDocument to value of attribute "AXDocument" of front window
				if axDocument is missing value then return missing value

				set filePath to textUtil's stringAfter(axDocument, "file://")
				return textUtil's replace(filePath, "%20", " ")
			end tell

			missing value
		end getCurrentFilePath
	end script
end decorate
