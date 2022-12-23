global std, syseve, retry, km, kb, configSystem

(* 
	Previously Bloody Flaky. Let's see if it has improved. This script creates an app for the user and stores it in /Applications/AppleScript folder
	
	@Requires:
		keyboard-maestro.applescript (Let's see if we can detach this.)
		user-specific keyboard maestro macro: Automator: Click At Command Phrase Input
		clipboard.applescript - Some input fields could not be manipulated directly so the clipboard is utilized.
	
	@Install:
		make install-automator

	WARNING: 
		Assumes automator is not used or opened for purposes other than the exclusive use of this script.
		Wipes out clipboard contents.
*)

property initialized : false
property logger : missing value
property documentType : missing value
property windowName : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "automator-spotCheck"
	logger's start()
	
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Manual: E2E: Create New App Script.
	")
	
	set spotLib to std's import("spot")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	sut's forceQuitApp()
	
	set configSystem to std's import("config")'s new("system")
	
	if caseIndex is 1 then
		tell sut
			launchAndWaitReady()
			createNewDocument()
			selectApplicationType()
			addAppleScriptAction()
			writeRunScript(configSystem's getValue("AppleScript Core Project Path") & "/examples/hello.applescript")
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
			clickSave()
		end tell
		tell application "Automator" to quit
		
	else if caseIndex is 2 then
		-- WIP
		
		doSelectDictationCommand()
		doAddAppleScriptAction()
		doWriteRunScriptNext("deployed/hello.applescript")
		doClickCommandEnabled()
		doSetCommandPhrase("Say this")
		
		set the clipboard to "Spot Check Only"
		doCompileScript()
	end if
	
	spot's finish()
	
	
	
	logger's finish()
end spotCheck


on new()
	(* Note: Handlers are ordered by which step they are called. *)
	script AutomatorInstance
		
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
			set my windowName to "Untitled (Dictation Command)"
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
			set my windowName to "Untitled (Application)"
		end selectApplicationType
		
		
		on addAppleScriptAction()
			if running of application "Automator" is false then return
			
			activate application "Automator"
			km's runScript("App Automator Click At Action Filter") -- maybe we can ignore because the input is intermittently focused.
			tell application "System Events" to tell process "Automator" to keystroke "Run AppleScript"
			delay 1 -- convert to wait.
			repeat 2 times
				kb's pressKey("enter")
			end repeat
			delay 0.1 -- convert to wait.
		end addAppleScriptAction
		
		
		(* scriptPath *)
		on writeRunScript(filePath)
			if running of application "Automator" is false then return
			
			
			tell application "System Events" to tell process "Automator"
				-- set the code
				set theCodeTextArea to text area 1 of scroll area 1 of splitter group 1 of group 1 of list 1 of scroll area 1 of splitter group 1 of splitter group 1 of window (my windowName)
				set value of theCodeTextArea to "
on run {input, parameters}
	(* Your script goes here *)
	set std to script \"std\"
	set fileUtil to std's import(\"file\")

	set scriptMon to fileUtil's convertPosixToMacOsNotation(\"" & filePath & "\")
	run script alias scriptMon
	return input
end run
"
			end tell
		end writeRunScript
		
		
		on compileScript()
			if running of application "Automator" is false then return
			
			tell application "System Events" to tell process "Automator"
				click button 4 of group 1 of list 1 of scroll area 1 of splitter group 1 of splitter group 1 of window (my windowName)
			end tell
		end compileScript
		
		
		on setCommandPhrase(commandPhrase)
			if running of application "Automator" is false then return
			
			-- Scroll Up, so UI is visible to km.
			tell application "System Events" to tell process "Automator"
				try
					set value of value indicator 1 of scroll bar 1 of scroll area 1 of splitter group 1 of splitter group 1 of window (my windowName) to 0
				end try -- Fail if scroll bar is absent, everything is visible.
			end tell
			
			set kmMacroName to "Automator: Click At Command Phrase Input"
			script WaiterOk
				km's runScript(kmMacroName)
			end script
			set kmResult to exec of retry on result for 5
			logger's debugf("kmResult: {}", kmResult)
			if kmResult is false then error "Keyboard Maestro Macro [" & kmMacroName & "] failed."
			-- syseve's pressRight() -- Simulate physical interaction to trick the app into a state. DOES NOT WORK.
			
			syseve's pressSpace() -- Try this instead of above to see if it works.
			syseve's pressDelete()
			
			tell application "System Events" to tell process "Automator"
				set theTextField to text field 1 of list 1 of scroll area 1 of splitter group 1 of splitter group 1 of window (my windowName)
				set value of theTextField to commandPhrase
			end tell
		end setCommandPhrase
		
		
		on clickCommandEnabled()
			if running of application "Automator" is false then return
			
			tell application "System Events" to tell process "Automator"
				click checkbox "Command Enabled" of list 1 of scroll area 1 of splitter group 1 of splitter group 1 of window (my windowName)
			end tell
		end clickCommandEnabled
		
		on triggerSave()
			kb's pressCommandKey("s")
		end triggerSave
		
		on waitForSaveReady()
			script WaitSaveButton
				tell application "System Events" to tell process "Automator"
					if exists (button "Save" of sheet 1 of window "Untitled (Application)") then return true
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
end new


-- Private Codes below =======================================================
(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("automator")
	
	set proc to std's import("process")
	set syseve to std's import("syseve")'s new()
	set retry to std's import("retry")'s new()
	set kb to std's import("keyboard")'s new()
	
	set km to std's import("keyboard-maestro")
	set configSystem to std's import("config")'s new("system")
end init