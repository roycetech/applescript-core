(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Cursor/2.5/dec-cursor-current-file

	@Created: Thu, Feb 26, 2026 at 03:53:46 PM
	@Last Modified: 2026-03-20 16:07:45
	@Change Logs:
*)
use textUtil : script "core/string"
use unic : script "core/unicodes"
use listUtil : script "core/list"
use fileUtil : script "core/file"

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

	logger's infof("Project path: {}", sut's getProjectPath())
	logger's infof("Current file path: {}", sut's getCurrentFilePath())
	logger's infof("Current filename: {}", sut's getCurrentFilename())
	logger's infof("Current base filename: {}", sut's getCurrentBaseFilename())
	logger's infof("Current file extension: {}", sut's getCurrentFileExtension())

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


		(*
			Retrofitted from visual-studio-code.
		*)
		on getProjectPath()
			set projectName to getCurrentProjectName() -- Diverged from vsc in the handler name to get the project name.
			logger's debugf("projectName: {}", projectName)

			if projectName is missing value then return missing value

			(* Extract path from the window title. *)
			(*
			tell application "System Events" to tell process "Cursor"
				title of front window
				textUtil's split(result, unic's SEPARATOR)
			end tell
			first item of result
			textUtil's stringBefore(result, projectName) & projectName
			fileUtil's expandPath(result)
			*)
			textUtil's stringBefore(getCurrentFilePath(), projectName) & projectName
		end getProjectPath


		on getCurrentFilename()
			tell application "System Events" to tell process "Cursor"
				set windowTitle to title of window 1
			end tell

			if windowTitle does not contain unic's SEPARATOR then return windowTitle

			textUtil's split(windowTitle, unic's SEPARATOR)
			first item of result

		end getCurrentFilename


		on getCurrentFileExtension()
			set filename to getCurrentFilename()
			if filename is missing value then return missing value

			set fileExtension to textUtil's stringAfter(filename, ".")
			if fileExtension is "" or fileExtension is missing value then return missing value

			fileExtension
		end getCurrentFileExtension


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
