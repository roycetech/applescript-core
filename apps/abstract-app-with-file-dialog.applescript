(*
	@Purpose:
		This script serves as the base script for application wrapper scripts that utilizes a file dialog either to open or to save a file.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/abstract-app-with-file-dialog

	@Created: Sat, Feb 28, 2026 at 07:20:19 PM
	@Last Modified: 2026-03-24 17:31:28
*)
use scripting additions

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"
use kbLib : script "core/keyboard"

property logger : missing value

property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		NOOP
		Manual: Safari example
		Manual: Go To Folder
		Manual: Cursor example
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set safariLab to script "core/safari"
	set safari to safariLab's new()
	logger's debugf("Unit test: Expand home: {}", safari's expandPath("~"))
	logger's debugf("Unit test: Expand subpath: {}", safari's expandPath("~/Documents"))
	logger's debugf("Unit test: Expand non-home: {}", safari's expandPath("/Applications"))

	if caseIndex is 1 then

	else if caseIndex is 2 then
		logger's infof("Has file access: {}", safari's hasFileAccess())
		set kbLib to script "core/keyboard"
		set kb to kbLib's new()
		tell application "System Events" to tell process "Safari"
			set frontmost to true
		end tell
		kb's pressCommandKey("s")
		delay 0.5

		set hasDialogWindowResult to safari's hasFileDialogWindow()
		logger's infof("Has dialog window: {}", hasDialogWindowResult)
		if hasDialogWindowResult then
			set fileDialogGetTypeResult to safari's fileDialogGetType()
			logger's infof("File dialog type: {}", fileDialogGetTypeResult)
		end if

		safari's fileDialogGoToFolder()
		set sutPath to safari's expandPath("~/Downloads/")
		logger's debugf("sutPath: {}", sutPath)

		safari's fileDialogEnterPath(sutPath)
		safari's fileDialogAcceptFoundPath()
		safari's fileDialogChooseSelectionWithAction("Save")

		activate

	else if caseIndex is 3 then
		set safariLab to script "core/safari"
		set safari to safariLab's new()
		set hasDialogWindowResult to safari's hasFileDialogWindow()
		logger's infof("Has dialog window: {}", hasDialogWindowResult)
		if hasDialogWindowResult then
			safari's fileDialogGoToFolder()

		end if

	else if caseIndex is 4 then
		set cursorLab to script "core/cursor"
		set kbLib to script "core/keyboard"
		set cursor to cursorLab's new()
		set kb to kbLib's new()
		cursor's _focusApp()
		kb's pressCommandKey("o")

		set hasDialogWindowResult to cursor's hasFileDialogWindow()
		logger's infof("Has dialog window: {}", hasDialogWindowResult)

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*
	NOTE: Requires recompilation when spot checking.
*)
on new(pProcessName)
	loggerFactory's inject(me)
	set baseApp to script "core/base-app"
	set kb to kbLib's new()

	script AbstractAppWithFileDialogInstance
		property parent : baseApp
		property processName : pProcessName
		property dialogWindowReference : 1
		-- property doSetDialogTypeAsWindowReference : true
		property doSetDialogTypeAsWindowReference : false

		(*
			@Overrides
		*)
		on hasFileAccess()
			true
		end hasFileAccess

		on hasFileDialogWindow()
			tell application "System Events" to tell process processName
				exists (sheet 1 of window dialogWindowReference)
			end tell
		end hasFileDialogWindow


		on fileDialogSheetUI()
			tell application "System Events" to tell process (my processName)
				try
					return sheet 1 of window (my dialogWindowReference)

				end try
			end tell
			missing value
		end fileDialogSheetUI


		(*
			@returns the type of file dialog window. "Save" or "Open"
		*)
		on fileDialogGetType()
			if not hasFileDialogWindow() then
				logger's debug("Dialog window was not found")
				return missing value
			end if

			tell application "System Events" to tell process processName
				try
					return the name of button 3 of splitter group 1 of my fileDialogSheetUI()
				on error the errorMessage number the errorNumber
					log errorMessage

				end try
			end tell

			missing value
		end fileDialogGetType


		on fileDialogGoToFolder()
			set dialogType to fileDialogGetType()
			if my doSetDialogTypeAsWindowReference then set my dialogWindowReference to dialogType

			tell application "System Events" to tell process processName
				set frontmost to true
				try
					perform action "AXRaise" of window (my dialogWindowReference)
				end try
			end tell
			kb's pressCommandShiftKey("g")

			set retry to retryLib's new()
			script WaitInputField
				tell application "System Events" to tell process processName
					if exists (text field 1 of sheet 1 of window (my dialogWindowReference)) then return true
					if exists (text field 1 of sheet 1 of sheet 1 of window (my dialogWindowReference)) then return true
				end tell
			end script
			exec of retry on result for 10
		end fileDialogGoToFolder


		on fileDialogEnterPath(newPath)
			set calcPath to expandPath(newPath)
			kb's insertTextByPasting(newPath)

			set retry to retryLib's new()
			script WaitFoundPath
				tell application "System Events" to tell process processName
					if exists (row 2 of table 1 of scroll area 1 of sheet 1 of window (my dialogWindowReference)) then return true
					if exists (row 2 of table 1 of scroll area 1 of sheet 1 of sheet 1 of window (my dialogWindowReference)) then return true
				end tell
			end script
			exec of retry on result for 10
		end fileDialogEnterPath


		on fileDialogAcceptFoundPath()
			kb's pressKey("return")
		end fileDialogAcceptFoundPath


		on fileDialogChooseSelectionWithAction(actionLabel)
			tell application "System Events" to tell process processName
				click button actionLabel of splitter group 1 of my fileDialogSheetUI()
			end tell
		end fileDialogChooseSelectionWithAction


		(*
			@Created: Wed, Mar 04, 2026, at 08:20:56 AM
		*)
		on expandPath(tildePath)
			set posixPath to tildePath

			(*
			if tildePath is "~" then
				-- set posixPath to format("/Users/{}", std's getUsername())
				set posixPath to POSIX path of (path to home folder)

			else if tildePath starts with "~" then
				set posixPath to format("/Users/{}/{}", {std's getUsername(), text 3 thru -1 of posixPath})

			end if
			*)

			if tildePath starts with "~" then
				set posixPath to text 1 thru -2 of POSIX path of (path to home folder)

				if tildePath is not "~" then
					set posixPath to posixPath & "/" & text 3 thru -1 of tildePath
				end if
			end if

			posixPath
		end expandPath

	end script
end new
