(*
	WIP: Migrate from Preferences.

	@Purpose:
		The original safari script is quite big and we want to improve its manageability by breaking it down into smaller pieces.
		This decorator will contain the handlers relating to tab groups.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/17.5/dec-safari-preferences

	@Created: Fri, Jul 12, 2024 at 2:58:38 PM
	@Last Modified: 2025-03-10 11:38:42
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"


property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		INFO
		Manual: Show Settings Window
		Manual: Close Settings Window
		Manual: Switch Settings Tab
		Manual: Enable extension

		Manual: Disable extension
		Manual: Close on Target Status
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
	set sutLib to script "core/safari"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	logger's infof("Is Preferences window active: {}", sut's isPreferencesWindowActive())
	logger's infof("Active preferences tab: {}", sut's getPreferencesTabName())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's showPreferences()
		
	else if caseIndex is 3 then
		sut's closePreferences()
		
	else if caseIndex is 4 then
		sut's showPreferences()
		-- sut's switchPreferencesTab("Unicorn")
		sut's switchPreferencesTab("Passwords")
		
	else if caseIndex is 5 then
		sut's enableExtension("Unicorn")
		sut's enableExtension("safari-extension-poc")
		
	else if caseIndex is 6 then
		sut's disableExtension("Unicorn")
		sut's disableExtension("safari-extension-poc")
		
	else if caseIndex is 7 then
		sut's closeOnExtensionToggle("safari-extension-poc", 0)
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script SafariPreferencesDecorator
		property parent : mainScript
		
		on showSettings()
			showPreferences()
		end showSettings
		
		on showPreferences()
			if isPreferencesWindowActive() then return
			
			tell application "System Events" to tell process "Safari"
				try
					click (first menu item of menu 1 of menu bar item "Safari" of menu bar 1 whose title starts with "Settings")
				end try
			end tell
		end showPreferences
		
		
		on closePreferences()
			set prefsWindow to getPreferencesWindow()
			if prefsWindow is missing value then return
			
			tell application "System Events" to tell process "Safari"
				click (first button of prefsWindow whose description is "close button")
			end tell
		end closePreferences
		
		
		on isPreferencesWindowActive()
			if running of application "Safari" is false then return false
			
			getPreferencesWindow() is not missing value
		end isPreferencesWindowActive
		
		
		on switchPreferencesTab(tabName)
			set prefsWindow to getPreferencesWindow()
			if prefsWindow is missing value then return
			
			tell application "System Events" to tell process "Safari"
				try
					click (first button of toolbar 1 of prefsWindow whose title contains tabName)
				end try
			end tell
		end switchPreferencesTab
		
		
		on getPreferencesTabName()
			set prefsWindow to getPreferencesWindow()
			if prefsWindow is missing value then return
			
			tell application "System Events"
				title of prefsWindow
			end tell
		end getPreferencesTabName
		
		
		(*
			@returns true if extension is toggled.
		*)
		on enableExtension(extensionKeyword)
			set prefsWindow to getPreferencesWindow()
			if prefsWindow is missing value then return false
			
			if getPreferencesTabName() is not "Extensions" then switchPreferencesTab("Extensions")
			set extRow to getExtensionRow(extensionKeyword)
			if extRow is missing value then return false
			
			tell application "System Events" to tell process "Safari"
				if value of checkbox 1 of UI element 1 of extRow is 0 then
					click checkbox 1 of UI element 1 of extRow
					return true
				end if
			end tell
			
			false
		end enableExtension
		
		
		(*
			@returns true if extension is toggled.
		*)
		on disableExtension(extensionKeyword)
			set prefsWindow to getPreferencesWindow()
			if prefsWindow is missing value then return false
			
			if getPreferencesTabName() is not "Extensions" then switchPreferencesTab("Extensions")
			set extRow to getExtensionRow(extensionKeyword)
			if extRow is missing value then return false
			
			tell application "System Events" to tell process "Safari"
				if value of checkbox 1 of UI element 1 of extRow is 1 then
					click checkbox 1 of UI element 1 of extRow
					return true
				end if
			end tell
			false
		end disableExtension
		
		
		on closeOnExtensionToggle(extensionKeyword, targetStatus)
			set retry to retryLib's new()
			set prefsWindow to getPreferencesWindow()
			if prefsWindow is missing value then return false
			
			if getPreferencesTabName() is not "Extensions" then switchPreferencesTab("Extensions")
			set extRow to getExtensionRow(extensionKeyword)
			if extRow is missing value then return false
			
			script ToggleWaiter
				tell application "System Events" to tell process "Safari"
					if value of checkbox 1 of UI element 1 of extRow is targetStatus then return true
				end tell
			end script
			exec of retry on result for 10
			if result is not missing value then closePreferences()
		end closeOnExtensionToggle
		
		
		on getExtensionRow(extensionKeyword)
			set prefsWindow to getPreferencesWindow()
			if prefsWindow is missing value then return
			
			if getPreferencesTabName() is not "Extensions" then switchPreferencesTab("Extensions")
			
			tell application "System Events" to tell process "Safari"
				set myExtRow to missing value
				try
					set myExtRow to first row of table 1 of scroll area 1 of group 1 of group 1 of group 1 of prefsWindow whose value of static text 1 of UI element 1 starts with extensionKeyword
				end try
				
			end tell
			myExtRow
		end getExtensionRow
		
		on getPreferencesWindow()
			tell application "System Events" to tell process "Safari"
				try
					return first window whose (enabled of second button is false and description of second button is "zoom button")
				end try
			end tell
			missing value
		end getPreferencesWindow
	end script
end decorate
