
(* 
	Previously Bloody Flaky. Let's see if it has improved. This script creates 
	an app for the user and stores it in /Applications/AppleScript folder. A 
	code template is hard coded in the body of this script.
	
	@Requires:
		keyboard-maestro.applescript (Let's see if we can detach this.)
		user-specific keyboard maestro macro: Automator: Click At Command Phrase Input
		clipboard.applescript - Some input fields could not be manipulated directly so the clipboard is utilized.
	
	@Build:
		make install-automator

	WARNING: 
		Assumes automator is not used or opened for purposes other than the exclusive use of this script.
		Wipes out clipboard contents.

	@Last Modified: 2023-07-13 21:07:06
*)

use scripting additions

use std : script "std"
use listUtil : script "list"

use loggerFactory : script "logger-factory"
use configLib : script "config"
use syseveLib : script "system-events"
use kbLib : script "keyboard"
use processLib : script "process"
use retryLib : script "retry"

use overriderLib : script "overrider"

use spotScript : script "spot-test"

property logger : missing value

property kb : missing value
property configSystem : missing value
property syseve : missing value
property retry : missing value
property overrider : missing value

property documentType : missing value
property windowName : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me, "automator")
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: E2E: Create New App Script
		Manual: E2E: Create Voice Command App
		Manual: Show Side Bar
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
		tell sut
			forceQuitApp()
			launchAndWaitReady()
			createNewDocument()
			selectApplicationType()
			addAppleScriptAction()
			writeRunScript("AppleScript Core Project Path", "examples/hello.applescript")
			compileScript()
			triggerSave()
			waitForSaveReady()
			enterScriptName("Spot Check Only")
			triggerGoToFolder()
			waitForGoToFolderInputField()
			enterDefaultSavePath()
			set savePathFound to waitToFindSavePath()
			
			if savePathFound is missing value then
				error "The save path was not found: " & savePath & ". Check config-system['AppleScript Apps path']"
			end if
			
			acceptFoundSavePath()
			
			tell me to error "abort" -- IS THIS PROMINENT ENOUGH?!!!
			-- clickSave()
		end tell
		tell application "Automator" to quit
		
	else if caseIndex is 2 then
		
		(* Commands are similar to when creating a regular app unless specified *)
		tell sut
			forceQuitApp()
			launchAndWaitReady()
			createNewDocument()
			selectDictationCommand()
			addAppleScriptAction()
			writeRunScript("AppleScript Core Project Path", "examples/hello.applescript")
			
			clickCommandEnabled() -- Voice Specific
			setCommandPhrase("Say this") -- Voice Specific
			compileScript()
			triggerSave()
			waitForSaveReady()
			
			enterScriptName("Spot Check Voice Command")
			-- Voice: Save destination is not available for voice commands.			
			clickSave()
		end tell
		
	else if caseIndex is 3 then
		tell sut to showSideBar()
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's inject(me, "automator")
	set kb to kbLib's new()
	set configSystem to configLib's new("system")
	set syseve to syseveLib's new()
	set retry to retryLib's new()
	set overrider to overriderLib's new()
	
	(* Note: Handlers are ordered by which step they are called. *)
	script AutomatorInstance
		property newWindowName : missing value
		on launchAndWaitReady()
			activate application "Automator"
			script AppWaiter
				tell application "System Events" to tell process "Automator"
					if exists button "Choose" of first sheet of front window then return true
				end tell
			end script
			exec of retry on result for 5 by 1
		end launchAndWaitReady
		
		on createNewDocument()
			script WaitOpen
				tell application "System Events" to tell process "Automator"
					try
						if exists button "Open an Existing Document..." of sheet 1 of window 1 then return true
					end try
					try
						click button "New Document" of window "Open"
						return true
					end try
				end tell
			end script
			exec of retry on result for 30 by 1
			if result is missing value then error "Failed"
		end createNewDocument
		
		
		(* Using key strokes *)
		on selectDictationCommand()
			activate application "Automator"
			tell application "System Events"
				repeat 3 times
					kb's pressKey("right")
				end repeat
				kb's pressKey("down")
				kb's pressKey("return")
			end tell
			set my newWindowName to "Untitled (Dictation Command)"
		end selectDictationCommand
		
		
		(* Respond to a choose document type dialog by using key strokes *)
		on selectApplicationType()
			if running of application "Automator" is false then return
			
			activate application "Automator" -- try this first instead of below, made it similar to when creating voice command.
			-- delay 1 -- Attempt to fix breakage, default is being selected.
			tell application "System Events"
				kb's pressKey("right")
				kb's pressKey("return")
			end tell
			set my newWindowName to "Untitled (Application)"
		end selectApplicationType
		
		
		on addAppleScriptAction()
			if running of application "Automator" is false then return
			
			showSideBar()
			activate application "Automator"
			tell application "System Events" to tell process "Automator" to keystroke "Run AppleScript"
			delay 1 -- convert to wait.
			repeat 2 times
				kb's pressKey("enter")
			end repeat
			delay 0.1 -- convert to wait.
		end addAppleScriptAction
		
		
		on showSideBar()
			if running of application "Automator" is false then return
			
			script ErrorAvoider
				tell application "System Events" to tell process "Automator"
					if newWindowName is missing value then set newWindowName to name of front window
					if value of checkbox 1 of group 1 of toolbar 1 of window newWindowName is 0 then
						click checkbox 1 of group 1 of toolbar 1 of window newWindowName
					end if
				end tell
			end script
			exec of retry on result for 10 by 0.1 -- Because it fails to get the window immediately after the doc type selection without the retry.
		end showSideBar
		
		
		(* 
			@ projectPathKey - this is the key in config-user.plist which points to the path of the project containing the script.
			@resourcePath - the script path name relative to the project. 
		*)
		on writeRunScript(projectPathKey, resourcePath)
			if running of application "Automator" is false then return
			
			
			tell application "System Events" to tell process "Automator"
				-- set the code
				set theCodeTextArea to text area 1 of scroll area 1 of splitter group 1 of group 1 of list 1 of scroll area 1 of splitter group 1 of splitter group 1 of window (my newWindowName)
				set value of theCodeTextArea to "
