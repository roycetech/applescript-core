(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Marked/2.6.46/dec-marked-settings

	@Created: Mon, May 26, 2025 at 08:08:00 AM
	@Last Modified: Mon, May 26, 2025 at 08:08:00 AM
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

property logger : missing value

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
	set sutLib to script "core/marked"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	logger's infof("Settings window present: {}", sut's isSettingsWindowPresent())
	logger's infof("Settings window selected tab name: {}", sut's getSettingsSelectedTabName())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's showSettings()
		
	else if caseIndex is 3 then
		sut's closeSettings()
		
	else if caseIndex is 4 then
		set sutTabName to "Unicorn"
		set sutTabName to "Preview"
		set sutTabName to "Apps"
		logger's debugf("sutTabName: {}", sutTabName)
		sut's switchSettingsTab(sutTabName)
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script MarkedSettingsDecorator
		property parent : mainScript
		
		on isSettingsWindowPresent()
			if running of application "Marked 2" is false then return false
			getSettingsWindow() is not missing value
		end isSettingsWindowPresent
		
		
		on showSettings()
			if isSettingsWindowPresent() then return
			
			tell application "System Events" to tell process "Marked 2"
				try
					click (first menu item of menu 1 of menu bar item "Marked 2" of menu bar 1 whose title starts with "Settings")
				end try
			end tell
		end showSettings
		
		
		on closeSettings()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			
			tell application "System Events" to tell process "Marked 2"
				try
					tell application "System Events" to tell process "Marked 2"
						first button of settingsWindow whose description is "close button"
						click result
					end tell
				end try
			end tell
		end closeSettings
		
		
		on getSettingsWindow()
			if running of application "Marked 2" is false then return missing value
			
			tell application "System Events" to tell process "Marked 2"
				try
					return the first window whose title does not end with ".md"
				end try
			end tell
			
			missing value
		end getSettingsWindow
		
		
		on switchSettingsTab(newTabName)
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			
			set currentSettingsTabName to getSettingsSelectedTabName()
			if currentSettingsTabName is equal to the newTabName then return
			
			tell application "System Events" to tell process "Marked 2"
				try
					click button newTabName of toolbar 1 of settingsWindow
				end try
			end tell
			
		end switchSettingsTab
		
		
		on getSettingsSelectedTabName()
			if isSettingsWindowPresent() is false then return missing value
			
			set settingsWindow to getSettingsWindow()
			tell application "System Events" to tell process "Marked 2"
				title of settingsWindow
			end tell
			
		end getSettingsSelectedTabName
		
		(*
			This is used by the tab-specific handlers.
		*)
		on _toggleSettingsTabbedCheckbox(settingsTabTitle, checkboxLabel)
			set settingsWindow to __initSettingsTabAndReturnWindow(settingsTabTitle)
			if settingsWindow is missing value then return missing value
			
			tell application "System Events" to tell process "Script Editor"
				try
					click checkbox checkboxLabel of tab group 1 of settingsWindow
				end try
			end tell
		end _toggleSettingsTabbedCheckbox
		
		(*
			This is used by the tab-specific handlers.
		*)
		on _toggleSettingsCheckbox(settingsTabTitle, checkboxLabel)
			set settingsWindow to __initSettingsTabAndReturnWindow(settingsTabTitle)
			if settingsWindow is missing value then return missing value
			
			tell application "System Events" to tell process "Script Editor"
				try
					click checkbox checkboxLabel of settingsWindow
				end try
			end tell
		end _toggleSettingsCheckbox
		
		
		(*
			This is used by the tab-specific handlers.
		*)
		on _triggerSettingsButton(settingsTabTitle, buttonLabel, buttonIndex)
			if buttonIndex is less than 1 then return missing value
			set settingsWindow to __initSettingsTabAndReturnWindow(settingsTabTitle)
			if settingsWindow is missing value then return missing value
			
			
			tell application "System Events" to tell process "Script Editor"
				try
					buttons of settingsWindow whose title is buttonLabel
					click item buttonIndex of result
				end try
			end tell
		end _triggerSettingsButton
		
		
		(*
			This is used by the tab-specific handlers.
		*)
		on _isSettingsTabbedCheckboxChecked(settingsTabTitle, checkboxLabel)
			set settingsWindow to __initSettingsTabAndReturnWindow(settingsTabTitle)
			if settingsWindow is missing value then return missing value
			
			tell application "System Events" to tell process "Script Editor"
				try
					return value of checkbox checkboxLabel of tab group 1 of settingsWindow is 1
				on error the errorMessage number the errorNumber
					log errorMessage
				end try
			end tell
			
			false
		end _isSettingsTabbedCheckboxChecked
		
		(*
			This is used by the tab-specific handlers.
		*)
		on _isSettingsCheckboxChecked(settingsTabTitle, checkboxLabel)
			set settingsWindow to __initSettingsTabAndReturnWindow(settingsTabTitle)
			if settingsWindow is missing value then return missing value
			
			tell application "System Events" to tell process "Script Editor"
				try
					return value of checkbox checkboxLabel of settingsWindow is 1
				on error the errorMessage number the errorNumber
					log errorMessage
				end try
			end tell
			
			false
		end _isSettingsCheckboxChecked
		
		on __initSettingsTabAndReturnWindow(settingsTabTitle)
			if running of application "Marked 2" is false then return missing value
			
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value
			
			switchSettingsTab(settingsTabTitle)
			settingsWindow
		end __initSettingsTabAndReturnWindow
	end script
end decorate
