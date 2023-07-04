(*
	Wrapper for Script Debugger app v8.0.5.
	
	Implementation was cloned from script-editor.applescript.
	
	@Assumptions:
		Script Debugger app will only have 1 window at any given time.
			New Script - at the start.
			Normal case - a script is open.
		
	@Facts:
		Cannot get the id of the app window.

	@Build:
		make compile-lib SOURCE='apps/3rd-party/Script Debugger/v8.0.x/script-debugger'
		
	@Create ON: June 24, 2023 2:21 PM
	
	@Known Issues:
		errOSAInternalTableOverflow as of June 28, 2023 1:25 PM. 
		
*)

use scripting additions

use listUtil : script "list"
use textUtil : script "string"
use loggerFactory : script "logger-factory"

use retryLib : script "retry"
use configLib : script "config"

use spotScript : script "spot-test"

property logger : missing value
property retry : missing value
property configSystem : missing value

property DOC_EDITED_SUFFIX : " Ð Edited"

if {"Script Debugger", "Script Editor"} contains (the name of current application as text) then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me, "script-debugger")
	set thisCaseId to "script-debugger-spotCheck"
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: File Info (Core Project, Other Project)
		Open file
		Open file with single quote in name
		Manual: E2E: Find Tab With Name, Focus, and Run(Found/Not Found. Open std.applescript)
		Manual: Get Front Tab
		
		Manual: Focus
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(thisCaseId, cases)
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
		logger's infof("Insertion Line: {}", frontTab's getInsertionLine())
		
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

