(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/1st-party/System Settings/15.0/macOS Sequoia/dec-system-settings_apple-intelligence-and-siri'

	@Created: Tue, May 27, 2025 at 01:42:52 PM
	@Last Modified: Tue, May 27, 2025 at 01:42:52 PM
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

use processLib : script "core/process"
use retryLib : script "core/retry"
use kbLib : script "core/keyboard"

property logger : missing value
property kb : missing value

property PANE_ID_AI_AND_SIRI : "com.apple.Siri-Settings.extension*siri-sae"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Reveal AI Pane
		Manual: Set Siri Keyboard Shortcut
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
	
	logger's infof("Keyboard shortcut: {}", sut's getSiriKeyboardShortcut())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's revealAppleIntelligenceAndSiri()
		
	else if caseIndex is 3 then
		set sutShortcut to "Unicorn"
		set sutShortcut to "Press Right Command Key Twice"
		logger's debugf("sutShortcut: {}", sutShortcut)
		
		sut's setSiriKeyboardShortcut(sutShortcut)
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set kb to kbLib's new()
	
	script SystemSettingsAppleIntelligenceAndSiriDecorator
		property parent : mainScript
		
		on getSiriKeyboardShortcut()
			if running of application "System Settings" is false then return missing value
			
			tell application "System Events" to tell process "System Settings"
				try
					return value of pop up button 2 of group 2 of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of front window
				end try
			end tell
			missing value
		end getSiriKeyboardShortcut
		
		
		on setSiriKeyboardShortcut(newShortCut)
			if running of application "System Settings" is false then return missing value
			
			tell application "System Events" to tell process "System Settings"
				try
					set sutPopup to pop up button 2 of group 2 of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of front window
					click sutPopup
					click menu item newShortCut of menu 1 of sutPopup
				on error the errorMessage number the errorNumber
					kb's pressKey("escape")
				end try
			end tell
		end setSiriKeyboardShortcut
		
		
		on revealAppleIntelligenceAndSiri()
			set retry to retryLib's new()
			
			if running of application "System Settings" is false then
				set systemSettingsProcess to processLib's new("System Settings")
				systemSettingsProcess's waitActivate()
			end if
			
			tell application "System Settings"
				reveal pane id PANE_ID_AI_AND_SIRI
			end tell
			
			script AppleIntelligenceAndSiriPaneWaiter
				tell application "System Events" to tell process "System Settings"
					if exists (window "Apple Intelligence & Siri") then return true
				end tell
			end script
			exec of retry on result for 3
		end revealAppleIntelligenceAndSiri
	end script
end decorate
