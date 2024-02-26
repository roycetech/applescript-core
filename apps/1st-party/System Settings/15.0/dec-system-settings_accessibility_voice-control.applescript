(*
	@Project:
		applescript-core
		
	@Build:
		./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/dec-system-settings_accessibility_voice-control"

	@Created: Tuesday, November 14, 2023 at 10:37:03 PM
	@Last Modified: Sunday, February 11, 2024 at 3:37:35 PM
	@Change Logs:
		Sunday, February 11, 2024 at 3:37:39 PM - Update to macOS Sonoma 14.3.1
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
		Manual: Set Microphone
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
	sut's quitApp()
	sut's revealAccessibilityVoiceControl()
	
	if caseIndex is 1 then
		sut's setMicrophone("MacBook")
		
	else if caseIndex is 2 then
		
	else if caseIndex is 3 then
		
	else
		
	end if
	
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
	
	script SystemSettingsAccessibilityDecorator
		property parent : mainScript
		
		on setMicrophone(micKeyword)
			tell application "System Events" to tell process "System Settings"
				set micPopup to pop up button 2 of group 1 of scroll area 1 of group 1 of last UI element of splitter group 1 of ui element 1 of front window
				click micPopup
				click (first menu item of menu 1 of micPopup whose title contains micKeyword)
				
			end tell
		end setMicrophone
		
		(*
			While on the Voice Control panel, click on the button "Commands..."
		*)
		on clickAccessibilityCommands()
			if running of application "System Settings" is false then return false
			
			(* Detect when Commands List is already visible. *)
			tell application "System Events" to tell process "System Settings"
				try
					set searchFieldPresent to exists (first text field of sheet 1 of window "Voice Control" whose value of attribute "AXIdentifier" is "Search Field")
					set doneButtonPresent to exists (button "Done" of sheet 1 of window "Voice Control")
					
					if searchFieldPresent and doneButtonPresent then return true
				end try
				
			end tell
			logger's debug("Not already showing target sheet")
			
			script ClickRetrier
				tell application "System Events" to tell process "System Settings" to tell window "Voice Control" to tell first UI element
					try
						click (first button of scroll area 1 of group 1 of last UI element of splitter group 1) -- Ventura removed the ability to click via name
						return true
					on error the errorMessage number the errorNumber
						logger's warn(errorMessage)
					end try
				end tell
			end script
			if (exec of retry on result for 50 by 0.1) is missing value then return false
			
			script FilterWaiter
				tell application "System Events" to tell process "System Settings" to tell window "Voice Control"
					-- if exists text field 1 of sheet 1 then return true
					if exists text field 1 of UI element 1 of row 1 of outline 1 of scroll area 1 of group 1 of splitter group 1 of group 1 of sheet 1 then return true
				end tell
			end script
			set waitResult to exec of retry on result for 50 by 0.1
			if waitResult is missing value then return false
			
			true
		end clickAccessibilityCommands
		
		on clickVocabulary()
			if running of application "System Settings" is false then return false
			
			(* Detect when Commands List is already visible. *)
			tell application "System Events" to tell process "System Settings"
				try
					set listPresent to exists (table 1 of scroll area 1 of sheet 1 of window "Accessibility")
					set addButtonPresent to exists (first button of group 1 of sheet 1 of window "Accessibility" whose description is "add")
					set saveButtonPresent to exists (button "Save" of sheet 1 of window "Accessibility")
					
					if listPresent and addButtonPresent and saveButtonPresent then return true
				end try
				
			end tell
			logger's debug("Not already showing target sheet")
			
			script ClickRetrier
				tell application "System Events" to tell process "System Settings" to tell window "Accessibility" to tell first group
					try
						click (first button whose name starts with "Vocabulary")
					end try
				end tell
			end script
			if (exec of retry on result for 50 by 0.1) is false then return false
			
			script FilterWaiter
				tell application "System Events" to tell process "System Settings" to tell window "Accessibility"
					if exists (first button of group 1 of sheet 1 of window "Accessibility" whose description is "add") then return true
				end tell
			end script
			set waitResult to exec of retry on result for 50 by 0.1
			if waitResult is missing value then return false
			
			true
		end clickVocabulary
		
		(*
			Requires that the correct pane is already open. @See #revealAccessibilityVoiceControl().
			
			@Requires administrator to grant access initially and install some software.
			@returns true if it was turned to enabled, false if turned to disabled, missing value if the app is not running or if an error was encountered.
		*)
		on toggleVoiceControl()
			if running of application "System Settings" is false then return missing value
			
			set currentState to -1
			script ClickWaiter
				tell application "System Events" to tell process "System Settings" to tell window "Voice Control" to tell first group
					-- set currentState to get value of checkbox "Enable Voice Control"
					set currentState to get value of checkbox 1 of group 1 of scroll area 1 of group 1 of group 2 of splitter group 1
					click checkbox "Voice Control" of group 1 of scroll area 1 of group 1 of group 2 of splitter group 1
				end tell
				true
			end script
			exec of retry on result for 30 by 0.1
			if result is missing value then return missing value
			
			if currentState is not 0 then return false
			
			true
		end toggleVoiceControl
	end script
end decorate