use scripting additions

use configLib : script \"config\"
use fileUtil : script \"file\"

property configUser : missing value

on run {input, parameters}
	(* Your script goes here *)
	set configUser to configLib's new(\"user\")
	set projectPath to configUser's getValue(\"Project " & projectPathKey & "\")
	set scriptFilePath to projectPath & \"/" & resourcePath & "\"
	set scriptMon to fileUtil's convertPosixToMacOsNotation(scriptFilePath)
	run script alias scriptMon
	return input
end run
"
			end tell
		end writeRunScript
		
		
		on compileScript()
			if running of application "Automator" is false then return
			
			tell application "System Events" to tell process "Automator"
				click button 4 of group 1 of list 1 of scroll area 1 of splitter group 1 of splitter group 1 of window (my newWindowName)
			end tell
		end compileScript
		
		
		on setCommandPhrase(commandPhrase)
			if running of application "Automator" is false then return
			
			tell application "System Events" to tell process "Automator"
				try
					set value of value indicator 1 of scroll bar 1 of scroll area 1 of splitter group 1 of splitter group 1 of window (my newWindowName) to 0
				end try -- Fail if scroll bar is absent, everything is visible.
			end tell
			
			tell application "System Events" to tell process "Automator"
				set theTextField to text field 1 of list 1 of scroll area 1 of splitter group 1 of splitter group 1 of window (my newWindowName)
				set value of theTextField to commandPhrase
			end tell
		end setCommandPhrase
		
		
		on clickCommandEnabled()
			if running of application "Automator" is false then return
			
			tell application "System Events" to tell process "Automator"
				click checkbox "Command Enabled" of list 1 of scroll area 1 of splitter group 1 of splitter group 1 of window (my newWindowName)
			end tell
		end clickCommandEnabled
		
		on triggerSave()
			if running of application "Automator" is false then return
			
			kb's pressCommandKey("s")
		end triggerSave
		
		on waitForSaveReady()
			script WaitSaveButton
				tell application "System Events" to tell process "Automator"
					-- if exists (button "Save" of sheet 1 of window "Untitled (Application)") then return true
					if exists (button "Save" of sheet 1 of window (my newWindowName)) then return true
				end tell
			end script
			exec of retry on result for 10
			assertThat of std given condition:result is not missing value, messageOnFail:"Save button was not found"
		end waitForSaveReady
		
		on enterScriptName(scriptName)
			kb's insertTextByPasting(scriptName)
			-- set the clipboard to scriptNameOnly
		end enterScriptName
		
		on triggerGoToFolder()
			kb's pressCommandShiftKey("g")
		end triggerGoToFolder
		
		on waitForGoToFolderInputField()
			script WaitInputField
				tell application "System Events" to tell process "Automator"
					if exists (text field 1 of sheet 1 of sheet 1 of first window) then return true
				end tell
			end script
			exec of retry on result for 10
		end waitForGoToFolderInputField
		
		on enterDefaultSavePath()
			set defaultSavePath to configSystem's getValue("AppleScript Apps path")
			enterSavePath(defaultSavePath)
		end enterDefaultSavePath
		
		on enterSavePath(savePath)
			kb's insertTextByPasting(savePath)
		end enterSavePath
		
		on waitToFindSavePath()
			script WaitFoundPath
				tell application "System Events" to tell process "Automator"
					if exists (row 2 of table 1 of scroll area 1 of sheet 1 of sheet 1 of front window) then return true
				end tell
			end script
			exec of retry on result for 10
		end waitToFindSavePath
		
		on acceptFoundSavePath()
			kb's pressKey("return")
		end acceptFoundSavePath
		
		on clickSave()
			if running of application "Automator" is false then return
			
			tell application "System Events" to tell process "Automator"
				click button "Save" of sheet 1 of window 1
			end tell
		end clickSave
		
		(*
			Fails when automator is active in the dock, and it could not be killed
			programmatically. Thus the pkill. Re-written on December 19, 2022.
		*)
		on forceQuitApp()
			if running of application "Automator" is false then return
			
			logger's debug("Automator IS running...")
			script DiscardChanges
				tell application "System Events" to tell process "Automator"
					try
						click button "Delete" of sheet 1 of window 1
						return true
					end try
					try
						click button "Close" of sheet 1 of window 1
						return true
					end try
					try
						click (first button of sheet 1 of window 1 whose name starts with "Don" and name ends with "Save")
						true
					end try
				end tell
			end script
			
			tell application "Automator"
				ignoring application responses
					close workflows
				end ignoring
				exec of retry on DiscardChanges for 5

				quit
				try
					do shell script "pkill Automator" -- required that app is not running in the Dock.
					delay 0.1
				end try

				repeat while its running is true
					delay 0.1
				end repeat
			end tell
		end forceQuitApp
	end script
	
	overrider's applyMappedOverride(result)
end new