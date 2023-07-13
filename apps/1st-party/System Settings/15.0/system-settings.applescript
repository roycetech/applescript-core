(*
	Library wrapper for the System Settings app. This was cloned from the original System Preferences app of macOS Monterey.  
	Some handlers have more additional requirements than others.  See handler's documentation for more 
	info.

	@Version:
		macOS Ventura 13.x.

	@Build:
		make compile-lib SOURCE="apps/1st-party/System Settings/15.0/system-settings"
		
	@References:
		https://derflounder.wordpress.com/2022/10/25/opening-macos-venturas-system-settings-to-desired-locations-via-the-command-line/
*)

use scripting additions

use listUtil : script "list"

use loggerLib : script "logger"
use retryLib : script "retry"
use usrLib : script "user"

use spotScript : script "spot-test"

property logger : loggerLib's new("system-settings")
property retry : retryLib's new()
property usr : usrLib's new()

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: Quit App (Running/Not Running)
		Manual: Reveal Security & Privacy > Privacy		
		Manual: Unlock Security & Privacy > Privacy (Unlock button must be visible already) 
		Manual: Reveal Voice Control
		Manual: Toggle Voice Control
		
		Manual: Click Commands...
		Manual: Enable 'Turn off Voice Control'
		Manual: Filter Commands and Enable
		Manual: Filter Commands and Disable
		Manual: Click Vocabulary
		
		Manual: Print Panes
		Manual: revealKeyboardDictation
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
		sut's revealAccessibilityVoiceControl()
		
	else if caseIndex is 5 then
		sut's revealAccessibilityVoiceControl()
		logger's infof("Toggle Voice Control: {}", sut's toggleVoiceControl())
		
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
		
	else if caseIndex is 11 then
		sut's printPaneIds()
		
	else if caseIndex is 12 then
		sut's revealKeyboardDictation()
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck

on new()
	script SystemSettings
		on printPaneIds()
			tell application "System Settings"
				set panesList to id of panes
				repeat with nextId in panesList
					log nextId
				end repeat
			end tell
		end printPaneIds
		
		on revealKeyboardDictation()
			tell application "System Settings"
				set current pane to pane id "com.apple.Keyboard-Settings.extension"
				delay 1
				reveal anchor "Dictation" of current pane
			end tell
		end revealKeyboardDictation
		
		on revealSecurityAccessibilityPrivacy()
			tell application "System Settings"
				activate
				reveal anchor "Accessibility" of pane id "com.apple.preference.security"
			end tell
			
			script PanelWaiter
				tell application "System Events" to tell process "System Settings"
					if (value of radio button "Privacy" of tab group 1 of window "Security & Privacy") is 0 then return missing value
				end tell
				true
			end script
			exec of retry on result for 50 by 0.1
		end revealSecurityAccessibilityPrivacy
		
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
		
		-- Review below =====================
		
		
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
				tell application "System Events" to tell process "System Settings" to tell window "Voice Control" to tell first group
					try
						click (first button of scroll area 1 of group 1 of group 2 of splitter group 1) -- Ventura removed the ability to click via name
						true
					on error the errorMessage number the errorNumber
						logger's warn(errorMessage)
					end try
				end tell
			end script
			if (exec of retry on result for 50 by 0.1) is missing value then return false
			
			script FilterWaiter
				tell application "System Events" to tell process "System Settings" to tell window "Voice Control"
					if exists text field 1 of sheet 1 then return true
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
		
		
		
		
		on unlockSecurityAccessibilityPrivacy()
			usr's cueForTouchId()
			script WindowWaiter
				tell application "System Events" to tell process "System Settings"
					click button "Click the lock to make changes." of window "Security & Privacy"
				end tell
				true
			end script
			exec of retry on result for 10 by 0.5
			
			script UnlockWaiter
				tell application "System Events" to tell application process "System Settings"
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
			if running of application "System Settings" is false then return
			
			try
				tell application "System Settings" to quit
			on error
				do shell script "killall 'System Settings'"
			end try
			
			repeat while running of application "System Settings" is true
				delay 0.1
			end repeat
		end quitApp
	end script
	overrider's applyMappedOverride(result)
end new
