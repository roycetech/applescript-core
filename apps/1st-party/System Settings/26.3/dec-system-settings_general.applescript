(*
	@Purpose:

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/1st-party/System Settings/26.3/dec-system-settings_general'

	@Created: Wed, Feb 18, 2026 at 10:21:40 AM
	@Last Modified: Wed, Feb 18, 2026 at 10:21:40 AM
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

use processLib : script "core/process"
use retryLib : script "core/retry"

property logger : missing value

property PANE_ID_GENERAL : "com.apple.systempreferences.GeneralSettings"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Reveal General Settings
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
	
	logger's infof("Right Scroll Pane UI detected: {}", sut's getRightPaneScrollArea() is not missing value)
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's revealGeneral()
		
	else if caseIndex is 3 then
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	set decGeneralAbout to script "core/dec-system-settings_general_about" 
	
	script SystemSettingsGeneralDecorator
		property parent : mainScript
		
		on revealGeneral()
			if running of application "System Settings" is false then
				set systemSettingsProcess to processLib's new("System Settings")
				systemSettingsProcess's waitActivate()
			end if
			
			tell application "System Events" to tell process "System Settings"
				if the name of front window is "General" then return
			end tell
			
			tell application "System Settings"
				reveal pane id PANE_ID_GENERAL
			end tell
			
			set retry to retryLib's new()
			script KeyboardPaneWaiter
				tell application "System Events" to tell process "System Settings"
					if exists (window "General") then return true
				end tell
			end script
			exec of retry on result for 3
		end revealGeneral
		
		
		on getRightPaneScrollArea()
			tell application "System Events" to tell process "System Settings"
				try
					return scroll area 1 of group 1 of group 3 of splitter group 1 of group 1 of front window
				end try
				
			end tell
			missing value
		end getRightPaneScrollArea
	end script
	
	decGeneralAbout's decorate(result)
end decorate
