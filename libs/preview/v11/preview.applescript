(*
	Library wrapper for Preview app.

		@Created: July 14, 2023 6:57 PM
		@Last Modified: 2023-07-14 20:23:57
*)
use scripting additions

use listUtil : script "list"
use textUtil : script "string"
use loggerFactory : script "logger-factory"

use kbLib : script "keyboard"
use retryLib : script "retry"

use spotScript : script "spot-test"

property logger : missing value
property kb : missing value
property retry : missing value

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
		
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck

(*  *)
on new()
	loggerFactory's inject(me)
	
	set kb to kbLib's new()
	set retry to retryLib's new()
	
	script PreviewInstance
		(* Creates a new file based on the image available from the clipboard. *)
		on newFromClipboard()
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
			_triggerGoToFolder()
			_waitForGoToFolderInputField()
			_enterSavePath(saveLocation)
			_waitToFindSavePath()
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
		
	end script
end new
