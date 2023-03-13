global std, retry, fileUtil, textUtil, cp, kb, uni
global RESERVED_DOC_NAMES

(*
	Library wrapper for Atom app. 
	
	WARNING: Atom app was sunsetted on December, 2022, further use is discouraged.
	
	Unable to properly retrive the document path when an object is focused on the side bar.
	
	Some document names are reserved for Atom and would pose problem if you have actual files with these names:
		Settings
		Project - When a project folder is selected on the side bar
		Project Find Results
		Welcome Guide
*)

use script "Core Text Utilities"
use scripting additions

property logger : missing value
property initialized : false

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "atom-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	set configSystem to std's import("config")'s new("system")
	set cases to listUtil's splitByLine("
		Manual: Load File (App Open, Not Running, Already Loaded)
		Manual: Document Info (sample.txt, no file, search result, nav bar focused, Settings)
		Manual: Close Front Tab		
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	set sampleNoteFilePath to configSystem's getValue("AppleScript Core Project Path") & "/apps/3rd-party/Atom/1.60.0/sample.txt"
	if caseIndex is 1 then
		logger's infof("Note Path: [{}]", sampleNoteFilePath)
		sut's openFile(sampleNoteFilePath)
		
	else if caseIndex is 2 then
		logger's infof("Current Document Name: [{}]", sut's getCurrentDocumentName())
		logger's infof("Current File Path: [{}]", sut's getCurrentFilePath())
		logger's infof("Current File Extension: [{}]", sut's getCurrentFileExtension())
		logger's infof("Current Resource Path: [{}]", sut's getCurrentResourcePath())
		logger's infof("Current Base Filename: [{}]", sut's getCurrentBaseFilename())
		
	else if caseIndex is 3 then
		sut's closeFrontTab()
		
		activate
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	script AtomInstance
		on openFile(posixPath)
			set pathUrl to posixPath
			open location "atom://core/open/file?filename=" & textUtil's encodeUrl(pathUrl)
		end openFile
		
		(* @returns Current document name. Missing value if non-file is focused. *)
		on getCurrentDocumentName()
			if running of application "Atom" is false then return missing value
			
			tell application "System Events" to tell process "Atom"
				if (count of windows) is 0 then return missing value
				
				set windowTitle to name of window 1
			end tell
			
			set tokens to textUtil's split(windowTitle, uni's SEPARATOR)
			
			set docNameFromTitle to first item of tokens
			
			if docNameFromTitle is not "Project" then return docNameFromTitle
			
			set docPath to _extractDocPathByHotkey()
			fileUtil's getBaseFilename(docPath)
		end getCurrentDocumentName
		
		(* 
			WARNING: Can take a long time to return the value.
			
			@returns the full document file path. missing value if no document is focused. 
		*)
		on getCurrentFilePath()
			if running of application "Atom" is false then return missing value
			
			tell application "System Events" to tell process "Atom"
				if (count of windows) is 0 then return missing value
				
				set windowTitle to name of front window
			end tell
			
			set titleTokens to textUtil's split(windowTitle, uni's SEPARATOR)
			if the number of titleTokens is 1 then return missing value
			
			set firstItemInTitle to first item of titleTokens
			if firstItemInTitle is "Project" then return _extractDocPathByHotkey()
			if RESERVED_DOC_NAMES contains firstItemInTitle then return missing value
			
			tell application "System Events" to tell process "Atom"
				set filePath to get value of attribute "AXDocument" of front window
			end tell
			textUtil's decodeUrl(textUtil's stringAfter(filePath, "file://"))
		end getCurrentFilePath
		
		on closeFrontTab()
			if running of application "Atom" is false then return
			
			tell application "System Events" to tell process "Atom"
				set frontmost to true
				try
					click menu item "Close Tab" of menu 1 of menu bar item "File" of menu bar 1
				end try
			end tell
		end closeFrontTab
		
		
		on getCurrentFileExtension()
			if running of application "Atom" is false then return missing value
			
			set docName to getCurrentDocumentName()
			if docName is missing value then return missing value
			
			set filenameTokens to textUtil's split(docName, ".")
			if the (count of filenameTokens) is 1 then return missing value
			
			last item of filenameTokens
		end getCurrentFileExtension
		
		on getCurrentBaseFilename()
			if running of application "Atom" is false then return missing value
			
			set docName to getCurrentDocumentName()
			if docName is missing value then return missing value
			
			set filenameTokens to textUtil's split(docName, ".")
			set firstToken to first item of filenameTokens
			if firstToken is "" or RESERVED_DOC_NAMES contains firstToken then return missing value
			
			firstToken
		end getCurrentBaseFilename
		
		(*
			For testing, you need to open the project in Atom.
		*)
		on getCurrentResourcePath()
			set docPath to getCurrentFilePath()
			if docPath is missing value then return missing value
			
			tell application "System Events" to tell process "Atom"
				if (count of windows) is 0 then return missing value
				
				set windowTitle to name of front window
			end tell
			
			set titleTokens to textUtil's split(windowTitle, uni's SEPARATOR)
			set folderPath to last item of titleTokens
			set expandedFolderPath to textUtil's replace(folderPath, "~", "/Users/" & std's getUsername())
			textUtil's replace(docPath, expandedFolderPath & "/", "")
		end getCurrentResourcePath
		
		(* Closes all tabs via menu. App needs take focus and you should restore focused app from the client script. *)
		on closeAllTabs()
			activate application "Atom"
			tell application "System Events" to tell process "Atom"
				perform action "AXPress" of menu item "Close All Tabs" of menu 1 of menu bar item "File" of menu bar 1
			end tell
		end closeAllTabs
		
		
		(* *)
		on cleanUp()
			if not running of application "Atom" then return
			
			try
				if running of application "Atom" is true then tell application "Atom" to quit
			end try
			
			repeat while running of application "Atom" is true
				delay 0.1
			end repeat
		end cleanUp
		
		
		-- Private Codes below =======================================================
		
		(*
			@Requires app focus.
		*)
		on _extractDocPathByHotkey()
			script GetFromClipboard
				activate application "Atom"
				kb's pressControlShiftKey("c")
			end script
			set docPath to cp's extract(GetFromClipboard)
			docPath
		end _extractDocPathByHotkey
	end script
	std's applyMappedOverride(result)
end new


(* Constructor. When you need to load another library, do it here. *)
on init()
	set RESERVED_DOC_NAMES to {"Settings", "Project", "Project Find Results", "Welcome Guide"}
	
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("atom")
	set retry to std's import("retry")
	set fileUtil to std's import("file")
	set syseve to std's import("syseve")
	set uni to std's import("unicodes")
	set textUtil to std's import("string")
	set cp to std's import("clipboard")'s new()
	set kb to std's import("keyboard")'s new()
end init
