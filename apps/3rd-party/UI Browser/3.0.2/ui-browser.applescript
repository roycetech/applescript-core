(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/UI Browser/3.0.2/ui-browser'

	@Created: Sun, May 25, 2025 at 02:09:29 PM
	@Last Modified: July 24, 2023 10:56 AM
*)

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Switch to Screen Reader
		Manual: Show Settings
		Manual: Switch Settings Tab
		Manual: Open Edit AppleScript window: ON
		
		Manual: Open Edit AppleScript window: OFF
		Manual: Copy script to clipboard: ON
		Manual: Copy script to clipboard: OFF

	")
	
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	activate application "UI Browser"
	
	set sut to new()
	logger's infof("Settings tab: {}", sut's getSettingsSelectedTab())
	logger's infof("Settings: AppleScript: isOpenEditAppleScriptWindow(): {}", sut's isOpenEditAppleScriptWindow())
	logger's infof("Settings: AppleScript: isCopyScriptToClipboard(): {}", sut's isCopyScriptToClipboard())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's switchToScreenReader()
		
	else if caseIndex is 3 then
		sut's showSettings()
		
	else if caseIndex is 4 then
		set sutTabName to "Unicorn"
		set sutTabName to "General"
		set sutTabName to "AppleScript"
		logger's infof("sutTabName: {}", sutTabName)
		
		sut's switchSettingsTab(sutTabName)
		
	else if caseIndex is 5 then
		sut's setOpenEditAppleScriptWindowOn()
		
	else if caseIndex is 6 then
		sut's setOpenEditAppleScriptWindowOff()
		
	else if caseIndex is 7 then
		sut's setCopyScriptToClipboardOn()
		
	else if caseIndex is 8 then
		sut's setCopyScriptToClipboardOff()
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	
	script UiBrowserInstance
		on switchToScreenReader()
			if running of application "UI Browser" is false then return
			
			tell application "System Events" to tell process "UI Browser"
				try
					click menu item "Switch to Screen Reader" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
		end switchToScreenReader
		
		
		on showSettings()
			if running of application "UI Browser" is false then return
			
			tell application "System Events" to tell process "UI Browser"
				try
					click (first menu item of menu 1 of menu bar item "UI Browser" of menu bar 1 whose title starts with "Settings")
				end try
			end tell
		end showSettings
		
		on getSettingsWindow()
			if running of application "UI Browser" is false then return missing value
			
			try
				tell application "System Events" to tell process "UI Browser"
					return first window whose description is "Preferences"
				end tell
			end try
			
			missing value
		end getSettingsWindow
		
		
		on getSettingsSelectedTab()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value
			
			tell application "System Events"
				return title of first radio button of tab group 1 of settingsWindow whose value is 1
			end tell
			
			"wip"
		end getSettingsSelectedTab
		
		
		on switchSettingsTab(tabTitle)
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value
			
			tell application "System Events"
				try
					click (first radio button of tab group 1 of settingsWindow whose title is tabTitle)
				end try
			end tell
		end switchSettingsTab
		
		
		on isOpenEditAppleScriptWindow()
			_isSettingsCheckboxChecked("AppleScript", "Open Edit AppleScript window")
		end isOpenEditAppleScriptWindow
		
		on setOpenEditAppleScriptWindowOn()
			if not isOpenEditAppleScriptWindow() then _toggleSettingsCheckbox("AppleScript", "Open Edit AppleScript window")
		end setOpenEditAppleScriptWindowOn
		
		on setOpenEditAppleScriptWindowOff()
			if isOpenEditAppleScriptWindow() then _toggleSettingsCheckbox("AppleScript", "Open Edit AppleScript window")
		end setOpenEditAppleScriptWindowOff
		
		
		on isCopyScriptToClipboard()
			_isSettingsCheckboxChecked("AppleScript", "Copy script to clipboard")
		end isCopyScriptToClipboard
		
		on setCopyScriptToClipboardOn()
			if not isCopyScriptToClipboard() then _toggleSettingsCheckbox("AppleScript", "Copy script to clipboard")
		end setCopyScriptToClipboardOn
		
		on setCopyScriptToClipboardOff()
			if isCopyScriptToClipboard() then _toggleSettingsCheckbox("AppleScript", "Copy script to clipboard")
		end setCopyScriptToClipboardOff
		
		
		(*
			This is used by the tab-specific handlers.
		*)
		on _toggleSettingsCheckbox(settingsTabTitle, checkboxLabel)
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			
			switchSettingsTab(settingsTabTitle)
			
			tell application "System Events" to tell process "Script Editor"
				try
					click checkbox checkboxLabel of tab group 1 of settingsWindow
				end try
			end tell
		end _toggleSettingsCheckbox
		
		(*
			This is used by the tab-specific handlers.
		*)
		on _isSettingsCheckboxChecked(settingsTabTitle, checkboxLabel)
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			
			switchSettingsTab(settingsTabTitle)
			
			tell application "System Events" to tell process "Script Editor"
				try
					value of checkbox checkboxLabel of tab group 1 of settingsWindow is 1
				end try
			end tell
		end _isSettingsCheckboxChecked
	end script
end new
