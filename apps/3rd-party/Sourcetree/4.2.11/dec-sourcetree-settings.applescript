(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Sourcetree/4.2.11/dec-sourcetree-settings

	@Created: Sat, May 24, 2025 at 05:35:06 AM
	@Last Modified: Sat, May 24, 2025 at 05:35:06 AM
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

use cliclickLib : script "core/cliclick"

property logger : missing value
property cliclick : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Show Settings
		Manual: Close Settings
		Manual: Switch Settings Tab
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
	set sutLib to script "core/sourcetree"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	logger's infof("Settings window open: {}", sut's isSettingsWindowOpen())
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's showSettings()
		
	else if caseIndex is 3 then
		sut's closeSettingsWindow()
		
	else if caseIndex is 4 then
		set sutTabName to "Unicorn"
		set sutTabName to "Accounts"
		set sutTabName to "Diff"
		logger's infof("New settings tab name: {}", sutTabName)
		
		sut's switchSettingsTab(sutTabName)
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set cliclick to cliclickLib's new()
	
	script SourcetreeSettingsDecorator
		property parent : mainScript
		
		on showSettings()
			if running of application "Sourcetree" is false then return
			
			tell application "System Events" to tell process "Sourcetree"
				try
					click (first menu item of menu 1 of menu bar item "Sourcetree" of menu bar 1 whose title starts with "Settings")
				end try
			end tell
		end showSettings
		
		
		on getSettingsWindow()
			tell application "System Events"
				if not (exists application process "Sourcetree") then return missing value
				set sourcetreeApp to application process "Sourcetree"
				set windowList to windows of sourcetreeApp
				
				repeat with w in windowList
					set winTitle to name of w
					set winSize to size of w
					set winHeight to item 2 of winSize
					
					-- Heuristic: short title, no "(", and height < 700 → likely a settings window
					if (length of winTitle is less than 20) and winTitle does not contain "(" and winHeight is less than 700 then
						return w
					end if
				end repeat
			end tell
			
			missing value
		end getSettingsWindow
		
		on isSettingsWindowOpen()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is not missing value then return true
			
			false
		end isSettingsWindowOpen
		
		
		on closeSettingsWindow()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return false
			
			tell application "System Events"
				click (first button of settingsWindow whose description is "close button")
			end tell
			
			false
		end closeSettingsWindow
		
		on switchSettingsTab(newTabName)
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			
			tell application "System Events" to tell process "Sourcetree"
				set frontmost to true
				try
					-- click button newTabName of toolbar 1 of settingsWindow
					-- perform action "AXPress" of button newTabName of toolbar 1 of settingsWindow
					lclick of cliclick at button newTabName of toolbar 1 of settingsWindow
				end try
			end tell
		end switchSettingsTab
		
	end script
end decorate
