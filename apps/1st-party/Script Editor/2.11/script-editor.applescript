(*
	Re-designed from scripteditor-tabs.applescript

	Prerequisite:	
		This script expects that finder preferences has to always
	display the file extension.

	@Project:
		applescript-core
	
	 @Build:
		./scripts/build-lib.sh 'apps/1st-party/Script Editor/2.11/script-editor'
													
	@Usage:
		use seLib : script "core/script-editor" 
		property se : seLib's new()
		set frontTab to se's getFrontTab()
		or
		KM Text Expander: uuse scripteditor
*)

use script "core/Text Utilities"
use scripting additions

use fileUtil : script "core/file"
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use scriptEditorTabLib : script "core/script-editor-tab"
use decWindow : script "core/dec-script-editor-window"
use decContent : script "core/dec-script-editor-content"
use decCursor : script "core/dec-script-editor-cursor"
use decSettings : script "core/dec-script-editor-settings"
use decSettingsGeneral : script "core/dec-script-editor-settings-general"
use decSettingsEditing : script "core/dec-script-editor-settings-editing"
use decTabs : script "core/dec-script-editor-tabs"
use decDialog : script "core/dec-script-editor-dialog"

use configLib : script "core/config"
use retryLib : script "core/retry"

use decoratorLib : script "core/decorator"

property logger : missing value

property configSystem : missing value
property retry : missing value

