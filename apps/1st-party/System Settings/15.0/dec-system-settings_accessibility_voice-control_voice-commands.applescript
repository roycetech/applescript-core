(*
	This decorator contains handlers for when the Commands button was clicked 
	from the Voice Control pane.

	@Version:
		macOS Sonoma
		
	@Project:
		applescript-core
		
	@Build:
		./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/dec-system-settings_accessibility_voice-control_voice-commands"

	@Created: Tuesday, November 14, 2023 at 10:29:06 PM
	@Last Modified: Friday, February 2, 2024 at 11:47:51 AM
	
	@Change Logs:
		Saturday, April 27, 2024 at 5:44:50 PM - set when I say need to be user typed.
*)
use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"
use cliclickLib : script "core/cliclick"
use kbLib : script "core/keyboard"

use spotScript : script "core/spot-test"

property logger : missing value
property retry : missing value
property cliclick : missing value
property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: Reveal the Voice Control Panel
		Manual: Trigger the Commands... button
		Manual: Click Add Voice Commands
		Manual: Set When I say
		Manual: Set While using
		
		Manual: Set Perform Action
		Manual: Set Perform Action Text
		Manual: Flip Voice Control switch
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
		
	else if caseIndex is 8 then
		logger's infof("Voice Control Flip result: {}", sut's flipVoiceControlSwitch())
		
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
	set cliclick to cliclickLib's new()
	set kb to kbLib's new()
	
	script SystemSettingsVoiceCommandsDecorator
		property parent : mainScript
		
		(*
			@returns true if the switch was turned on.
			@NOTE: 
				UI Types dynamically changes from list to group and vice versa for undetermined reason. 
				This was observed after toggling the UI to ON.
		*)
		on flipVoiceControlSwitch()
			set toggleUI to _getVoiceControlToggleUI()
			if toggleUI is missing value then return false
			
			tell application "System Events"
				click toggleUI
				delay 0.4 -- Fails intermittently, 
				set toggleUI to my _getVoiceControlToggleUI()
				if toggleUI is missing value then return false
				
				-- try
				the value of toggleUI is 1
				-- end try
			end tell
		end flipVoiceControlSwitch
		
		on revealAccessibilityVoiceControl()
			tell application "System Settings" to activate
			
			set motorGroup to missing value
			script PanelWaiter
				tell application "System Settings"
					set current pane to pane id "com.apple.Accessibility-Settings.extension"
					-- reveal anchor "Voice Control" of current pane
				end tell
				
				tell application "System Events" to tell process "System Settings"
					-- if exists static text "Accessibility" of window "Accessibility" then return true
					-- if exists (group 3 of scroll area 1 of group 1 of list 2 of splitter group 1 of UI element 1 of window "Accessibility") then return true
					set motorGroup to group 3 of scroll area 1 of group 1 of last UI element of splitter group 1 of UI element 1 of window "Accessibility"
				end tell
			end script
			set retryResult to exec of retry on result for 20 by 0.5
			if retryResult is missing value then return
			
			tell application "System Events"
				try
					click button 1 of motorGroup
				end try
			end tell
			delay 0.1
		end revealAccessibilityVoiceControl
		
		on setWhenISay(triggerPhrase)
			tell application "System Events" to tell process "System Settings"
				-- set value of text field 1 of group 1 of sheet 1 of window "Voice Control" to triggerPhrase
				set targetTextField to text field 1 of group 1 of scroll area 1 of group 2 of splitter group 1 of group 1 of sheet 1 of window "Voice Control"
				
				lclick of cliclick at targetTextField
				kb's pressKey(space)
				kb's pressKey("delete")
				set value of targetTextField to triggerPhrase
			end tell
		end setWhenISay
		
		on setWhileUsing(appName)
			if appName is "" or appName is missing value then return
			
			tell application "System Events" to tell process "System Settings"
				if not (exists (window "Voice Control")) then return
				
				-- set the whileUsingPopup to the pop up button 1 of group 1 of sheet 1 of window "Voice Control"
				set the whileUsingPopup to the pop up button 1 of group 1 of scroll area 1 of group 2 of splitter group 1 of group 1 of sheet 1 of window "Voice Control"
				click the whileUsingPopup
				delay 0.2
				try
					click the menu item appName of menu 1 of the whileUsingPopup
				on error
					try
						click (the first menu item of menu 1 of the whileUsingPopup whose title starts with appName)
					end try
				end try
			end tell
		end setWhileUsing
		
		on setPerformAction(actionTitle)
			tell application "System Events" to tell process "System Settings"
				if not (exists (window "Voice Control")) then return
				
				-- set the performPopup to the pop up button 2 of group 1 of sheet 1 of window "Voice Control"
				set the performPopup to the pop up button 2 of group 1 of scroll area 1 of group 2 of splitter group 1 of group 1 of sheet 1 of window "Voice Control"
				click the performPopup
				delay 0.2
				click the menu item actionTitle of menu 1 of the performPopup
			end tell
			delay 1
		end setPerformAction
		
		on setPerformActionText(performText)
			tell application "System Events" to tell process "System Settings"
				try
					-- set the value of text area 1 of scroll area 1 of group 1 of sheet 1 of window "Voice Control" to the performText
					set the value of text field 2 of group 1 of scroll area 1 of group 2 of splitter group 1 of group 1 of sheet 1 of window "Voice Control" to the performText
				end try
			end tell
		end setPerformActionText
		
		on clickAddVoiceCommand()
			tell application "System Events" to tell process "System Settings"
				try
					-- click (first button of group 2 of sheet 1 of window "Voice Control" whose description is "add")  -- They're slowly killing accessibility.
					click (first button of group 1 of splitter group 1 of group 1 of sheet 1 of front window whose value of attribute "AXAttributedDescription" is "Add")
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
