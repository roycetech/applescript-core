(*
	Library wrapper for Pulsar app. Converted from atom.applescript.

	Unable to properly retrieve the document path when an object is focused on the side bar.

	Some document names are reserved for Pulsar and would pose problem if you have actual files with these names:
		Settings
		Project - When a project folder is selected on the side bar
		Project Find Results
		Welcome Guide

	@Last Modified: 2023-09-18 22:33:40
	@Tab: AC 🚧
	@Build:
		make compile-pulsar
*)

use script "core/Text Utilities"
use scripting additions

use std : script "core/std"
use fileUtil : script "core/file"
use unic : script "core/unicodes"
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use listUtil : script "core/list"
use retryLib : script "core/retry"
use configLib : script "core/config"
use spotScript : script "core/spot-test"
use kbLib : script "core/keyboard"
use syseveLib : script "core/system-events"
use clipLib : script "core/clipboard"

property logger : missing value
property configSystem : missing value
property retry : missing value
property kb : missing value
property syseve : missing value
property clip : missing value

property RESERVED_DOC_NAMES : {"Settings", "Project", "Project Find Results", "Welcome Guide"}

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Load File (App Open, Not Running, Already Loaded)
		Manual: Document Info (sample.txt, no file, search result, nav bar focused, Settings)
		Manual: Close Front Tab
		Manual: _extractDocPathByHotkey (Tree View, Editor)
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()
	set sampleNoteFilePath to configSystem's getValue("AppleScript Core Project Path") & "/apps/3rd-party/Pulsar/sample.txt"
	if caseIndex is 1 then
		logger's infof("Note Path: [{}]", sampleNoteFilePath)
		sut's openFile(sampleNoteFilePath)

	else if caseIndex is 2 then
		logger's infof("Current Document Name: [{}]", sut's getCurrentDocumentName())
		logger's infof("Current File Path: [{}]", sut's getCurrentFilePath())
		logger's infof("Current File Directory: [{}]", sut's getCurrentFileDirectory())
		logger's infof("Current File Extension: [{}]", sut's getCurrentFileExtension())
		logger's infof("Current Resource Path: [{}]", sut's getCurrentResourcePath())
		logger's infof("Current Base Filename: [{}]", sut's getCurrentBaseFilename())

	else if caseIndex is 3 then
		sut's closeFrontTab()

		activate

	else if caseIndex is 4 then
		logger's infof("File path from hotkey: [{}]", sut's _extractDocPathByHotkey())

	end if

	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's inject(me)
	set configSystem to configLib's new("system")
	set retry to retryLib's new()
	set kb to kbLib's new()
	set syseve to syseveLib's new()
	set clip to clipLib's new()

	script PulsarInstance
		on openFile(posixPath)
			set pathUrl to posixPath
			-- URL Scheme for pulsar:// did not work, likely on future update.
			open location "atom://core/open/file?filename=" & textUtil's encodeUrl(pathUrl)
		end openFile

		(* @returns Current document name. Missing value if non-file is focused. *)
		on getCurrentDocumentName()
			if running of application "Pulsar" is false then return missing value

			tell application "System Events" to tell process "Pulsar"
				if (count of windows) is 0 then return missing value

				set windowTitle to name of window 1
			end tell

			set tokens to textUtil's split(windowTitle, unic's SEPARATOR)

			set docNameFromTitle to first item of tokens

			if docNameFromTitle is not "Project" then return docNameFromTitle

			set docPath to _extractDocPathByHotkey()
			fileUtil's getBaseFileName(docPath)
		end getCurrentDocumentName


		on getCurrentFileDirectory()
			textUtil's split(getCurrentFilePath(), "/")
			textUtil's join(items 1 thru -2 of result, "/")
		end getCurrentFileDirectory


		(*
			WARNING: Can take a long time to return the value.

			@returns the full document file path. missing value if no document is focused.
		*)
		on getCurrentFilePath()
			if running of application "Pulsar" is false then return missing value

			tell application "System Events" to tell process "Pulsar"
				if (count of windows) is 0 then return missing value

				set windowTitle to name of front window
			end tell

			set titleTokens to textUtil's split(windowTitle, unic's SEPARATOR)
			if the number of titleTokens is 1 then return missing value

			set firstItemInTitle to first item of titleTokens
			if firstItemInTitle is "Project" then return _extractDocPathByHotkey()
			if RESERVED_DOC_NAMES contains firstItemInTitle then return missing value

			tell application "System Events" to tell process "Pulsar"
				set filePath to get value of attribute "AXDocument" of front window
			end tell
			textUtil's decodeUrl(textUtil's stringAfter(filePath, "file://"))
		end getCurrentFilePath

		on closeFrontTab()
			if running of application "Pulsar" is false then return

			tell application "System Events" to tell process "Pulsar"
				set frontmost to true
				try
					click menu item "Close Tab" of menu 1 of menu bar item "File" of menu bar 1
				end try
			end tell
		end closeFrontTab


		on getCurrentFileExtension()
			if running of application "Pulsar" is false then return missing value

			set docName to getCurrentDocumentName()
			if docName is missing value then return missing value

			set filenameTokens to textUtil's split(docName, ".")
			if the (count of filenameTokens) is 1 then return missing value

			last item of filenameTokens
		end getCurrentFileExtension

		on getCurrentBaseFilename()
			if running of application "Pulsar" is false then return missing value

			set docName to getCurrentDocumentName()
			if docName is missing value then return missing value

			set filenameTokens to textUtil's split(docName, ".")
			set firstToken to first item of filenameTokens
			if firstToken is "" or RESERVED_DOC_NAMES contains firstToken then return missing value

			firstToken
		end getCurrentBaseFilename

		(*
			For testing, you need to open the project in Atom. The notes project is a great candidate.
		*)
		on getCurrentResourcePath()
			set docPath to getCurrentFilePath()
			if docPath is missing value then return missing value

			tell application "System Events" to tell process "Pulsar"
				if (count of windows) is 0 then return missing value

				set windowTitle to name of front window
			end tell

			set titleTokens to textUtil's split(windowTitle, unic's SEPARATOR)
			set folderPath to last item of titleTokens
			set expandedFolderPath to textUtil's replace(folderPath, "~", "/Users/" & std's getUsername())
			textUtil's replace(docPath, expandedFolderPath & "/", "")
		end getCurrentResourcePath

		(* Closes all tabs via menu. App needs take focus and you should restore focused app from the client script. *)
		on closeAllTabs()
			activate application "Pulsar"
			tell application "System Events" to tell process "Pulsar"
				perform action "AXPress" of menu item "Close All Tabs" of menu 1 of menu bar item "File" of menu bar 1
			end tell
		end closeAllTabs


		(* *)
		on cleanUp()
			if not running of application "Pulsar" then return

			try
				if running of application "Pulsar" is true then tell application "Pulsar" to quit
			end try

			repeat while running of application "Pulsar" is true
				delay 0.1
			end repeat
		end cleanUp


		-- Private Codes below =======================================================

		(*
			@Requires app focus.
			Unreliable. Does not work when focus is on the Tree View, which is
			the condition used to invoke this handler.
		*)
		on _extractDocPathByHotkey()
			script GetFromClipboard
				activate application "Pulsar"
				delay 0.1
				kb's pressControlShiftKey("c")
			end script
			set docPath to clip's extract(GetFromClipboard)
			docPath
		end _extractDocPathByHotkey
	end script
end new
