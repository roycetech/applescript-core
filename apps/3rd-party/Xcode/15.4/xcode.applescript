(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Xcode/15.4/xcode

	@Created: Monday, May 27, 2024 at 1:22:50 PM
	@Last Modified: 2024-05-31 16:10:02
*)

use textUtil : script "core/string"
use unic : script "core/unicodes"

use loggerFactory : script "core/logger-factory"
use kbLib : script "core/keyboard"


use spotScript : script "core/spot-test"

property logger : missing value
property kb : missing value

property PROJECT_EXT_PLAYGROUND : ".playground"
property PROJECT_EXT_REGULAR : ".xcodeproj"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Quick Open File
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()

	activate application "Xcode"

	-- Manual: Current File details (No file, Find Result, Ordinary File)
	logger's infof("Is Playground: {}", sut's isPlayground())
	logger's infof("Current Project: {}", sut's getCurrentProjectName())
	logger's infof("Current File Path: {}", sut's getCurrentFilePath())
	logger's infof("Current Filename: {}", sut's getCurrentFilename())

	logger's infof("Current Base Filename: {}", sut's getCurrentBaseFilename())
	logger's infof("Current File Ext: {}", sut's getCurrentFileExtension())
	logger's infof("Current Document Name: {}", sut's getCurrentDocumentName())
	logger's infof("Current Project Full Path: {}", sut's getCurrentProjectFullPath())

	(*
	Undefined.
	logger's infof("Current Directory: {}", sut's getCurrentFileDirectory())
	logger's infof("Current Project Path: {}", sut's getCurrentProjectPath())
	logger's infof("Current Resource: {}", sut's getCurrentProjectResource())
	*)
	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's quickOpen("main.m")
	end if

	-- activate

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	set kb to kbLib's new()

	script XcodeInstance
		on quickOpen(filename)
			kb's pressCommandShiftKey("o")
			kb's typeText(filename)
			delay 0.1
			kb's pressKey(return)
		end quickOpen


		on isPlayground()
			tell application "Xcode"
				name of active workspace document ends with ".playground"
			end tell
		end isPlayground


		on getCurrentProjectName()
			set projectNameMarker to my PROJECT_EXT_REGULAR
			if isPlayground() then
				set projectNameMarker to my PROJECT_EXT_PLAYGROUND
			end if

			tell application "Xcode"
				textUtil's stringBefore(name of active workspace document, projectNameMarker)
			end tell
		end getCurrentProjectName


		on getCurrentFilePath()
			if isPlayground() then return getCurrentProjectFullPath()

			missing value
		end getCurrentFilePath


		on getCurrentDocumentName()
			if isPlayground() then
				tell application "Xcode"
					return name of active workspace document

				end tell
			end if

			tell application "Xcode"
				textUtil's stringAfter(name of front window, unic's SEPARATOR)
			end tell
		end getCurrentDocumentName


		on getCurrentFilename()
			getCurrentDocumentName()
		end getCurrentFilename


		on getCurrentBaseFilename()
			if isPlayground() then return getCurrentProjectName()

			tell application "Xcode"
				set filenameFromTitle to textUtil's stringAfter(name of front window, unic's SEPARATOR)
			end tell
			textUtil's stringBefore(filenameFromTitle, ".")
		end getCurrentBaseFilename


		on getCurrentFileExtension()
			if isPlayground() then return text 2 thru -1 of my PROJECT_EXT_PLAYGROUND

			tell application "Xcode"
				set filenameFromTitle to textUtil's stringAfter(name of front window, unic's SEPARATOR)
			end tell
			textUtil's stringAfter(filenameFromTitle, ".")
		end getCurrentFileExtension


		on getCurrentProjectFullPath()
			tell application "Xcode"
				path of active workspace document
			end tell
		end getCurrentProjectFullPath
	end script
end new


