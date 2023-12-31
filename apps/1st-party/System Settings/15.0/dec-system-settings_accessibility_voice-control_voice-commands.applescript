(*
	@Project:
		applescript-core
		
	@Build:
		./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/dec-system-settings_accessibility_voice-control_voice-commands"

	@Created: Tuesday, November 14, 2023 at 10:29:06 PM
	@Last Modified: Tuesday, November 14, 2023 at 10:29:06 PM
	@Change Logs:
*)
use listUtil : script "core/list"
use loggerFactory : script "core/logger-factory"
use retryLib : script "core/retry"

use spotScript : script "core/spot-test"

property logger : missing value
property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: Reveal the Voice Control Panel
		Manual: Manual Trigger the Voice Commands
		Manual: Click Add Voice Commands
		Manual: Set When I say
		Manual: Set While using
		
		Manual: Set Perform Action
		Manual: Set Perform Action Text
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	-- activate application ""
	set sutLib to script "core/system-settings"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	if caseIndex is 1 then
		sut's quitApp()
		sut's revealAccessibilityVoiceControl()
		
	else if caseIndex is 2 then
		sut's clickAccessibilityCommands()
		
	else if caseIndex is 3 then
		sut's clickAddVoiceCommand()
		
	else if caseIndex is 4 then
		sut's setWhenISay("spot check")
		
	else if caseIndex is 5 then
		sut's setWhileUsing("UI Browser")
		
	else if caseIndex is 6 then
		sut's setPerformAction("Open URL")
		
	else if caseIndex is 7 then
		sut's setPerformActionText("Perform Text")
		
	else
		
	end if
	
	activate -- Restore focus
	
	spot's finish()
	logger's finish()
end spotCheck


on newSpotBase()
	script SpotBaseInstance
		property template : missing value
	end script
end newSpotBase


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set retry to retryLib's new()
	
	script SystemSettingsVoiceCommandsDecorator
		property parent : mainScript

		on revealAccessibilityVoiceControl()
			tell application "System Settings" to activate
			
			script PanelWaiter
				tell application "System Settings"
					set current pane to pane id "com.apple.Accessibility-Settings.extension"
					-- reveal anchor "Voice Control" of current pane
				end tell
				
				tell application "System Events" to tell process "System Settings"
					if exists static text "Accessibility" of window "Accessibility" then return true
				end tell
			end script
			exec of retry on result for 50 by 0.1
			
			tell application "System Events" to tell process "System Settings"
				try
					click button 1 of group 3 of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of window "Accessibility"
				end try
			end tell
			delay 0.1
		end revealAccessibilityVoiceControl

		on setWhenISay(triggerPhrase)
			tell application "System Events" to tell process "System Settings"
				set value of text field 1 of group 1 of sheet 1 of window "Voice Control" to triggerPhrase
			end tell
		end setWhenISay

		on setWhileUsing(appName)
			if appName is "" or appName is missing value then return
			
			tell application "System Events" to tell process "System Settings"
				set the whileUsingPopup to the pop up button 1 of group 1 of sheet 1 of window "Voice Control"
				click the whileUsingPopup
				delay 0.2
				try
					click the menu item appName of menu 1 of the whileUsingPopup
				end try
			end tell
		end setWhileUsing
		
		on setPerformAction(actionTitle)
			tell application "System Events" to tell process "System Settings"
				set the performPopup to the pop up button 2 of group 1 of sheet 1 of window "Voice Control"
				click the performPopup
				delay 0.2
				click the menu item actionTitle of menu 1 of the performPopup
			end tell
			delay 1
		end setPerformAction
		
		on setPerformActionText(performText)
			tell application "System Events" to tell process "System Settings"
				try
					set the value of text area 1 of scroll area 1 of group 1 of sheet 1 of window "Voice Control" to the performText
				end try
			end tell
		end setPerformText
		
		on clickAddVoiceCommand()
			tell application "System Events" to tell process "System Settings"
				try
					click (first button of group 2 of sheet 1 of window "Voice Control" whose description is "add")
				end try
			end tell
		end clickAddVoiceCommand


		(* 
			After clicking the Commands... button under Accessibility, type in a to filter the list of check boxes.
			
			@commandKeyword is case-sensitive. Use a single-word that uniquely filters the list. For example 'Turn off Voice' will match all phrases with that has any of the words: Turn, off, or voice.
			@targetRow the command row to enable. Needs to be manually checked with the UI.
		*)
		on filterCommandsAndEnable(commandKeyword)
			_filterCommandsAndSetState(commandKeyword, 1)
		end filterCommandsAndEnable
		
		(* 
			After clicking the Commands... button under Accessibility, type in a to filter the list of check boxes.
			
			@commandKeyword is case-sensitive. Use a single-word that uniquely filters the list. For example 'Turn off Voice' will match all phrases with that has any of the words: Turn, off, or voice.
			@targetRow the command row to enable. Needs to be manually checked with the UI.
		*)
		on filterCommandsAndDisable(commandKeyword)
			_filterCommandsAndSetState(commandKeyword, 0)
		end filterCommandsAndDisable
		
		(*
			@Private.  
		*)
		on _filterCommandsAndSetState(commandLabel, newState)
			if running of application "System Settings" is false then return false
			
			-- try
			tell application "System Events" to tell process "System Settings" to tell window "Voice Control"
				set value of text field 1 of sheet 1 to commandLabel
				delay 0.2 -- breaks/does not work without this delay, retry doesn't work either.
				
				logger's debug("Iterating...")
				repeat with nextRow in rows of table 1 of scroll area 1 of sheet 1
					if value of static text 1 of UI element 1 of nextRow is equal to commandLabel then
						
						set currentValue to value of checkbox 1 of UI element 1 of nextRow
						if currentValue is equal to the newState then return false
						
						click checkbox 1 of UI element 1 of nextRow
						exit repeat
					end if
				end repeat
				
			end tell
			return true
			-- end try
			false
		end _filterCommandsAndSetState
		
		(*
			@returns true if operation is success, false or missing value if there's an error.
		*)
		on enableTurnOffVoiceControl()
			if clickAccessibilityCommands() is false then return false
			
			filterCommandsAndEnable("Turn off Voice Control")
			
			try
				tell application "System Events" to tell process "System Settings" to tell window "Accessibility" to tell first sheet
					click button "Done"
				end tell
				return true
			end try
			
			false
		end enableTurnOffVoiceControl		
	end script
end decorate
