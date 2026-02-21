(*
	This decorator contains handlers for when the Voice Control pane is active from the Accessibility settings.

	@Project:
		applescript-core
		
	@Build:
		./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/dec-system-settings_accessibility_voice-control"

	@Created: Tuesday, November 14, 2023 at 10:37:03 PM
	@Last Modified: Sunday, February 11, 2024 at 3:37:35 PM
	@Change Logs:
		Sunday, February 11, 2024 at 3:37:39 PM - Update to macOS Sonoma 14.3.1
*)
use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"

property logger : missing value

property retry : missing value

property PANE_ID_DESKTOP_AND_DOCK : "com.apple.Desktop-Settings.extension"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		INFO
		Manual: Set Microphone
		Manual: Trigger Commands...
		Manual: Trigger Vocabulary...
	")
	
	set spotScript to script "core/spot-test"
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
	
	logger's infof("Voice Control State: {}", sut's isVoiceControlActive())
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's setMicrophone("MacBook")
		
	else if caseIndex is 3 then
		sut's clickAccessibilityCommands()
		
	else if caseIndex is 4 then
		logger's infof("Handler result: {}", sut's clickVocabulary())
		
	else
		
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set retry to retryLib's new()
	
	script SystemSettingsAccessibilityVoiceControlDecorator
		property parent : mainScript
		
		(*
			@returns true of Voice control is active.
		*)
		on isVoiceControlActive()
			tell application "System Events"
				try
					return value of my _getVoiceControlToggleUI() is 1
				end try
			end tell
			false
		end isVoiceControlActive
		
		on setMicrophone(micKeyword)
			tell application "System Events" to tell process "System Settings"
				set micPopup to pop up button 2 of group 1 of scroll area 1 of group 1 of last UI element of splitter group 1 of UI element 1 of front window
				click micPopup
				try
					click (last menu item of menu 1 of micPopup whose title contains micKeyword) -- Using last trying to avoid the automatic.
				end try
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
				tell application "System Events" to tell process "System Settings" to tell window "Voice Control" to tell first UI element
					try
						-- click (first button of scroll area 1 of group 1 of last list of splitter group 1 whose name starts with "Vocabulary")
						click (button 2 of scroll area 1 of group 1 of last list of splitter group 1) -- button by name is absent in Sonoma.
					end try
				end tell
			end script
			if (exec of retry on result for 50 by 0.1) is false then
				logger's fatal("Button Vocabulary was not found")
				return false
			end if
			
			script FilterWaiter
				tell application "System Events" to tell process "System Settings" to tell window "Voice Control"
					-- if exists (first button of group 1 of sheet 1 of window "Accessibility" whose description is "add") then return true  -- Killed by Apple.
					if exists (first button of group 1 of scroll area 1 of group 1 of sheet 1 whose value of attribute "AXIdentifier" is "AX_VOCAB_PHRASE_ADD") then return true
				end tell
			end script
			set waitResult to exec of retry on result for 50 by 0.1
			if waitResult is missing value then
				logger's fatal("Add button was not detected")
				return false
			end if
			
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
				tell application "System Events" to tell process "System Settings" to tell window "Voice Control" to tell first UI element
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
		
		
		on _getVoiceControlToggleUI()
			script Failable
				tell application "System Events" to tell process "System Settings"
					checkbox 1 of group 1 of scroll area 1 of group 1 of last UI element of splitter group 1 of UI element 1 of window "Voice Control"
				end tell
			end script
			exec of retry on result for 6 by 0.5
		end _getVoiceControlToggleUI
	end script
end decorate
