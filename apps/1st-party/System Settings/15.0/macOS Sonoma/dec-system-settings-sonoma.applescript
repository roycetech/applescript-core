(*

	System Settings version did not change from macOS Ventura to Sonoma but the functionality broke.
	This decorator aims to fix that.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/1st-party/System Settings/15.0/macOS Sonoma/dec-system-settings-sonoma'

	@Created: Thursday, January 4, 2024 at 12:58:11 PM
	@Last Modified: Thursday, January 4, 2024 at 12:58:11 PM
	@Change Logs:
*)
use scripting additions

use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"
use uiutilLib : script "core/ui-util"
use spotScript : script "core/spot-test"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set cases to listUtil's splitByLine("
		Main
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
		sut's revealPrivacyAndSecurity_Accessibility()
		
	else if caseIndex is 2 then
		
	else if caseIndex is 3 then
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set retry to retryLib's new()
	set uiutil to uiutilLib's new()
	
	script SystemSettingsSonomaDecorator
		property parent : mainScript
		
		on revealPrivacyAndSecurity_Accessibility()
			tell application "System Settings"
				activate
				delay 0.4 -- Fails without this delay.
				set current pane to pane id "com.apple.settings.PrivacySecurity.extension"
			end tell
			
			script WindowChangeWaiter
				tell application "System Events" to tell process "System Settings"
					if exists (window "Privacy & Security") then return true
				end tell
			end script
			exec of retry on result for 3
			
			
			tell application "System Events" to tell process "System Settings"
				-- Accessibility is dying on each macOS release or maybe the old tools can no longer detect it.
				try
					click button 16 of group 1 of scroll area 1 of group 1 of list 2 of splitter group 1 of list 1 of front window
					return true
				end try
				-- uiutil's printAttributeValues(button 16 of group 1 of scroll area 1 of group 1 of list 2 of splitter group 1 of list 1 of front window)
				
				false
			end tell
		end revealPrivacyAndSecurity_Accessibility
	end script
end decorate