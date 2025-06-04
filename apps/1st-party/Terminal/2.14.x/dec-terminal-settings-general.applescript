(*
	@Purpose:


	@UI Notes:
		Only the On startup, open section radio buttons > popup, has accessibility label. The other pop ups were written by lazy developers

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-settings-general

	@Created: Sun, Jun 01, 2025 at 08:05:43 AM
	@Last Modified: Sun, Jun 01, 2025 at 08:05:43 AM
	@Change Logs:
*)
use unic : script "core/unicodes"

use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"

property logger : missing value

property LABEL_CHECKBOX_USE_COMMAND : "Use " & unic's COMMAND & "-1 through " & unic's COMMAND & "-9 to switch tabs"


if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Set new window profile
		Manual: Set Shell open with
		Manual: Set New windows open with profile
		Manual: Set New windows open with directory
	
		Manual: Set New tabs open with profile
		Manual: Set New tabs open with directory
		Manual: Toggle use command-number to switch tabs
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
	
	logger's infof("On startup, open: {}", sut's getOnStartupOpen())
	logger's infof("On startup, open: New window with profile: {}", sut's getOnStartupOpenNewWindowWithProfile())
	
	logger's infof("Shells open with: {}", sut's getShellsOpenWith())
	logger's infof("Shell open with: Command: {}", sut's getShellOpenWithCommand())
	
	logger's infof("New windows open with profile: {}", sut's getNewWindowsOpenWithProfile())
	logger's infof("New windows open with directory: {}", sut's getNewWindowsOpenWithDirectory())
	
	logger's infof("New tabs open with profile: {}", sut's getNewTabsOpenWithProfile())
	logger's infof("New tabs open with directory: {}", sut's getNewTabsOpenWithDirectory())
	logger's infof("Use command-num to switch tabs: {}", sut's isUseCommandTabToSwitchTabs())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		set profileTitle to "Unicorn"
		set profileTitle to "Pro"
		
		sut's setNewWindowWithProfile(profileTitle)
		
	else if caseIndex is 3 then
		set sutShellOpenWith to "Unicorn"
		set sutShellOpenWith to "Command (complete path):"
		set sutShellOpenWith to "Default login shell"
		logger's debugf("sutShellOpenWith: {}", sutShellOpenWith)
		
		sut's setShellsOpenWith(sutShellOpenWith)
		
	else if caseIndex is 4 then
		set sutNewWindowsOpenWithProfile to "Unicorn"
		set sutNewWindowsOpenWithProfile to "Same Profile"
		set sutNewWindowsOpenWithProfile to "Default Profile"
		
		logger's debugf("sutNewWindowsOpenWithProfile: {}", sutNewWindowsOpenWithProfile)
		
		sut's setNewWindowsOpenWithProfile(sutNewWindowsOpenWithProfile)
		
	else if caseIndex is 5 then
		set sutNewWindowsOpenWithDirectory to "Unicorn"
		set sutNewWindowsOpenWithDirectory to "Same Working Directory"
		set sutNewWindowsOpenWithDirectory to "Default Working Directory"
		
		logger's debugf("sutNewWindowsOpenWithDirectory: {}", sutNewWindowsOpenWithDirectory)
		
		sut's setNewWindowsOpenWithDirectory(sutNewWindowsOpenWithDirectory)
		
	else if caseIndex is 6 then
		set sutNewTabsOpenWithProfile to "Unicorn"
		set sutNewTabsOpenWithProfile to "Same Profile"
		set sutNewTabsOpenWithProfile to "Default Profile"
		
		logger's debugf("sutNewTabsOpenWithProfile: {}", sutNewTabsOpenWithProfile)
		
		sut's setNewTabsOpenWithProfile(sutNewTabsOpenWithProfile)
		
	else if caseIndex is 7 then
		set sutNewTabsOpenWithDirectory to "Unicorn"
		set sutNewTabsOpenWithDirectory to "Same Working Directory"
		set sutNewTabsOpenWithDirectory to "Default Working Directory"
		
		logger's debugf("sutNewTabsOpenWithDirectory: {}", sutNewTabsOpenWithDirectory)
		
		sut's setNewTabsOpenWithDirectory(sutNewTabsOpenWithDirectory)
		
	else if caseIndex is 8 then
		sut's toggleUseCommandTabToSwitchTabs()
		
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set kb to kbLib's new()
	
	script TerminalSettingsGeneralDecorator
		property parent : mainScript
		
		on getOnStartupOpen()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value
			
			tell application "System Events" to tell process "Terminal"
				first radio button of radio group 1 of group 1 of settingsWindow whose value is 1
				return title of result
			end tell
			
			missing value
		end getOnStartupOpen
		
		
		on getOnStartupOpenNewWindowWithProfile()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value
			
			tell application "System Events" to tell process "Terminal"
				return value of first pop up button of group 1 of settingsWindow whose description is "startup window profile"
				-- the only other popup with label, ""startup window group"
			end tell
			
			missing value
		end getOnStartupOpenNewWindowWithProfile
		-- TODO: set when the window group radio is enabled. It isn't right now.
		
		
		on getShellsOpenWith()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value
			
			tell application "System Events" to tell process "Terminal"
				first radio button of radio group 2 of group 1 of settingsWindow whose value is 1
				return title of result
			end tell
			
			missing value
		end getShellsOpenWith
		
		
		on setShellsOpenWith(newValue)
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			
			tell application "System Events" to tell process "Terminal"
				try
					click (radio button newValue of radio group 2 of group 1 of settingsWindow)
				end try
			end tell
		end setShellsOpenWith
		
		
		on getShellOpenWithCommand()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value
			
			tell application "System Events" to tell process "Terminal"
				return value of text field 1 of group 1 of settingsWindow
			end tell
			
			missing value
		end getShellOpenWithCommand
		
		
		on getNewWindowsOpenWithProfile()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value
			
			tell application "System Events" to tell process "Terminal"
				return value of pop up button 6 of group 1 of settingsWindow
			end tell
			
			missing value
		end getNewWindowsOpenWithProfile
		
		
		on setNewWindowsOpenWithProfile(profileTitle)
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			
			tell application "System Events" to tell process "Terminal"
				set newWindowsProfilePopup to pop up button 6 of group 1 of settingsWindow
				click newWindowsProfilePopup
				delay 0.1
				try
					click menu item profileTitle of menu 1 of newWindowsProfilePopup
				on error errorMessage number errorNumber
					logger's warn(errorMessage)
					kb's pressKey("esc")
				end try
			end tell
		end setNewWindowsOpenWithProfile
		
		
		on getNewWindowsOpenWithDirectory()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value
			
			tell application "System Events" to tell process "Terminal"
				return value of pop up button 3 of group 1 of settingsWindow
			end tell
			
			missing value
		end getNewWindowsOpenWithDirectory
		
		
		on setNewWindowsOpenWithDirectory(directoryTitle)
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			
			tell application "System Events" to tell process "Terminal"
				set newWindowsDirectoryPopup to pop up button 3 of group 1 of settingsWindow
				click newWindowsDirectoryPopup
				delay 0.1
				try
					click menu item directoryTitle of menu 1 of newWindowsDirectoryPopup
				on error errorMessage number errorNumber
					logger's warn(errorMessage)
					kb's pressKey("esc")
				end try
			end tell
		end setNewWindowsOpenWithDirectory
		
		
		on getNewTabsOpenWithProfile()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value
			
			tell application "System Events" to tell process "Terminal"
				return value of pop up button 4 of group 1 of settingsWindow
			end tell
			
			missing value
		end getNewTabsOpenWithProfile
		
		
		on setNewTabsOpenWithProfile(profileTitle)
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			
			tell application "System Events" to tell process "Terminal"
				set newTabsProfilePopup to pop up button 4 of group 1 of settingsWindow
				click newTabsProfilePopup
				delay 0.1
				try
					click menu item profileTitle of menu 1 of newTabsProfilePopup
				on error errorMessage number errorNumber
					logger's warn(errorMessage)
					kb's pressKey("esc")
				end try
			end tell
		end setNewTabsOpenWithProfile
		
		
		on getNewTabsOpenWithDirectory()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value
			
			tell application "System Events" to tell process "Terminal"
				return value of pop up button 5 of group 1 of settingsWindow
			end tell
			
			missing value
		end getNewTabsOpenWithDirectory
		
		
		on setNewTabsOpenWithDirectory(directoryTitle)
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			
			tell application "System Events" to tell process "Terminal"
				set newTabsDirectoryPopup to pop up button 5 of group 1 of settingsWindow
				click newTabsDirectoryPopup
				delay 0.1
				try
					click menu item directoryTitle of menu 1 of newTabsDirectoryPopup
				on error errorMessage number errorNumber
					logger's warn(errorMessage)
					kb's pressKey("esc")
				end try
			end tell
		end setNewTabsOpenWithDirectory
		
		
		on setStartupOpenNewWindowWithProfile(profileTitle)
			setNewWindowWithProfile(profileTitle)
		end setStartupOpenNewWindowWithProfile
		
		
		on setNewWindowWithProfile(profileTitle)
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value
			
			tell application "System Events" to tell process "Terminal"
				set newWindowProfilePopup to first pop up button of group 1 of settingsWindow whose description is "startup window profile"
				click newWindowProfilePopup
				delay 0.1
				try
					click menu item profileTitle of menu 1 of newWindowProfilePopup
				on error the errorMessage number the errorNumber
					logger's warn(errorMessage)
					kb's pressKey("esc")
				end try
			end tell
		end setNewWindowWithProfile
		
		on isUseCommandTabToSwitchTabs()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return false
			
			tell application "System Events" to tell process "Terminal"
				try
					return value of checkbox LABEL_CHECKBOX_USE_COMMAND of group 1 of settingsWindow is 1
				end try
			end tell
			false
		end isUseCommandTabToSwitchTabs
		
		
		on toggleUseCommandTabToSwitchTabs()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			
			tell application "System Events" to tell process "Terminal"
				try
					click checkbox LABEL_CHECKBOX_USE_COMMAND of group 1 of settingsWindow
				end try
			end tell
		end toggleUseCommandTabToSwitchTabs
		
		on setUseCommandTabToSwitchTabsOn()
			if not isUseCommandTabToSwitchTabs() then toggleUseCommandTabToSwitchTabs()
		end setUseCommandTabToSwitchTabsOn
		
		
		on setUseCommandTabToSwitchTabsOff()
			if isUseCommandTabToSwitchTabs() then toggleUseCommandTabToSwitchTabs()
		end setUseCommandTabToSwitchTabsOff
		
	end script
end decorate
