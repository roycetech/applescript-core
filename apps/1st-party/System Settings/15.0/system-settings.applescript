(*
	Library wrapper for the System Settings app. This was cloned from the original System Preferences app of macOS Monterey.  
	Some handlers have more additional requirements than others.  See handler's documentation for more 
	info.

	@Version:
		macOS Ventura 13.x. 

	@Project:
		applescript-core
 
	@Build:
		make build-lib SOURCE="apps/1st-party/System Settings/15.0/system-settings"
		 
	@References:
		https://derflounder.wordpress.com/2022/10/25/opening-macos-venturas-system-settings-to-desired-locations-via-the-command-line/
*)

use scripting additions 

use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"
use retryLib : script "core/retry"
use usrLib : script "core/user"

use decoratorLib : script "core/decorator"
use decPasswords : script "core/dec-system-settings_passwords"
use decVoiceControl : script "core/dec-system-settings_accessibility_voice-control"
use decVoiceCommand : script "core/dec-system-settings_accessibility_voice-control_voice-commands"

use spotScript : script "core/spot-test"

property logger : missing value
property retry : missing value
property usr : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
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
		Manual: Reveal Passwords (decorator)
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
		sut's revealPrivacyAndSecurity_Accessibility()
		logger's infof("Handler result: {}", result)
		
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
		
	else if caseIndex is 13 then
		sut's revealPasswords()
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck

on new()
	loggerFactory's inject(me)
	set retry to retryLib's new()
	set usr to usrLib's new()
	
	script SystemSettingsInstance
		on printPaneIds()
			tell application "System Settings"
				set panesList to id of panes
				repeat with nextId in panesList
					log nextId
				end repeat
			end tell
		end printPaneIds
		
		
		(* To move in its own decorator when more functions are needed. *)
		on revealKeyboard()
			tell application "System Settings"
				set current pane to pane id "com.apple.Keyboard-Settings.extension"
			end tell
		end revealKeyboard
		
		
		on revealPrivacyAndSecurity_Accessibility()
			tell application "System Settings"
				activate
				delay 0.2 -- Fails without this delay.
				set current pane to pane id "com.apple.settings.PrivacySecurity.extension"
			end tell
			
			script PanelWaiter
				tell application "System Events" to tell process "System Settings"
					if (value of radio button "Privacy" of tab group 1 of window "Security & Privacy") is 0 then return missing value
					
				end tell
				true
			end script
			exec of retry on result for 50 by 0.1
		end revealPrivacyAndSecurity_Accessibility
		
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
	
	set decorator to decoratorLib's new(result)
	decorator's decorate()
	
	decPasswords's decorate(result)
	decVoiceControl's decorate(result)
	decVoiceCommand's decorate(result)
end new

