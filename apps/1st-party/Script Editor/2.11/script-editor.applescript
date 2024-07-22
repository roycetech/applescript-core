(*
	Re-designed from scripteditor-tabs.applescript

	Prerequisite:	
		This script expects that finder preferences has to always
	display the file extension.

	@Plists:
		config-system
			AppleScript Core Project Path

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
use listUtil : script "core/list"
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use contentDecorator : script "core/dec-script-editor-content"

use configLib : script "core/config"
use retryLib : script "core/retry"

use decoratorLib : script "core/decorator"

use spotScript : script "core/spot-test"

property logger : missing value
property configSystem : missing value
property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: File Info (Core Project, Other Project)
		Open file
		Open file with single quote in name
		Manual: E2E: Find Tab With Name, Focus, and Run(Found/Not Found. Open std.applescript)
		Manual: Get Front Tab
		
		Manual: Focus
		Manual: Save as app
		Manual: Replace and Select
	")
	
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
	
	set projectPath to configSystem's getValue("AppleScript Core Project Path")
	if caseIndex is 1 then
		logger's infof("getScriptLocation: {}", frontTab's getScriptLocation())
		logger's infof("getScriptDirectory: {}", frontTab's getScriptDirectory())
		logger's infof("getScriptName: {}", frontTab's getScriptName())
		logger's infof("getBaseScriptName: {}", frontTab's getBaseScriptName())
		logger's infof("getPosixPath: {}", frontTab's getPosixPath())
		logger's infof("(BROKEN, not possible when there's multiple projects) getResourcePath(): {}", frontTab's getResourcePath())
		
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
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's injectBasic(me)
	
	set configSystem to configLib's new("system")
	set retry to retryLib's new()
	
	script ScriptEditorInstance
		
		(* @return  missing value of tab is not found. ScriptEditorInstance *)
		on findTabWithName(theName as text)
			if running of application "Script Editor" is false then return missing value
			
			tell application "Script Editor"
				if not (window theName exists) then return missing value
				
				set appWindow to window theName
				return my _new(id of appWindow)
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
				return my _new(id of window 1)
			end tell
		end getFrontTab
		
		
		
		(*
			@posixFilePath the Unix file  path e.g. /Users/...

			@returns script instance TODO
		*)
		on openFile(posixFilePath)
			activate application "Script Editor"
			
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
		
		-- Private Codes below =======================================================
		on _new(windowId)
			script ScriptEditorInstance
				property appWindow : missing value -- app window, not syseve window.
				property suffixedName : missing value
				
				on getScriptDirectory()
					textUtil's stringBefore(getPosixPath(), getBaseScriptName())
				end getScriptDirectory
				
				on focus()
					if running of application "Script Editor" is false then return
					
					tell application "System Events" to tell process "Script Editor"
						try -- Fix the nasty bug where it focuses but it's still not considered as the main window targeted by the menu command merge all windows.
							click menu item (name of document of my appWindow) of menu 1 of menu bar item "Window" of menu bar 1
						end try
					end tell
					
					tell application "Script Editor"
						set index of my appWindow to 1
					end tell
				end focus
				
				on runScript()
					focus()
					
					script RunScriptInstance
						tell application "System Events" to tell process "Script Editor"
							click (first button of toolbar 1 of front window whose description is "Run") -- button "Run" don't seem to work.
						end tell
						logger's debug("Run button found and clicked...")
						true
					end script
					set runResult to exec of retry on result for 3
					logger's debugf("runResult: {}", runResult)
					runResult
				end runScript
				
				
				on newTab()
					if running of application "Script Editor" is false then return
					
					focus()
					
					tell application "System Events" to tell process "Script Editor"
						click (first button of tab group "tab bar" of first window whose description is "new tab")
					end tell
				end newTab
				
				(**)
				on showLogs()
					if running of application "Script Editor" is false then return
					
					focus()
					
					tell application "System Events" to tell process "Script Editor"
						if exists (window "Open") then
							click button "Cancel" of window "Open"
						end if
						
						tell window (name of my appWindow)
							set logTabState to (value of first radio button of first radio group whose description is "log") as text
							if logTabState is not "1" then click (first radio button of first radio group whose description is "log")
							click checkbox "Messages" of group 1 of splitter group 1 of splitter group 1
							delay 0.1
							
							-- Set nice ration between the code and the output panes.
							set maxValue to maximum value of splitter 1 of splitter group 1 of splitter group 1
							set value of splitter 1 of splitter group 1 of splitter group 1 to maxValue * 0.7
						end tell
					end tell
				end showLogs
				
				(* @returns the code text of the front most editor tab *)
				on getContents()
					if running of application "Script Editor" is false then return
					
					contents of document of my appWindow
				end getContents
				
				on setContents(newText as text)
					if running of application "Script Editor" is false then return
					
					set contents of document of my appWindow to newText
				end setContents
				
				(* @returns the filename without the path. *)
				on getScriptName()
					name of appWindow
				end getScriptName
				
				(* @returns the extension-less filename. *)
				on getBaseScriptName()
					set winName to getScriptName()
					
					set endIdx to (textUtil's lastIndexOf(winName, ".")) - 1
					text 1 thru endIdx of winName
				end getBaseScriptName
				
				(* 
					@Deprecated. 
					Broken, because it assumed that the project will always be applescript-core :( 
				*)
				on getResourcePath()
					if running of application "Script Editor" is false then return missing value
					
					set projectSubPath to "applescript-core/"
					tell application "Script Editor"
						set resourcePath to path of document of appWindow
					end tell
					text ((offset of projectSubPath in resourcePath) + (length of projectSubPath)) thru -1 of resourcePath
				end getResourcePath
				
				(*
					Assumes that script editor is running.
					Does not work on path when the document reference is returned, convert to record.
					@return struct with: posixPath, name, and resourcePath.
				*)
				on getDetail()
					if running of application "Script Editor" is false then return missing value
					
					tell application "Script Editor"
						set frontDoc to document of appWindow
						set projectSubPath to "applescript/"
						set resourcePath to path of document of appWindow
						set theResourcePath to text ((offset of projectSubPath in resourcePath) + (length of projectSubPath)) thru -1 of resourcePath
						{posixPath:path of document of appWindow, name:name of document of appWindow, resourcePath:theResourcePath}
					end tell
				end getDetail
				
				(*
				    @targetFolder Mac OS colon separated format for the script destination.
				*)
				on saveAsText(targetFolder)
					if running of application "Script Editor" is false then return
					
					set newScriptName to textUtil's replace(getScriptName(), ".scpt", ".applescript")
					logger's debug("New Script Name: " & newScriptName)
					
					tell application "Script Editor"
						tell document of my appWindow
							-- compile
							save as "text" in targetFolder & newScriptName
						end tell
					end tell
				end saveAsText
				
				(*
				    @targetFolder Mac OS colon separated format for the script destination.
				*)
				on saveAsScript(targetFolder)
					if running of application "Script Editor" is false then return
					
					
					set newScriptName to textUtil's replace(getScriptName(), ".applescript", ".scpt")
					logger's debug("New Script Name: " & newScriptName)
					
					tell application "Script Editor"
						tell document of my appWindow
							compile
							save as "script" in targetFolder & newScriptName
						end tell
					end tell
				end saveAsScript
				
				(*
		    			@targetFolder Mac OS colon separated format for the script destination.
				*)
				on saveAsStayOpenApp(newScriptName, targetFolder)
					if running of application "Script Editor" is false then return
					
					if newScriptName is missing value then set newScriptName to textUtil's replace(getScriptName(), ".applescript", ".app")
					tell application "Script Editor"
						tell document of my appWindow
							compile
							save as "application" in (targetFolder & newScriptName) with stay open and run only
						end tell
					end tell
					newScriptName
				end saveAsStayOpenApp
				
				on closeTab()
					if running of application "Script Editor" is false then return
					
					tell application "Script Editor" to close appWindow
				end closeTab
				
				on saveDocument()
					if running of application "Script Editor" is false then return
					
					tell application "Script Editor"
						save document of my appWindow
					end tell
				end saveDocument
				
				on hasSavePrompt()
					if running of application "Script Editor" is false then return
					
					tell application "System Events" to tell process "Script Editor"
						button "Revert" of sheet 1 of window (name of my appWindow) exists
					end tell
				end hasSavePrompt
				
				on respondRevert()
					if running of application "Script Editor" is false then return
					
					tell application "System Events" to tell process "Script Editor"
						click button "Revert" of sheet 1 of window (name of my appWindow)
					end tell
				end respondRevert
				
				on compileDocument()
					if running of application "Script Editor" is false then return
					
					tell application "Script Editor"
						compile document of my appWindow
					end tell
				end compileDocument
				
				on getPosixPath()
					if running of application "Script Editor" is false then return
					
					tell application "Script Editor"
						set posixPath to path of document of appWindow
					end tell
					
					if my suffixedName is not missing value then -- Means it has been exported as workaround to assistive access bug.
						set posixPath to textUtil's replace(posixPath, getBaseScriptName(), my suffixedName)
						set posixPath to text 1 thru -(length of "plescript") of posixPath -- considered the off by one bug.
					end if
					
					posixPath
				end getPosixPath
				
				(* @returns the mac os notation folder of this script *)
				on getScriptLocation()
					if running of application "Script Editor" is false then return
					
					tell application "Script Editor" -- Wrapped due to error, was fine before.
						set sut to path of document of appWindow
						set scriptName to name of document of appWindow
					end tell
					set scriptNameLength to count of scriptName
					set reducedLength to (sut's length) - scriptNameLength
					set location to text 1 thru reducedLength of sut
					(POSIX file location) as text
				end getScriptLocation
				
				on mergeAllWindows()
					if running of application "Script Editor" is false then return
					
					focus()
					
					tell application "System Events" to tell process "Script Editor"
						click menu item "Merge All Windows" of menu 1 of menu bar item "Window" of menu bar 1
					end tell
				end mergeAllWindows
			end script
			
			tell application "Script Editor" to set appWindow of ScriptEditorInstance to window id windowId
			
			ScriptEditorInstance
		end _new
	end script
	
	contentDecorator's decorate(result)
	set decorator to decoratorLib's new(result)
	decorator's decorate()
end new
