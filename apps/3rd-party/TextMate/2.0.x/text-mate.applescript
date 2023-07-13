use script "Core Text Utilities"
use scripting additions

(*
	The app Sublime Text behaves differently as compared to first party Apple apps in terms of how it handles its windows. 
	Each individual project tabs are not treated as separate windows as compared to first party apps.

	@Usage:
		use tmLib : script "text-mate"
		property tm : tmLi's new()
	-- Text Expander: "uuse tb"
		
	@Installation:
		make install-text-mate


 	NOTE: if AXDocument is missing, usually when filename is missing value then restart Sublime Text.
*)

use textUtil : script "string"
use listUtil : script "list"
use unic : script "unicodes"

use loggerLib : script "logger"
use configLib : script "config"

use spotScript : script "spot-test"

property logger : loggerLib's new("text-mate")

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	logger's start()
	set configSystem to configLib's new("system")
	
	set cases to listUtil's splitByLine("
		Manual: Current File details (No file, Find Result, Ordinary File)
		Manual: Focus Window
		Manual: Open File
				
		Run Remote File - e2e
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	
	set sut to new()
	if caseIndex is 1 then
		logger's infof("Current Document Name: {}", sut's getCurrentDocumentName())
		logger's infof("Current Project Folder Name: {}", sut's getCurrentProjectFolderName())
		logger's infof("Current Project Path: {}", sut's getCurrentProjectPath())
		
		logger's infof("Current File Path: {}", sut's getCurrentFilePath())
		logger's infof("Current Resource: {}", sut's getCurrentResource())
		logger's infof("Current Filename: {}", sut's getCurrentFilename())
		logger's infof("Current Base Filename: {}", sut's getCurrentBaseFilename())
		logger's infof("Current File Ext: {}", sut's getCurrentFileExtension())
		
	else if caseIndex is 2 then
		sut's focusWindowEndingWith("Delete Daily")
		
	else if caseIndex is 3 then
		-- sut's openFile(configSystem's getValue("AppleScript Core Project Path") & "/examples/hello.applescript")
		sut's openFile(configSystem's getValue("AppleScript Core Project Path") & "/examples/what's up.applescript")
		
		
	else if caseIndex is 11 then
		activate application "TextMate"
		
		set doc1name to getDocumentName()
		focusGroup1()
		set doc2name to getDocumentName()
		if doc1name is equal to doc2name then
			log "same doc"
		else
			log "diff doc"
		end if
		
		focusGroup2()
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	script TextMateInstance
		on openFile(filePath)
			set partiallyEncoded to textUtil's replace(filePath, " ", "%20")
			set mateUrl to format {"txmt://open/?url=file://{}", partiallyEncoded}
			open location mateUrl
		end openFile
		
		
		(* Retrieves the current document name by parsing the window title. *)
		on getCurrentDocumentName()
			if running of application "TextMate" is false then return missing value
			
			set filename to missing value
			tell application "System Events" to tell process "TextMate"
				if (count of windows) is 0 then return missing value
				
				set windomName to name of first window
			end tell
			set windowNameTokens to textUtil's split(windomName, unic's SEPARATOR)
			first item of windowNameTokens
		end getCurrentDocumentName
		
		
		on getCurrentProjectPath()
			set filePath to getCurrentFilePath()
			if filePath is missing value then return missing value
			textUtil's replace(filePath, "/" & getCurrentResource(), "")
		end getCurrentProjectPath
		
		
		on getCurrentFilename()
			if running of application "TextMate" is false then return missing value
			
			set currentFilePath to getCurrentFilePath()
			if currentFilePath is missing value then return missing value
			
			last item of listUtil's split(currentFilePath, "/")
		end getCurrentFilename
		
		
		(* @returns the filename without the extension. *)
		on getCurrentBaseFilename()
			set filename to getCurrentFilename()
			if filename is missing value then return missing value
			
			set baseFilename to first item of listUtil's split(filename, ".")
			if baseFilename is "" then return missing value
			
			baseFilename
		end getCurrentBaseFilename
		
		
		(*
			Cases:
				Find Result
				Non-Loaded
				File is loaded
		*)
		on getCurrentFilePath()
			set docName to getCurrentDocumentName()
			set filename to missing value
			tell application "System Events" to tell process "TextMate"
				tell first window
					set filename to value of attribute "AXDocument"
				end tell
			end tell
			
			set filename to textUtil's stringAfter(filename, "file://")
			textUtil's replace(filename, "%20", " ")
		end getCurrentFilePath
		
		
		(*
			@deprecated, use getCurrentFileExtension().
			@returns the extension of the current file, considering special cases.
		*)
		on getCurrentFileType()
			getFileType()
		end getCurrentFileType
		
		
		(*
			Cases covered:
				Find Results
				No extension
				Extension only
		*)
		on getCurrentFileExtension()
			set docName to getCurrentDocumentName()
			if docName is "Find Results" or docName is missing value or isCurrentFileNewUnsaved() then return missing value
			
			set filenameTokens to textUtil's split(docName, ".")
			if the number of items in filenameTokens is 1 then return missing value
			last item of filenameTokens
		end getCurrentFileExtension
		
		
		on getVisibleWindows()
			tell application "System Events" to tell process "TextMate"
				(windows whose subrole is "AXStandardWindow")
			end tell
		end getVisibleWindows
		
		(*
	@return false if exception encountered, likely the window was not found,
	otherwise it returns true for success.
*)
		to focusWindowContaining(titleSubstring as text)
			tell application "System Events" to tell process "TextMate"
				try
					click (first menu item of menu 1 of menu bar item "Window" of menu bar 1 whose title contains titleSubstring)
					true
				on error
					return false
				end try
			end tell
		end focusWindowContaining
		
		(*
			Will fail when there are multiple folders open in a project.

			@return false if exception encountered, likely the window was not found,
			otherwise it returns true for success.
		*)
		on focusWindowEndingWith(endingName)
			if running of application "TextMate" is false then
				error "TextMate app is not running."
			end if
			
			tell application "System Events" to tell process "TextMate"
				try
					click (first menu item of menu 1 of menu bar item "Window" of menu bar 1 whose title ends with endingName)
					return true
				end try
				return false
			end tell
		end focusWindowEndingWith
		
		
		(*
			ST3 does not respond to activate
			@return false when the app is not running
		*)
		on activateWindow()
			if not running of application "TextMate" then return false
			
			-- Battleground shit, not working.
			tell application "System Events" to tell process "Sublime Text" to set frontmost to true
			
			return true
		end activateWindow
		
		
		(* Get the resource path of the front most Sublime Text window. *)
		on getCurrentResource()
			set docName to getCurrentDocumentName()
			if docName is "Find Results" or docName is missing value or isCurrentFileNewUnsaved() then return missing value
			
			set filename to ""
			tell application "System Events" to tell process "TextMate"
				tell front window
					set windowName to its name
					
					set filename to value of attribute "AXDocument"
					assertThat of std given condition:filename is not missing value, messageOnFail:"Filename is missing, you may need to restart Sublime Text"
					
				end tell
			end tell
			
			-- logger's debugf("windowName: {}", windowName)
			
			set projectFolderName to last item of textUtil's split(windowName, SEPARATOR of uni)
			-- logger's debugf("projectFolderName: {}", projectFolderName)
			set filename to textUtil's replace(filename, "%20", " ")
			set startIndex to (offset of projectFolderName in filename) + (length of projectFolderName) + 1
			
			textUtil's substringFrom(filename, startIndex)
		end getCurrentResource
		
		(*
			Get project of the front most Sublime Text window.
			Might not work if the opened resource is not part of a saved project.
		*)
		on getCurrentProjectFolderName()
			tell application "System Events" to tell process "TextMate"
				tell front window
					set windowTitle to get value of attribute "AXTitle"
					if windowTitle is "" then
						return missing value
					end if
					
					(*
					set oldDelimiters to AppleScript's text item delimiters
					set AppleScript's text item delimiters to unic's SEPARATOR
					set theArray to every text item of theWindowTitle
					set retval to last item of theArray
					set AppleScript's text item delimiters to oldDelimiters
					return retval
					*)
				end tell
			end tell
			
			set csv to textUtil's split(windowTitle, ",")
			set projectPart to first item of csv
			set filenameAndProject to textUtil's split(projectPart, unic's SEPARATOR)
			last item of filenameAndProject
		end getCurrentProjectFolderName
		
		
		(*
			@return e.g. lib/resource.c
		*)
		on getCurrentProjectResource(project)
			set filename to ""
			tell application "System Events"
				tell process "TextMate"
					logger's debug("Looking for the project window...")
					
					try
						set theWindow to first window whose value of attribute "AXTitle" ends with project
						if not (theWindow exists) then
							tell me to error "The project: " & project & " could not be found"
						end if
						logger's debug("Window found")
					on error the error_message number the error_number
						display dialog "Error: " & the error_number & ". " & the error_message buttons {"OK"} default button 1
					end try
					
					tell theWindow
						set filename to value of attribute "AXDocument"
						assertThat of std given condition:filename is not missing value, messageOnFail:"Filename is missing, you may need to restart ST3"
						logger's debug("Filename: " & filename)
					end tell
				end tell
			end tell
			
			set filename to textUtil's replace(filename, "%20", " ")
			set startIndex to (offset of project in filename) + (length of project) + 1
			
			return textUtil's substringFrom(filename, startIndex)
		end getCurrentProjectResource
		
		
		(* Sends a close tab key stroke combination. *)
		on closeTab()
			if running of application "TextMate" is false then return
			
			activate application "TextMate"
			kb's pressCommandKey("w")
		end closeTab
		
		
		
		-- Private Codes below =======================================================
		(* 
			Determines the project name by tokenizing the Sublime Text title and checking if the token exists in the full filename of the 
			active editor file. 
		*)
		on _findProjectFolder(projectNameRaw, filename)
			repeat with nextFolder in textUtil's split(projectNameRaw, ", ")
				if filename contains nextFolder then
					return nextFolder
				end if
			end repeat
			tell me to error "I can't find your project folder from: " & projectNameRaw
		end _findProjectFolder
	end script
	
	overrider's applyMappedOverride(result)
end new
