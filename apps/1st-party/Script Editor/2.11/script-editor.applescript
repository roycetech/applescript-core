global std, textUtil, retry

use script "Core Text Utilities"
use scripting additions

(*
	Re-designed from scripteditor-tabs.applescript

	Prerequisite:	
		This script expects that finder preferences has to always
	display the file extension.

	Compile:
		make compile-lib SOURCE="apps/1st-party/Script Editor/2.11/scripteditor"
				

	Usage:
		set seLib to std's import("script-editor")
		set seTab to seLib's getFrontTab()
*)

property initialized : false
property logger : missing value
if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "scripteditor-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	set fileUtil to std's import("file")
	set configSystem to std's import("config")'s new("system")
	
	set cases to listUtil's splitByLine("
		Misc
		Open file
		Open file with single quote in name
		Manual: E2E: Find Tab With Name, Focus, and Run(Found/Not Found. Open std.applescript)
		Manual: Get Front Tab
		
		Manual: Focus
		
		
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
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
		set sutTab to findTabWithName(spotTabName)
		logger's logObj("Found Tab", sutTab)
		sutTab's runScript()
		
	else if caseIndex is 5 then
		set sutTab to getFrontTab()
		logger's logObj("Front Tab", sutTab)
		logger's infof("Script Name: {}", sutTab's getScriptName())
		
	else if caseIndex is 6 then
		set spotTabName to "std.applescript"
		set sutTab to findTabWithName(spotTabName)
		sutTab's focus()
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	script ScriptEditorInstance
		
		(* @return  missing value of tab is not found. ScriptEditorInstance *)
		on findTabWithName(theName as text)
			if running of application "Script Editor" is false then return missing value
			
			tell application "Script Editor"
				if not (window theName exists) then return missing value
				
				set theWindow to window theName
				return my _new(id of theWindow)
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
			
			do shell script "open " & quoted form of posixFilePath
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
		
		
		-- Private Codes below =======================================================
		on _new(windowId)
			script ScriptEditorInstance
				property theWindow : missing value -- app window, not syseve window.
				property suffixedName : missing value
				
				on focus()
					if running of application "Script Editor" is false then return
					
					tell application "System Events" to tell process "Script Editor"
						try -- Fix the nasty bug where it focuses but it's still not considered as the main window targeted by the menu command merge all windows.
							click menu item (name of document of my theWindow) of menu 1 of menu bar item "Window" of menu bar 1
						end try
					end tell
					
					tell application "Script Editor"
						set index of my theWindow to 1
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
						
						tell window (name of my theWindow)
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
					
					contents of document of my theWindow
				end getContents
				
				on setContents(newText as text)
					if running of application "Script Editor" is false then return
					
					set contents of document of my theWindow to newText
				end setContents
				
				(* @returns the filename without the path. *)
				on getScriptName()
					name of theWindow
				end getScriptName
				
				(* @returns the extensionless filename. *)
				on getBaseScriptName()
					set winName to getScriptName()
					
					set endIdx to (textUtil's lastIndexOf(winName, ".")) - 1
					text 1 thru endIdx of winName
				end getBaseScriptName
				
				(* @deprecated. Broken, because it assumed that the project will always be applescript-core :( *)
				on getResourcePath()
					if running of application "Script Editor" is false then return missing value
					
					set projectSubPath to "applescript-core/"
					tell application "Script Editor"
						set resourcePath to path of document of theWindow
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
						set frontDoc to document of theWindow
						set projectSubPath to "applescript/"
						set resourcePath to path of document of theWindow
						set theResourcePath to text ((offset of projectSubPath in resourcePath) + (length of projectSubPath)) thru -1 of resourcePath
						{posixPath:path of document of theWindow, name:name of document of theWindow, resourcePath:theResourcePath}
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
						tell document of my theWindow
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
						tell document of my theWindow
							compile
							save as "script" in targetFolder & newScriptName
						end tell
					end tell
				end saveAsScript
				
				(*
		    @targetFolder Mac OS colon separated format for the script destination.
		*)
				on saveAsStayOpenApp(targetFolder)
					if running of application "Script Editor" is false then return
					
					set newScriptName to textUtil's replace(getScriptName(), ".applescript", ".app")
					tell application "Script Editor"
						tell document of my theWindow
							compile
							save as "application" in targetFolder & newScriptName with stay open
						end tell
					end tell
					newScriptName
				end saveAsStayOpenApp
				
				on closeTab()
					if running of application "Script Editor" is false then return
					
					tell application "Script Editor" to close theWindow
				end closeTab
				
				on saveDocument()
					if running of application "Script Editor" is false then return
					
					tell application "Script Editor"
						save document of my theWindow
					end tell
				end saveDocument
				
				on hasSavePrompt()
					if running of application "Script Editor" is false then return
					
					tell application "System Events" to tell process "Script Editor"
						button "Revert" of sheet 1 of window (name of my theWindow) exists
					end tell
				end hasSavePrompt
				
				on respondRevert()
					if running of application "Script Editor" is false then return
					
					tell application "System Events" to tell process "Script Editor"
						click button "Revert" of sheet 1 of window (name of my theWindow)
					end tell
				end respondRevert
				
				on compileDocument()
					if running of application "Script Editor" is false then return
					
					tell application "Script Editor"
						compile document of my theWindow
					end tell
				end compileDocument
				
				on getPosixPath()
					if running of application "Script Editor" is false then return
					
					tell application "Script Editor"
						set posixPath to path of document of theWindow
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
						set sut to path of document of theWindow
						set scriptName to name of document of theWindow
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

			tell application "Script Editor" to set theWindow of ScriptEditorInstance to window id windowId

			ScriptEditorInstance
		end _new
	end script
	std's applyMappedOverride(result)
end new


(* Constructor. When you need to load another library, do it here. *)
(* When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true

	set std to script "std"

	set logger to std's import("logger")'s new("script-editor")
	set textUtil to std's import("string")
	set retry to std's import("retry")'s new()
end init