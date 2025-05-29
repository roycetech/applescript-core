(*
	@Purpose:
		To be used to interact with file/folder selection from another app (e.g. Choose file/folder, Save to, etc.).

	Repurposed from Automator.applescript.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Finder/15.2/finder-mini

	@Created: Monday, December 30, 2024 at 11:56:11 AM
	@Last Modified: 2025-01-09 15:22:29
*)
use script "core/Text Utilities"

use std : script "core/std"

use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"
use retryLib : script "core/retry"

property logger : missing value
property kb : missing value
property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set spotScript to script "core/spot-test"
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Trigger go to Folder
		Manual: Enter Path
		Manual: Accept found path
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

	else if caseIndex is 2 then
		-- tell application "System Events" to tell process "Preview"
		tell application "System Events" to tell process "CleanShot X"
			set frontmost to true
			perform action "AXRaise" of window "Open"
		end tell
		sut's triggerGoToFolder()

	else if caseIndex is 3 then
		tell application "System Events" to tell process "CleanShot X"
			set frontmost to true
		end tell

		sut's enterPath("~/Desktop")

	else if caseIndex is 4 then
		tell application "System Events" to tell process "CleanShot X"
			set frontmost to true
		end tell
		sut's acceptFoundPath()
	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new(pProcessName)
	loggerFactory's inject(me)
	set kb to kbLib's new()
	set retry to retryLib's new()

	script FinderMiniInstance
		property processName : pProcessName

		on triggerGoToFolder()
			tell application "System Events" to tell process processName
				try
					perform action "AXRaise" of window "Open"
				end try
			end tell
			kb's pressCommandShiftKey("g")

			script WaitInputField
				tell application "System Events" to tell process processName
					if exists (text field 1 of sheet 1 of window "Open") then return true
				end tell
			end script
			exec of retry on result for 10
		end triggerGoToFolder


		on enterPath(newPath)
			set calcPath to untilde(newPath)
			kb's insertTextByPasting(newPath)

			script WaitFoundPath
				tell application "System Events" to tell process processName
					if exists (row 2 of table 1 of scroll area 1 of sheet 1 of window "Open") then return true
				end tell
			end script
			exec of retry on result for 10
		end enterPath


		on acceptFoundPath()
			kb's pressKey("return")
		end acceptFoundPath


		on chooseSelection()
			tell application "System Events" to tell process processName
				click button "Choose" of window "Open"
			end tell
		end chooseSelection


		on untilde(tildePath)
			set posixPath to tildePath
			if tildePath is "~" then
				set posixPath to format {"/Users/{}/", std's getUsername()}
			else if tildePath starts with "~" then
				set posixPath to format {"/Users/{}/{}", {std's getUsername(), text 3 thru -1 of posixPath}}
			end if
			posixPath
		end untilde

	end script
end new
