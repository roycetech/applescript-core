(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/1st-party/Script Editor/2.11/dec-script-editor-settings'

	@Created: Mon, May 19, 2025 at 02:13:48 PM
	@Last Modified: Mon, May 19, 2025 at 02:13:48 PM
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
		Manual: Hide Settings
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
	set sutLib to script "core/script-editor"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	logger's infof("Settings window present: {}", sut's isSettingsWindowPresent())
	logger's infof("Settings window tab name: {}", sut's getSettingsSelectedTabName())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's showSettings()
		
	else if caseIndex is 3 then
		sut's closeSettings()
		
	else if caseIndex is 4 then
		sut's showSettings()
		set sutSettingsTabName to "Unicorn"
		set sutSettingsTabName to "General"
		set sutSettingsTabName to "Editing"
		logger's infof("sutSettingsTabName: {}", sutSettingsTabName)
		
		sut's switchSettingsTab(sutSettingsTabName)
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script ScriptEditorSettingsDecorator
		property parent : mainScript
		
		on isSettingsWindowPresent()
			if running of application "Script Editor" is false then return false
			
			tell application "System Events" to tell process "Script Editor"
				if exists (window "General") then return true
				if exists (window "History") then return true
				if exists (window "Editing") then return true
				if exists (window "Formatting") then return true
			end tell
			
			false
		end isSettingsWindowPresent
		
		on showSettings()
			if running of application "Script Editor" is false then return
			if isSettingsWindowPresent() then return
			
			tell application "System Events" to tell process "Script Editor"
				try
					click (first menu item of menu 1 of menu bar item "Script Editor" of menu bar 1 whose title starts with "Settings")
				end try
			end tell
		end showSettings
		
		
		on getSettingsWindow()
			if not isSettingsWindowPresent() then return missing value
			
			tell application "System Events" to tell process "Script Editor"
				if exists (window "General") then return window "General"
				if exists (window "History") then return window "History"
				if exists (window "Editing") then return window "Editing"
				if exists (window "Formatting") then return window "Formatting"
			end tell
			
			missing value
		end getSettingsWindow
		
		on closeSettings()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			
			tell application "System Events"
				click (first button of settingsWindow whose description is "close button")
			end tell
		end closeSettings
		
		on switchSettingsTab(newTabName)
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			if getSettingsSelectedTabName() is equal to newTabName then return
			
			tell application "System Events"
				try
					click button newTabName of toolbar 1 of settingsWindow
				end try
			end tell
		end switchSettingsTab
		
		
		on getSettingsSelectedTabName()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value
			
			tell application "System Events"
				title of settingsWindow
			end tell
		end getSettingsSelectedTabName
		
		
		(*
			This is used by the tab-specific handlers.
		*)
		on _toggleSettingsCheckbox(settingsTabTitle, checkboxLabel)
			if running of application "Script Editor" is false then return
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			
			switchSettingsTab(settingsTabTitle)
			
			tell application "System Events" to tell process "Script Editor"
				try
					click checkbox checkboxLabel of settingsWindow
				end try
			end tell
		end _toggleSettingsCheckbox

		(*
			This is used by the tab-specific handlers.
		*)
		on _isSettingsCheckboxChecked(settingsTabTitle, checkboxLabel)
			if running of application "Script Editor" is false then return
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			
			switchSettingsTab(settingsTabTitle)
			
			tell application "System Events" to tell process "Script Editor"
				try
					value of checkbox checkboxLabel of settingsWindow is 1
				end try
			end tell
		end _toggleSettingsCheckbox
	end script
end decorate
