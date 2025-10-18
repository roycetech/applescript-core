(*
	@Purpose:
		Represent the Script Editor tab.
		
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/1st-party/Script Editor/2.11/script-editor-tab'

	@Created: Sun, Oct 05, 2025 at 10:02:59 AM - Refactored out of script-editor.applescript.
	@Last Modified: July 24, 2023 10:56 AM
*)
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"

property logger : missing value

property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: 
	")
	
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	tell application "Script Editor"
		set appWindowId to id of front window
	end tell
	set sut to new(appWindowId)
	
	logger's infof("Script name: {}", sut's getScriptName())
	logger's infof("getScriptLocation: {}", sut's getScriptLocation())
	logger's infof("getScriptDirectory: {}", sut's getScriptDirectory())
	logger's infof("getBaseScriptName: {}", sut's getBaseScriptName())
	logger's infof("getPosixPath: {}", sut's getPosixPath())
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new(windowId)
	loggerFactory's inject(me)
	set retry to retryLib's new()
	
	tell application "Script Editor"
		set localAppWindow to window id windowId
	end tell
	
	script ScriptEditorTabInstance
		property appWindow : localAppWindow -- app window, not syseve window. 
		property suffixedName : missing value
		
		
		on hasSelection()
			tell application "Script Editor"
				tell document 1 of appWindow
					contents of selection is not ""
				end tell
			end tell
		end hasSelection
		
		
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
		
		on stopScript()
			focus()
			
			tell application "System Events" to tell process "Script Editor"
				click (first button of toolbar 1 of front window whose description is "Stop")
			end tell
		end stopScript
		
		
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
			if running of application "Script Editor" is false then return missing value
			
			script RetryFailing
				return contents of document of my appWindow
			end script
			exec of retry on result for 2
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
			
			set posixPath to missing value
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
		
		
		-- TODO: Move to script-editor.applescript
		on mergeAllWindows()
			if running of application "Script Editor" is false then return
			
			focus()
			
			tell application "System Events" to tell process "Script Editor"
				click menu item "Merge All Windows" of menu 1 of menu bar item "Window" of menu bar 1
			end tell
		end mergeAllWindows
	end script
end new

