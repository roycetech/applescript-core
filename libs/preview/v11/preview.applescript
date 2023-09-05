(*
	Library wrapper for Preview app.

		@Created: July 14, 2023 6:57 PM
		@Last Modified: 2023-09-05 12:05:52
*)
use scripting additions

use listUtil : script "list"
use textUtil : script "string"
use windowUtilLib : script "window"

use loggerFactory : script "logger-factory"

use kbLib : script "keyboard"
use retryLib : script "retry"

use spotScript : script "core/spot-test"

property logger : missing value
property kb : missing value
property retry : missing value
property windowUtil : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	(* These test cases are run in order. *)
	set cases to listUtil's splitByLine("
		Manual: New From Clipboard
		Manual: Trigger File > Save
		Manual: Set export filename
		Manual: Select format
		Manual: Set Destination

		Manual: Trigger Save Button
		Manual: Find Tab
		Manual: Front Tab (TODO)
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
		sut's newFromClipboard()

	else if caseIndex is 2 then
		sut's triggerFileSave()

	else if caseIndex is 3 then
		sut's setExportFilename("spot.png")

	else if caseIndex is 4 then
		sut's selectFormat("PNG")

	else if caseIndex is 5 then
		activate application "Preview"

		tell application "Finder"
			properties of folder "Delete Daily" of (path to home folder)
			set deleteDailyPath to textUtil's replace(textUtil's stringAfter(URL of folder "Delete Daily" of (path to home folder) as text, "file://"), "%20", " ")
		end tell

		logger's debugf("deleteDailyPath: {}", deleteDailyPath)
		sut's setSaveLocationPosixPath(deleteDailyPath)

	else if caseIndex is 6 then
		sut's triggerSave()

	else if caseIndex is 7 then
		sut's findTabWithName("x")

	else if caseIndex is 8 then
		set frontTab to sut's getFrontTab()
		if frontTab is missing value then
			logger's info("Front tab was not found")
		else
			logger's infof("File Path: {}", frontTab's getFilePath())
		end if

	end if

	spot's finish()
	logger's finish()
end spotCheck

(*  *)
on new()
	loggerFactory's inject(me)
	set windowUtil to windowUtilLib's new()

	set kb to kbLib's new()
	set retry to retryLib's new()

	script PreviewInstance

		(*
			Creates a new file based on the image available from the clipboard.
			Grabs focus.
		*)
		on newFromClipboard()
			if running of application "Preview" is false then
				activate application "Preview"
				delay 1
			end if

			tell application "System Events" to tell process "Preview"
				if enabled of menu item "New from Clipboard" of menu 1 of menu bar item "File" of menu bar 1 is false then
					error "New from Clipboard menu item is disabled, check that you can copy the item properly before triggering this"
				end if
			end tell

			activate application "Preview"
			delay 0.1
			tell application "System Events" to tell process "Preview"
				try
					click menu item "New from Clipboard" of menu 1 of menu bar item "File" of menu bar 1
				end try
			end tell
		end newFromClipboard

		(*
			Triggers File > Save... from the menu.

			@Warning: App will get focus

		*)
		on triggerFileSave()
			if running of application "Preview" is false then return

			activate application "Preview"
			tell application "System Events" to tell process "Preview"
				try
					click (first menu item of menu 1 of menu bar item "File" of menu bar 1 whose title starts with "Save")
				end try
			end tell
			delay 1 -- convert to wait later.
		end triggerFileSave

		(*
			Used after triggering File > Save.
		*)
		on setExportFilename(filename)
			if running of application "Preview" is false then return

			tell application "System Events" to tell process "Preview"
				set value of text field 1 of sheet 1 of front window to filename
			end tell
		end setExportFilename


		(*
			@saveLocation - posix path to the save location.
		*)
		on setSaveLocationPosixPath(saveLocation)
			logger's debug("Triggering goto folder")
			_triggerGoToFolder()
			logger's debug("Waiting for the input field")
			_waitForGoToFolderInputField()
			logger's debug("Entering the save path")
			_enterSavePath(saveLocation)
			logger's debug("Wait to find save path")
			_waitToFindSavePath()
			logger's debug("Accepting the found save path")
			_acceptFoundSavePath()
		end setSaveLocationPosixPath


		on selectFormat(formatKey)
			if running of application "Preview" is false or formatKey is missing value then return

			tell application "System Events" to tell process "Preview"
				set formatDropDown to pop up button 2 of sheet 1 of front window
				click formatDropDown
				delay 0.1

				try
					click (first menu item of menu 1 of formatDropDown whose title is formatKey)
				on error
					kb's pressKey("esc") -- dismiss popup on error
				end try
			end tell
		end selectFormat


		(*
			Used after triggering File > Save.
		*)
		on triggerSave()
			if running of application "Preview" is false then return

			tell application "System Events" to tell process "Preview"
				click button "Save" of sheet 1 of front window
			end tell
		end triggerSave


		on _triggerGoToFolder()
			kb's pressCommandShiftKey("g")
			-- _enterSavePath()
		end _triggerGoToFolder


		(* This handler group can probably go somewhere to improve re-usability. *)
		on _waitForGoToFolderInputField()
			script WaitInputField
				tell application "System Events" to tell process "Preview"
					if exists (text field 1 of sheet 1 of sheet 1 of first window) then return true
				end tell
			end script
			exec of retry on result for 10
		end _waitForGoToFolderInputField

		on _enterSavePath(savePath)
			kb's insertTextByPasting(savePath)
		end _enterSavePath

		on _waitToFindSavePath()
			script WaitFoundPath
				tell application "System Events" to tell process "Preview"
					if exists (row 2 of table 1 of scroll area 1 of sheet 1 of sheet 1 of front window) then return true
				end tell
			end script
			exec of retry on result for 10
		end _waitToFindSavePath

		on _acceptFoundSavePath()
			kb's pressKey("return")
		end _acceptFoundSavePath


		on findTabWithName(documentName)
			try
				tell application "Preview"
					set appWindow to first window whose name is documentName
				end tell
				return _new(appWindow)
			end try

			missing value
		end findTabWithName

		on getFrontTab()
			if not windowUtil's hasWindow("Preview") then return missing value

			_new(front window of application "Preview")
		end getFrontTab


		on _new(pAppWindow)
			script PreviewTabInstance
				property appWindow : pAppWindow

				on getFilePath()
					tell application "Preview"
						path of document of my appWindow
					end tell
				end getFilePath

				on focus()
					try
						tell application "System Events" to tell process "Preview"
							click (first menu item of first menu of menu bar item "Window" of first menu bar whose title is equal to name of my appWindow)
						end tell
						true
					on error
						false
					end try
				end focus

				on closeTab()
					tell appWindow to close
				end closeTab

				on fullScreen()
					focus()
					activate application "Preview"
					tell application "System Events" to tell process "Preview"
						try
							click menu item "Enter Full Screen" of menu 1 of menu bar item "View" of menu bar 1
						end try
					end tell
				end fullScreen
			end script
		end _new

	end script
end new
