(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Cursor/2.5/dec-cursor-current-file

	@Created: Thu, Feb 26, 2026 at 03:53:46 PM
	@Last Modified: 2026-03-12 10:55:58
	@Change Logs:
*)
use textUtil : script "core/string"
use unic : script "core/unicodes"
use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

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
	logger's infof("Current filename: {}", sut's getCurrentFilename())
	logger's infof("Current base filename: {}", sut's getCurrentBaseFilename())

	if caseIndex is 1 then

	else if caseIndex is 2 then

	else if caseIndex is 3 then

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(* @mainScript - script "core/cursor" *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script CurrentFileDecorator
		property parent : mainScript

		on getCurrentFilename()
			tell application "System Events" to tell process "Cursor"
				set windowTitle to title of window 1
			end tell

			if windowTitle does not contain unic's SEPARATOR then return windowTitle

			textUtil's split(windowTitle, unic's SEPARATOR)
			first item of result

		end getCurrentFilename


		on getCurrentBaseFilename()
			set filename to getCurrentFilename()
			if filename is missing value then return missing value

			set baseFilename to first item of listUtil's split(filename, ".")
			if baseFilename is "" then return missing value

			baseFilename
		end getCurrentBaseFilename


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
