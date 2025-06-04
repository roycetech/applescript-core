(*
	NOTE:
		Checkboxes with similar title works across tabs is the Profiles settings.
		Implementation is limited to options I personally use.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-settings

	@Created: Monday, December 23, 2024 at 6:55:56 AM
	@Last Modified: 2025-05-22 14:35:10
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"


property logger : missing value
property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Show Settings
		Manual: Close Settings

		Manual: Switch settings tab

		Manual: Toggle Use Option as Meta key On
		Manual: Toggle Use Option as Meta key Off
		Manual: Set Default Profile
		Manual: Set Selected Profile

		Manual: Iterate Profiles
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
	set sutLib to script "core/terminal"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	logger's infof("Settings dialog present: {}", sut's isSettingsWindowPresent())
	
	logger's infof("Window dimensions toggled: {}", sut's isDimensionsOn())
	logger's infof("Shared Active process name toggled: {}", sut's isActiveProcessNameOn())
	logger's infof("Shared Working directory or document toggled: {}", sut's isWorkingDirectoryOrDocumentOn())
	logger's infof("Keyboard: Option key is meta key: {}", sut's isUseOptionAsMetaKeyOn())
	logger's infof("Selected Profile: {}", sut's getSelectedProfile())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's showSettingsWindow()
		
	else if caseIndex is 3 then
		sut's closeSettingsWindow()
		
	else if caseIndex is 4 then
		
	else if caseIndex is 5 then
		set settingsTitle to "Unicorn"
		set settingsTitle to "General"
		set settingsTitle to "Profiles"
		set settingsTitle to "Window Groups"
		
		sut's switchSettingsTab(settingsTitle)
		
	else if caseIndex is 6 then
		set profileTabTitle to "Unicorn"
		set profileTabTitle to "Window"
		-- 		set profileTabTitle to "Tab"
		set profileTabTitle to "Keyboard"
		logger's infof("profileTabTitle: {}", profileTabTitle)
		
		sut's switchProfilesTab(profileTabTitle)
		
	else if caseIndex is 7 then
		sut's setDimensionsOff()
		
	else if caseIndex is 8 then
		sut's setDimensionsOn()
		
	else if caseIndex is 9 then
		sut's setActiveProcessNameOff()
		
	else if caseIndex is 10 then
		sut's setActiveProcessNameOn()
		
	else if caseIndex is 11 then
		sut's setWorkingDirectoryOrDocumentOff()
		
	else if caseIndex is 12 then
		sut's setUseOptionAsMetaKeyOn()
		
	else if caseIndex is 13 then
		sut's setUseOptionAsMetaKeyOff()
		
	else if caseIndex is 14 then
		set sutProfile to "Unicorn"
		set sutProfile to "Pro"
		
		sut's setDefaultProfile(sutProfile)
		
	else if caseIndex is 15 then
		set sutProfile to "Unicorn"
		set sutProfile to "Basic"
		-- set sutProfile to "Pro"
		
		sut's setSelectedProfile(sutProfile)
		logger's infof("Handler result: {}", result)
		
	else if caseIndex is 16 then
		sut's switchSettingsTab("Profiles")
		script ProfileNamePrinter
			on execute(nextRow)
				tell application "System Events"
					logger's infof("Profile name: {}", value of text field 1 of nextRow)
				end tell
			end execute
		end script
		sut's iterateProfiles(result)
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	set kb to kbLib's new()
	
	script TerminalSettingsDecorator
		property parent : mainScript
		
		on getSettingsWindow()
			if running of application "Terminal" is false then return missing value
			
			tell application "System Events" to tell process "Terminal"
			try
				return first window whose description is "dialog"
			end
			end tell
			
			missing value
		end getSettingsWindow
		
		
		on showSettingsWindow()
			if running of application "Terminal" is false then return
			
			tell application "System Events" to tell process "Terminal"
				try
					click (first menu item of menu 1 of menu bar item "Terminal" of menu bar 1 whose title starts with "Setting")
				end try
			end tell
		end showSettingsWindow
		
		on isSettingsWindowPresent()
			if running of application "Terminal" is false then return false
			
			tell application "System Events" to tell process "Terminal"
				return exists (first window whose description is "dialog")
			end tell
			
			false
		end isSettingsWindowPresent
		
		on closeSettingsWindow()
			if running of application "Terminal" is false then return
			if not isSettingsWindowPresent() then return
			
			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				try
					click (first button of settingsWindow whose role description is "close button")
				on error
					return
				end try
			end tell
		end closeSettingsWindow
		
		on switchSettingsTab(tabTitle)
			if running of application "Terminal" is false then return
			if not isSettingsWindowPresent() then return
			
			tell application "System Events" to tell process "Terminal"
				try
					set settingsWindow to first window whose description is "dialog"
				on error
					return
				end try
				
				if exists (button tabTitle of toolbar 1 of settingsWindow) then
					click button tabTitle of toolbar 1 of settingsWindow
					
				else if exists (radio button tabTitle of tab group 1 of group 1 of settingsWindow) then
					click radio button tabTitle of tab group 1 of group 1 of settingsWindow
				end if
			end tell
		end switchSettingsTab
	end script
end decorate

