global std, configSystem, unic, textUtil, listUtil, finder, kb
global ST_CLI

use script "Core Text Utilities"
use scripting additions

(*
	The app Sublime Text behaves differently as compared to first party Apple apps in terms of how it handles its windows. 
	Each individual project tabs are not treated as separate windows as compared to first party apps.

	@Usage:
       	set st to std's import("sublime-text")'s new  -- Text Expander: "sset st"
		
	@Installation:
		From this sub-directory, run: `make install`

	@Known Issues:
		The handler isCurrentFileNewUnsaved is broken when the front window does 
		not have a saved project.


 	NOTE: if AXDocument is missing, usually when filename is missing value then restart Sublime Text.
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "sublime-text-spotCheck"
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: Current File details (No file, Find Result, Ordinary File)
		Focus Window - AppleScript		
		Open File
		Manual: New Unsaved File
		Manual: Switch to Group 1

		Manual: Switch to Group 2
				
		Run Remote File - e2e
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	
	set sut to new()
	if caseIndex is 1 then
		logger's infof("Current Document Name: {}", sut's getCurrentDocumentName())
		logger's infof("Current Project: {}", sut's getCurrentProjectName())
		logger's infof("Current Project Path: {}", sut's getCurrentProjectPath())
		
		logger's infof("Current File Path: {}", sut's getCurrentFilePath())
		logger's infof("Current Resource: {}", sut's getCurrentResource())
		logger's infof("Current Filename: {}", sut's getCurrentFilename())
		logger's infof("Current Base Filename: {}", sut's getCurrentBaseFilename())
		logger's infof("Current File Ext: {}", sut's getCurrentFileExtension())
		
	else if caseIndex is 2 then
		sut's focusWindowEndingWith("applescript-core")
		
	else if caseIndex is 3 then
		sut's openFile(configSystem's getValue("AppleScript Core Project Path") & "/examples/hello.applescript")
		
	else if caseIndex is 4 then
		logger's infof("New Unsaved File: {}", sut's isCurrentFileNewUnsaved())
		
	else if caseIndex is 5 then
		activate application "Sublime Text"
		sut's focusGroup1()
		
	else if caseIndex is 6 then
		activate application "Sublime Text"
		sut's focusGroup2()
		
	else if caseIndex is 11 then
		
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
	script SublimeTextInstance
		
		on openFile(filePath)
			set openShellCommand to format {"{} {}", {ST_CLI, quoted form of filePath}}
			do shell script openShellCommand
		end openFile
		
		
		(* Retrieves the current document name by parsing the window title. *)
		on getCurrentDocumentName()
			if running of application "Sublime Text" is false then return missing value
			
			set filename to missing value
			tell application "System Events" to tell process "Sublime Text"
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
			if running of application "Sublime Text" is false then return missing value
			
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
			Works by detecting a file image in the window title. Does not work 
			if the workspace was not saved as a project.
		*)
		on isCurrentFileNewUnsaved()
			if running of application "Sublime Text" is false then return missing value
			
			tell application "System Events" to tell process "Sublime Text"
				if (count of windows) is 0 then return missing value
				
				not (exists (image 1 of window 1)) -- When there's file icon, it means it is a saved file.
			end tell
		end isCurrentFileNewUnsaved
		
		
		(*
			Cases:
				Find Result
				Non-Loaded
				File is loaded
		*)
		on getCurrentFilePath()
			set docName to getCurrentDocumentName()
			if docName is "Find Results" or docName is missing value or isCurrentFileNewUnsaved() then return missing value
			
			set filename to missing value
			tell application "System Events" to tell process "Sublime Text"
				tell first window
					set filename to value of attribute "AXDocument"
					assertThat of std given condition:filename is not missing value, messageOnFail:"Filename is missing, you may need to restart sublime text"
				end tell
			end tell
			
			if filename is missing value then
				tell me to error "Could not get the document, try re-opening the project tab"
			end if
			
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
		
		
		on focusWindowByKM(windowName as text)
			tell application "Keyboard Maestro Engine"
				setvariable "windowTitle" to windowName
				
				do script "Window to Frontmost - Sublime Text"
			end tell
		end focusWindowByKM
		
		
		on getVisibleWindows()
			tell application "System Events" to tell process "Sublime Text"
				(windows whose subrole is "AXStandardWindow")
			end tell
		end getVisibleWindows
		
		(*
	@return false if exception encountered, likely the window was not found,
	otherwise it returns true for success.
*)
		on focusWindowContaining(titleSubstring as text)
			tell application "System Events" to tell process "Sublime Text"
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
			if running of application "Sublime Text" is false then
				error "Sublime Text app is not running."
			end if
			
			tell application "System Events" to tell process "Sublime Text"
				try
					click (first menu item of menu 1 of menu bar item "Window" of menu bar 1 whose title ends with endingName)
					return true
				end try
			end tell

			false
		end focusWindowEndingWith
		
		
		(*
			ST3 does not respond to activate
			@return false when the app is not running
		*)
		on activateWindow()
			if not running of application "Sublime Text" then return false
			
			-- Battleground shit, not working.
			tell application "System Events" to tell process "Sublime Text" to set frontmost to true
			
			return true
		end activateWindow
		
		
		(* Get the resource path of the front most Sublime Text window. *)
		on getCurrentResource()
			set docName to getCurrentDocumentName()
			if docName is "Find Results" or docName is missing value or isCurrentFileNewUnsaved() then return missing value
			
			set filename to ""
			tell application "System Events" to tell process "Sublime Text"
				tell front window
					set windowName to its name
					
					set filename to value of attribute "AXDocument"
					assertThat of std given condition:filename is not missing value, messageOnFail:"Filename is missing, you may need to restart Sublime Text"
					
				end tell
			end tell
			
			set projectNameRaw to last item of textUtil's split(windowName, SEPARATOR of unic)
			-- set projectName to _findProjectFolder(projectNameRaw, filename) -- BROKEN
			set projectName to getCurrentProjectName()
			set filename to textUtil's replace(filename, "%20", " ")
			set startIndex to (offset of projectName in filename) + (length of projectName) + 1
			
			textUtil's substringFrom(filename, startIndex)
		end getCurrentResource
		
		(*
			Returns the names of focused projects for each Sublime Text windows.
		*)
		on getWindowProjectNames()
			if not running of application "Sublime Text" then return

			tell application "System Events" to tell process "Sublime Text"
				set windowNames to the name of windows
				set projectNames to {}
				repeat with nextWindowTitle in windowNames
					set end of projectNames to the last item of textUtil's split(nextWindowTitle, unic's separator)
				end repeat
			end tell
			projectNames
		end getWindowProjectNames


		on getOpenProjectNames()
			if not running of application "Sublime Text" then return {}

			set projectNames to {}
			tell application "System Events" to tell process "Sublime Text"
				try
					repeat with i from (count of menu items of menu 1 of menu bar item "Window" of menu bar 1) to 1 by -1
						set nextMenu to menu item i of menu 1 of menu bar item "Window" of menu bar 1
						set nextMenuName to the name of nextMenu
						if nextMenuName is missing value then exit repeat
						
						set end of projectNames to last item of textUtil's split(nextMenuName, unic's separator)
					end repeat
				end try
			end tell
			projectNames
		end getOpenProjectNames


		on getWindowsCount()
			if not running of application "Sublime Text" then return 0

			tell application "System Events" to tell process "Sublime Text"
				count of windows
			end tell
		end getWindowsCount

		(*
			Get project of the front most Sublime Text window.
			Might not work if the opened resource is not part of a saved project.
		*)
		on getCurrentProjectName()
			tell application "System Events" to tell process "Sublime Text"
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
		end getCurrentProjectName
		
		
		(*
			@return e.g. lib/resource.c
		*)
		on getCurrentProjectResource(project)
			set filename to ""
			tell application "System Events"
				tell process "Sublime Text"
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
		
		
		on closeProject()
			if running of application "Sublime Text" is false then return

			tell application "System Events" to tell process "Sublime Text"
				try
					click menu item "Close Project" of menu 1 of menu bar item "Project" of menu bar 1
				end try
			end tell
		end closeProject
		

		(* Sends a close tab key stroke combination. *)
		on closeTab()
			kb's pressCommandKey("w")
		end closeTab
		
		
		on focusGroup1()
			kb's pressCommandKey("k")
			kb's pressCommandKey("left")
		end focusGroup1
		
		
		on focusGroup2()
			kb's pressCommandKey("k")
			kb's pressCommandKey("right")
		end focusGroup2
		
		
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
	
	std's applyMappedOverride(result)
end new


(* Constructor. When you need to load another library, do it here. *)
on init()
	set ST_CLI to quoted form of (do shell script "plutil -extract \"Sublime Text CLI\" raw ~/applescript-core/config-system.plist")
	
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("sublime-text")
	set configSystem to std's import("config")'s new("system")
	set unic to std's import("unicodes")
	set textUtil to std's import("string")
	set listUtil to std's import("list")
	set finder to std's import("finder")'s new()
	set kb to std's import("keyboard")'s new()
end init