property CONFIG_SYSTEM : "system"
property CONFIG_KEY_AS_PROJECT_CORE_PATH : "AppleScript Core Project Path"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Manual: File Info (Core Project, Other Project)
		Open file
		Open file with single quote in name
		Manual: E2E: Find Tab With Name, Focus, and Run(Found/Not Found. Open std.applescript)
		Manual: Get Front Tab
		
		Manual: Focus
		Manual: Save as app
		Manual: Replace and Select
		Manual: Close Search
		Manual: Show Settings
		
		Manual: Show Logs History
		Manual: Close Logs History
	")
	
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	set frontTab to sut's getFrontTab()
	frontTab's focus()
	
	set projectPath to configSystem's getValue(CONFIG_KEY_AS_PROJECT_CORE_PATH)
	
	logger's infof("Is new document window present?: {}", sut's isNewDocumentWindowPresent)
	logger's infof("Integration: getScriptName: {}", frontTab's getScriptName())
	-- logger's infof("(BROKEN, not possible when there's multiple projects) getResourcePath(): {}", frontTab's getResourcePath())
	-- log frontTab's getContents()
	log sut's getFrontContents()
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		openFile(projectPath & "/examples/hello.applescript")
		
	else if caseIndex is 3 then
		openFile(projectPath & "/examples/what's up.applescript")
		--
		
		-- frontTab's runScript()
		
	else if caseIndex is 4 then
		logger's infof("Not Found: {}", findTabWithName("Bad Name"))
		set spotTabName to "std.applescript"
		set sutTab to sut's findTabWithName(spotTabName)
		logger's logObj("Found Tab", sutTab)
		sutTab's runScript()
		
	else if caseIndex is 5 then
		set sutTab to sut's getFrontTab()
		logger's logObj("Front Tab", sutTab)
		logger's infof("Script Name: {}", sutTab's getScriptName())
		
	else if caseIndex is 6 then
		set spotTabName to "std.applescript"
		set sutTab to sut's findTabWithName(spotTabName)
		sutTab's focus()
		
	else if caseIndex is 7 then
		set sutTab to sut's findTabWithName("Menu Case.applescript")
		if sutTab is missing value then
			logger's warn("You need to open Menu Case.applescript in Script Editor")
		else
			sutTab's focus()
			tell application "Finder"
				set targetFolderMon to folder "Stay Open" of folder "AppleScript" of (path to applications folder) as text
				-- set targetFolderMon to folder "Stay Open" of folder "AppleScript" of (path to applications folder from user domain) as text
			end tell
			logger's infof("Handler result: {}", sutTab's saveAsStayOpenApp(missing value, targetFolderMon))
		end if
		
	else if caseIndex is 8 then
		sut's replaceAndSelect("xxx", "yyy") -- This line will be updated.
		
	else if caseIndex is 9 then
		sut's closeSearch()
		
	else if caseIndex is 10 then
		sut's showSettings()
		
	else if caseIndex is 11 then
		sut's showLogsHistory()
		
	else if caseIndex is 12 then
		sut's closeLogsHistory()
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's injectBasic(me)
	set configSystem to configLib's new("system")
	set retry to retryLib's new()
	
	script ScriptEditorInstance
		-- on isAtNewDocumentWindow
		on isNewDocumentWindowPresent()
			if running of application "Script Editor" is false then return false

			tell application "System Events" to tell process "Script Editor"
				exists (window "Open")
			end tell
		end isNewDocumentWindowPresent

		on getFrontContents()
			set editorWindow to getEditorWindow()
			if editorWindow is missing value then 
				-- logger's debug("editorWindow is missing")
				return missing value
			end if
			
			tell application "Script Editor" to tell the front document
				contents
			end tell
		end getFrontContents
		
		
		on closeSearch()
			set editorWindow to getEditorWindow()
			if editorWindow is missing value then return
			
			tell application "System Events" to tell process "Script Editor"
				try
					click button "Done" of scroll area 1 of splitter group 1 of splitter group 1 of editorWindow
				end try -- In case it is not even present
				try
					click button "Done" of scroll area 1 of group 1 of group 1 of splitter group 1 of splitter group 1 of editorWindow
				end try
			end tell
		end closeSearch
		
		
		on showSettings()
			if running of application "Script Editor" is false then return
			
			tell application "System Events" to tell process "Script Editor"
				try
					click (first menu item of menu 1 of menu bar item "Script Editor" of menu bar 1 whose title starts with "Settings")
				end try
			end tell
			
		end showSettings
		
		(* @return  missing value of tab is not found. ScriptEditorInstance *)
		on findTabWithName(theName as text)
			if running of application "Script Editor" is false then return missing value
			
			tell application "Script Editor"
				if not (window theName exists) then return missing value
				
				set appWindow to window theName
				return scriptEditorTabLib's new(id of appWindow)
			end tell
		end findTabWithName


		(* 
			@tabTitle - the filename of the script.
			@return  missing value of tab is not found. ScriptEditorInstance 
		*)
		on findTabByTitle(tabTitle)
			if running of application "Script Editor" is false then return missing value
			
			tell application "Script Editor"
				if not (window tabTitle exists) then return missing value
				
				set appWindow to window tabTitle
				return scriptEditorTabLib's new(id of appWindow)
			end tell
		end findTabWithName
		
		
		on getFrontTab()
			if running of application "Script Editor" is false then return missing value
			
			script FrontTabWaiter
				tell application "Script Editor"
					if (count of (windows whose name is not "Log History" and visible is true)) is 0 then return missing value
					true
				end tell
			end script
			if (exec of retry on result for 3) is missing value then return missing value
			
			tell application "Script Editor"
				return scriptEditorTabLib's new(id of window 1)
			end tell
		end getFrontTab
		
		
		
		(*
			@posixFilePath the Unix file  path e.g. /Users/...

			@returns script instance TODO
		*)
		on openFile(posixFilePath)
			if running of application "Script Editor" is false then
				activate application "Script Editor"
			end if
			
			tell application "System Events" to tell process "Script Editor"
				if exists (window "Open") then
					click button "Cancel" of window "Open"
				end if
			end tell
			
			-- do shell script "open " & quoted form of posixFilePath -- Uses the default app.
			do shell script "open -a 'Script Editor' " & quoted form of posixFilePath
			delay 0.1
			return getFrontTab()
			
			tell application "Script Editor" to open POSIX file posixFilePath
			delay 0.1
			getFrontTab()
		end openFile
		
		on recompileAllOpenDocuments()
			tell application "Script Editor"
				repeat with nextDocument in documents
					try
						compile nextDocument
					end try
				end repeat
			end tell
		end recompileAllOpenDocuments
		
		(*
				    Copied from the default AppleScripts.
				*)
		on replaceAndSelect(target_string, replacement_string)
			tell application "Script Editor"
				tell the front document
					set this_text to the contents
					set this_offset to the offset of the target_string in this_text
					if this_offset is not 0 then
						set selection to characters this_offset thru (this_offset + (length of the target_string) - 1)
						set the contents of the selection to the replacement_string
					end if
				end tell
			end tell
		end replaceAndSelect
		
		
		on showLogsHistory()
			set editorWindow to getEditorWindow()
			if editorWindow is missing value then return
			
			tell application "System Events" to tell process "Script Editor"
				try
					click (first button of group 1 of splitter group 1 of splitter group 1 of editorWindow whose help is "Show the Log History")
				end try
			end tell
		end showLogsHistory
		
		on closeLogsHistory()
			tell application "System Events" to tell process "Script Editor"
				try
					click of first button of window "Log History" whose description is "close button"
				end try
			end tell
		end closeLogsHistory


		on closeLibrary()
			tell application "System Events" to tell process "Script Editor"
				try
					click of first button of window "Library" whose description is "close button"
				end try
			end tell
		end closeLibrary
	end script
	
	decWindow's decorate(result)
	decContent's decorate(result)
	decCursor's decorate(result)
	decSettings's decorate(result)
	decSettingsGeneral's decorate(result)
	decSettingsEditing's decorate(result)
	decTabs's decorate(result)
	decDialog's decorate(result)
	
	set decorator to decoratorLib's new(result)
	decorator's decorateByName("ScriptEditorInstance")
end new