(*  *)
on new()
	set retry to retryLib's new()
	set configSystem to configLib's new("system")
	
	script ScriptDebuggerInstance
		on getFrontTab()
			if running of application "Script Debugger" is false then return missing value
			
			script FrontTabWaiter
				tell application "Script Debugger"
					if (count of (windows whose name is not "New Script" and visible is true)) is 0 then return missing value
					true
				end tell
			end script
			if (exec of retry on result for 3) is missing value then return missing value
			
			_new()
		end getFrontTab
		
		(*
			@posixFilePath the Unix file  path e.g. /Users/...

			@returns script instance TODO
		*)
		on openFile(posixFilePath)
			do shell script "open -a 'Script Debugger' " & quoted form of posixFilePath
			delay 0.1
			getFrontTab()
		end openFile
		
		-- Private Codes below =======================================================
		on _new()
			tell application "Script Debugger"
				set localAppWindow to the front window
			end tell
			
			script ScriptDebuggerTabInstance
				property appWindow : localAppWindow
				property windowDocument : missing value
				property suffixedName : missing value
				
				on getPosixPath()
					if running of application "Script Debugger" is false then return missing value
					
					tell application "Script Debugger"
						path of windowDocument
					end tell
				end getPosixPath
				
				(* @returns the mac os notation folder of this script *)
				on getScriptLocation()
					if running of application "Script Debugger" is false then return
					
					tell application "Script Debugger" -- Wrapped due to error, was fine before.
						set scriptPath to path of my windowDocument
						set scriptName to name of my windowDocument
					end tell
					set scriptNameLength to count of scriptName
					set reducedLength to (scriptPath's length) - scriptNameLength
					set location to text 1 thru reducedLength of scriptPath
					(POSIX file location) as text
				end getScriptLocation
				
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
					@returns the current line number -1.
				*)
				on getInsertionLine()
					tell application "System Events" to tell process "Script Debugger"
						get value of attribute "AXInsertionPointLineNumber" of text area 1 of scroll area 1 of splitter group 1 of splitter group 1 of splitter group 1 of front window
					end tell
				end getInsertionLine
				
				
				on isEventLogVisible()
					
				end isEventLogVisible
				
				-- BELOW FOR REVIEW.
				on focus()
					if running of application "Script Debugger" is false then return
					
					tell application "System Events" to tell process "Script Debugger"
						try -- Fix the nasty bug where it focuses but it's still not considered as the main window targeted by the menu command merge all windows.
							click menu item (name of document of my appWindow) of menu 1 of menu bar item "Window" of menu bar 1
						end try
					end tell
					
					tell application "Script Debugger"
						set index of my appWindow to 1
					end tell
				end focus
				
				on runScript()
					focus()
					
					script RunScriptInstance
						tell application "System Events" to tell process "Script Debugger"
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
					if running of application "Script Debugger" is false then return
					
					focus()
					
					tell application "System Events" to tell process "Script Debugger"
						click (first button of tab group "tab bar" of first window whose description is "new tab")
					end tell
				end newTab
				
				(**)
				on showLogs()
					if running of application "Script Debugger" is false then return
					
					focus()
					
					tell application "System Events" to tell process "Script Debugger"
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
					if running of application "Script Debugger" is false then return
					
					contents of document of my appWindow
				end getContents
				
				on setContents(newText as text)
					if running of application "Script Debugger" is false then return
					
					set contents of document of my appWindow to newText
				end setContents
				
				(*
					Assumes that Script Debugger is running.
					Does not work on path when the document reference is returned, convert to record.
					@return struct with: posixPath, name, and resourcePath.
				*)
				on getDetail()
					if running of application "Script Debugger" is false then return missing value
					
					tell application "Script Debugger"
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
					if running of application "Script Debugger" is false then return
					
					set newScriptName to textUtil's replace(getScriptName(), ".scpt", ".applescript")
					logger's debug("New Script Name: " & newScriptName)
					
					tell application "Script Debugger"
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
					if running of application "Script Debugger" is false then return
					
					
					set newScriptName to textUtil's replace(getScriptName(), ".applescript", ".scpt")
					logger's debug("New Script Name: " & newScriptName)
					
					tell application "Script Debugger"
						tell document of my appWindow
							compile
							save as "script" in targetFolder & newScriptName
						end tell
					end tell
				end saveAsScript
				
				(*
		    			@targetFolder Mac OS colon separated format for the script destination.
				*)
				on saveAsStayOpenApp(targetFolder)
					if running of application "Script Debugger" is false then return
					
					set newScriptName to textUtil's replace(getScriptName(), ".applescript", ".app")
					tell application "Script Debugger"
						tell document of my appWindow
							compile
							save as "application" in targetFolder & newScriptName with stay open
						end tell
					end tell
					newScriptName
				end saveAsStayOpenApp
				
				on closeTab()
					if running of application "Script Debugger" is false then return
					
					tell application "Script Debugger" to close appWindow
				end closeTab
				
				on saveDocument()
					if running of application "Script Debugger" is false then return
					
					tell application "Script Debugger"
						save document of my appWindow
					end tell
				end saveDocument
				
				on hasSavePrompt()
					if running of application "Script Debugger" is false then return
					
					tell application "System Events" to tell process "Script Debugger"
						button "Revert" of sheet 1 of window (name of my appWindow) exists
					end tell
				end hasSavePrompt
				
				on respondRevert()
					if running of application "Script Debugger" is false then return
					
					tell application "System Events" to tell process "Script Debugger"
						click button "Revert" of sheet 1 of window (name of my appWindow)
					end tell
				end respondRevert
				
				on compileDocument()
					if running of application "Script Debugger" is false then return
					
					tell application "Script Debugger"
						compile document of my appWindow
					end tell
				end compileDocument
			end script
			
			tell application "System Events" to tell process "Script Debugger"
				set frontWindowName to textUtil's replace(the title of front window, DOC_EDITED_SUFFIX, "")
			end tell
			
			tell application "Script Debugger"
				set windowDocument of ScriptDebuggerTabInstance to the current document of script window 1
			end tell
			
			ScriptDebuggerTabInstance
		end _new
	end script
end new


-- Private Codes below =======================================================
