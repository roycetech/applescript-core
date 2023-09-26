(*
	Library wrapper for the System Preferences app. Some handlers have more 
	additional requirements than others.  See handler's documentation for more 
	info.

	@Version:
		macOS Monterey 12.x.

	@Build:
		make build-lib SOURCE="apps/1st-party/System Preferences/15.0/system-preferences"
*)

use scripting additions

use loggerFactory : script "core/logger-factory"

use listUtil : script "core/list"

use retryLib : script "core/retry"
use usrLib : script "core/user"

use spotScript : script "core/spot-test"

use decoratorLib : script "core/decorator"

property logger : missing value
property retry : missing value
property usr : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: Quit App (Running/Not Running)
		Manual: Reveal Security & Privacy > Privacy		
		Manual: Unlock Security & Privacy > Privacy (Unlock button must be visible already) 
		Manual: Reveal Dictation
		Manual: Toggle Voice Control
		
		Manual: Click Commands...
		Manual: Enable 'Turn off Voice Control'
		Manual: Filter Commands and Enable
		Manual: Filter Commands and Disable
		Manual: Click Vocabulary
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	-- spot's setAutoIncrement(true)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	if caseIndex is 1 then
		sut's quitApp()
		
	else if caseIndex is 2 then
		sut's quitApp()
		sut's revealSecurityAccessibilityPrivacy()
		
	else if caseIndex is 3 then
		sut's unlockSecurityAccessibilityPrivacy()
		
	else if caseIndex is 4 then
		sut's quitApp()
		sut's revealAccessibilityDictation()
		
	else if caseIndex is 5 then
		sut's revealAccessibilityDictation()
		logger's infof("Toggle Voice Control: {}", sut's toggleVoiceVoiceControl())
		
	else if caseIndex is 6 then
		logger's infof("Click Commands...: {}", sut's clickAccessibilityCommands())
		
	else if caseIndex is 7 then
		-- sut's revealAccessibilityDictation()
		logger's infof("Turn On: 'Turn Off Voice Control': {}", sut's enableTurnOffVoiceControl())
		
	else if caseIndex is 8 then
		sut's quitApp()
		if sut's revealAccessibilityDictation() is false then error "Could not reveal Accessibility Dictation"
		sut's clickAccessibilityCommands()
		logger's infof("Manual: Filter and Enable: '<phrase>': {}", sut's filterCommandsAndEnable("<phrase>", 2))
		
	else if caseIndex is 9 then
		sut's quitApp()
		sut's revealAccessibilityDictation()
		sut's clickAccessibilityCommands()
		logger's infof("Manual: Filter and Disable: '<phrase>': {}", sut's filterCommandsAndDisable("<phrase>", 2))
		
	else if caseIndex is 10 then
		sut's quitApp()
		sut's revealAccessibilityDictation()
		sut's clickVocabulary()
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's inject(me)
	set retry to retryLib's new()
	set usr to usrLib's new()
	
	script SystemPreferences
		on revealAccessibilityDictation()
			tell application "System Preferences" to activate
			
			script PanelWaiter
				tell application "System Preferences"
					reveal anchor "Dictation" of pane id "com.apple.preference.universalaccess"
				end tell
				
				tell application "System Events" to tell process "System Preferences"
					if exists (checkbox "Enable Voice Control" of group 1 of window "Accessibility") then return true
				end tell
			end script
			exec of retry on result for 50 by 0.1
		end revealAccessibilityDictation
		
		
		(*
			Requires that the correct pane is already open. @See #revealAccessibilityDictation().
			
			@Requires administrator to grant access initially and install some software.
			@returns true if it was turned to enabled, false if turned to disabled, missing value if the app is not running or if an error was encountered.
		*)
		on toggleVoiceVoiceControl()
			if running of application "System Preferences" is false then return missing value
			
			set currentState to -1
			script ClickWaiter
				tell application "System Events" to tell process "System Preferences" to tell window "Accessibility" to tell first group
					set currentState to get value of checkbox "Enable Voice Control"
					click checkbox "Enable Voice Control"
				end tell
				true
			end script
			exec of retry on result for 30 by 0.1
			if result is missing value then return missing value
			
			if currentState is not 0 then return false
			
			true
		end toggleVoiceVoiceControl
		
		
		on clickAccessibilityCommands()
			if running of application "System Preferences" is false then return false
			
			(* Detect when Commands List is already visible. *)
			tell application "System Events" to tell process "System Preferences"
				try
					set searchFieldPresent to exists (first text field of sheet 1 of window "Accessibility" whose value of attribute "AXIdentifier" is "Search Field")
					set doneButtonPresent to exists (button "Done" of sheet 1 of window "Accessibility")
					
					if searchFieldPresent and doneButtonPresent then return true
				end try
				
			end tell
			logger's debug("Not already showing target sheet")
			
			script ClickRetrier
				tell application "System Events" to tell process "System Preferences" to tell window "Accessibility" to tell first group
					try
						click (first button whose name starts with "Commands")
						true
					on error the errorMessage number the errorNumber
						logger's warn(errorMessage)
					end try
				end tell
			end script
			if (exec of retry on result for 50 by 0.1) is missing value then return false
			
			script FilterWaiter
				tell application "System Events" to tell process "System Preferences" to tell window "Accessibility"
					if exists text field 1 of sheet 1 then return true
				end tell
			end script
			set waitResult to exec of retry on result for 50 by 0.1
			if waitResult is missing value then return false
			
			true
		end clickAccessibilityCommands
		
		
		on clickVocabulary()
			if running of application "System Preferences" is false then return false
			
			(* Detect when Commands List is already visible. *)
			tell application "System Events" to tell process "System Preferences"
				try
					set listPresent to exists (table 1 of scroll area 1 of sheet 1 of window "Accessibility")
					set addButtonPresent to exists (first button of group 1 of sheet 1 of window "Accessibility" whose description is "add")
					set saveButtonPresent to exists (button "Save" of sheet 1 of window "Accessibility")
					
					if listPresent and addButtonPresent and saveButtonPresent then return true
				end try
				
			end tell
			logger's debug("Not already showing target sheet")
			
			script ClickRetrier
				tell application "System Events" to tell process "System Preferences" to tell window "Accessibility" to tell first group
					try
						click (first button whose name starts with "Vocabulary")
					end try
				end tell
			end script
			if (exec of retry on result for 50 by 0.1) is false then return false
			
			script FilterWaiter
				tell application "System Events" to tell process "System Preferences" to tell window "Accessibility"
					if exists (first button of group 1 of sheet 1 of window "Accessibility" whose description is "add") then return true
				end tell
			end script
			set waitResult to exec of retry on result for 50 by 0.1
			if waitResult is missing value then return false
			
			true
		end clickVocabulary
		
		
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
			if running of application "System Preferences" is false then return false
			
			
			
			-- try
			tell application "System Events" to tell process "System Preferences" to tell window "Accessibility"
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
				tell application "System Events" to tell process "System Preferences" to tell window "Accessibility" to tell first sheet
					click button "Done"
				end tell
				return true
			end try
			
			false
		end enableTurnOffVoiceControl
		
		
		on revealSecurityAccessibilityPrivacy()
			tell application "System Preferences"
				activate
				reveal anchor "Privacy_Accessibility" of pane id "com.apple.preference.security"
			end tell
			
			script PanelWaiter
				tell application "System Events" to tell process "System Preferences"
					if (value of radio button "Privacy" of tab group 1 of window "Security & Privacy") is 0 then return missing value
				end tell
				true
			end script
			exec of retry on result for 50 by 0.1
		end revealSecurityAccessibilityPrivacy
		
		on unlockSecurityAccessibilityPrivacy()
			usr's cueForTouchId()
			script WindowWaiter
				tell application "System Events" to tell process "System Preferences"
					click button "Click the lock to make changes." of window "Security & Privacy"
				end tell
				true
			end script
			exec of retry on result for 10 by 0.5
			
			script UnlockWaiter
				tell application "System Events" to tell application process "System Preferences"
					try
						button "Click the lock to prevent further changes." of window "Security & Privacy" exists
					end try
				end tell
				true
			end script
			exec of retry on result for 10
		end unlockSecurityAccessibilityPrivacy
		
		
		(* 
			Invoke this script before doing anything with System Preferences so that you 
			have a clean slate as you start. 
		*)
		on quitApp()
			if running of application "System Preferences" is false then return
			
			try
				tell application "System Preferences" to quit
			on error
				do shell script "killall 'System Preferences'"
			end try
			
			repeat while running of application "System Preferences" is true
				delay 0.1
			end repeat
		end quitApp
	end script

	set decorator to decoratorLib's new(result)
	decorator's decorate()
end new
