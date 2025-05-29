(*
	NOTE: Bartender window is not your typical window, it doesn't show menu items or show its window name in the menu bar.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Bartender/v5/bartender

	@Created: Tue, May 27, 2025 at 10:22:37 AM
	@Last Modified: July 24, 2023 10:56 AM
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
		NOOP
		Manual: Show Settings Window
		Manual: Close Settings Window
		Manual: Switch Settings Tab
		Manual: General: Set menu bar item spacing

		Manual: Dismiss dialog window
	")
	
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	logger's infof("Settings window present: {}", sut's isSettingsWindowPresent())
	logger's infof("Dialog window present: {}", sut's isDialogWindowPresent())
	logger's infof("Focused tab name: {}", sut's getFocusedTabName())
	logger's infof("General: Menu bar item spacing: {}", sut's getMenuBarItemSpacing())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's showSettings()
		
	else if caseIndex is 3 then
		sut's closeSettings()
		
	else if caseIndex is 4 then
		set sutTabName to "Unicorn"
		set sutTabName to "Presets"
		logger's debugf("sutTabName: {}", sutTabName)
		
		sut's switchTabName(sutTabName)
		
	else if caseIndex is 5 then
		set sutMenuBarItemSpacing to "Unicorn"
		set sutMenuBarItemSpacing to "Default Spacing"
		set sutMenuBarItemSpacing to "Tiny Spacing"
		
		logger's debugf("sutMenuBarItemSpacing: {}", sutMenuBarItemSpacing)
		
		sut's setMenuBarItemSpacing(sutMenuBarItemSpacing)
		
	else if caseIndex is 6 then
		sut's dismissDialogWithOK()
	o
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	set kb to kbLib's new()
	
	script BartenderInstance
		on isDialogWindowPresent()
			if running of application "Bartender 5" is false then return false
			
			set dialogWindow to getDialogWindow()
			dialogWindow is not missing value
		end isDialogWindowPresent
		
		
		on getDialogWindow()
			if running of application "Bartender 5" is false then return missing value
			
			tell application "System Events" to tell process "Bartender 5"
				try
					return first window whose subrole is "AXDialog"
				end try
			end tell
			
			missing value
		end getDialogWindow
		
		
		on dismissDialogWithOK()
			set dialogWindow to getDialogWindow()
			if dialogWindow is missing value then return
			
			tell application "System Events" to tell process "Bartender 5"
				click button "OK" of dialogWindow
			end tell
		end dismissDialogWithOK
		
		on getFocusedTabName()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value
			
			tell application "System Events" to tell process "Bartender 5"
				try
					first row of outline 1 of scroll area 1 of splitter group 1 of settingsWindow whose selected is true
					return name of UI elements of result as text -- Client calls fail without this coercion.
					
				end try
			end tell
			
			missing value
		end getFocusedTabName
		
		on switchTabName(newTabName)
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			
			tell application "System Events" to tell process "Bartender 5"
				try
					set selected of (first row of outline 1 of scroll area 1 of splitter group 1 of settingsWindow whose value of static text 1 of UI element 1 is newTabName) to true
				end try
			end tell
		end switchTabName
		
		
		on getMenuBarItemSpacing()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value
			if getFocusedTabName() is not equal to "General" then return missing value
			
			tell application "System Events" to tell process "Bartender 5"
				return value of pop up button 2 of splitter group 1 of settingsWindow
			end tell
		end getMenuBarItemSpacing
		
		
		on setMenuBarItemSpacing(newSpacing)
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			
			if getFocusedTabName() is not equal to "General" then
				switchTabName("General")
			end if
			
			tell application "System Events" to tell process "Bartender 5"
				set targetPopup to pop up button 2 of splitter group 1 of settingsWindow
				click targetPopup
				try
					click menu item newSpacing of menu 1 of targetPopup
				on error the errorMessage number the errorNumber
					-- Dismiss the popup
					kb's pressKey("escape")
					
				end try
			end tell
		end setMenuBarItemSpacing
		
		
		on showSettings()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is not missing value then return
			
			tell application "System Events" to tell process "Bartender 5"
				click menu item "Bartender Settings..." of menu "Bartender 5" of menu bar item "Bartender" of menu bar 2
			end tell
		end showSettings
		
		on closeSettings()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			
			tell application "System Events" to tell process "Bartender 5"
				click (first button of settingsWindow whose description is "close button")
			end tell
		end closeSettings
		
		
		on isSettingsWindowPresent()
			set settingsWindow to getSettingsWindow()
			
			settingsWindow is not missing value
		end isSettingsWindowPresent
		
		
		on getSettingsWindow()
			if running of application "Bartender 5" is false then return false
			
			tell application "System Events" to tell process "Bartender 5"
				try
					return first window whose subrole is "AXStandardWindow"
				end try
			end tell
			
			missing value
		end getSettingsWindow
		
	end script
end new
