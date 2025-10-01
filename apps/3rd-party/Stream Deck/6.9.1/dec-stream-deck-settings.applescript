(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Stream Deck/6.9.1/dec-stream-deck-settings'

	@Created: Wed, Oct 01, 2025 at 01:04:40 PM
	@Last Modified: Wed, Oct 01, 2025 at 01:04:40 PM
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

property logger : missing value

use retryLib : script "core/retry"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Settings window - show
		Manual: Settings window - hide
		Manual: Settings window - switch tab
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
	set sutLib to script "core/stream-deck"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	logger's infof("Settings window present: {}", sut's isSettingsWindowPresent())
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's showSettingsWindow()
		
	else if caseIndex is 3 then
		sut's hideSettingsWindow()
		
	else if caseIndex is 4 then
		set sutTabTitle to "Unicorn"
		set sutTabTitle to "Plugins"
		-- set sutTabTitle to "General"
		
		logger's infof("sutTabTitle: {}", sutTabTitle)
		
		sut's switchSettingsTab(sutTabTitle)
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script StreamDeckSettingsDecorator
		property parent : mainScript
		
		on isSettingsWindowPresent()
			getSettingsWindow() is not missing value
		end isSettingsWindowPresent
		
		
		on showSettingsWindow()
			if running of application "Elgato Stream Deck" is false then return
			if isSettingsWindowPresent() then return
			
			set retry to retryLib's new()
			tell application "System Events" to tell process "Stream Deck"
				try
					click (first menu item of menu 1 of menu bar 2 whose title starts with "Preferences")
				end try
			end tell
			
			script SettingsWindowWaiter
				if isSettingsWindowPresent() then return true
			end script
			exec of retry on result for 15 by 0.2
		end showSettingsWindow
		
		
		on hideSettingsWindow()
			if running of application "Elgato Stream Deck" is false then return
			
			set settingsWindow to getSettingsWindow()
			tell application "System Events" to tell process "Stream Deck"
				try
					click (first button of settingsWindow whose description is "close button")
				end try
			end tell
		end hideSettingsWindow
		
		
		on getSettingsWindow()
			if running of application "Elgato Stream Deck" is false then return missing value
			
			tell application "System Events" to tell process "Stream Deck"
				try
					return window "Preferences"
				end try
			end tell
			missing value
		end getSettingsWindow
		
		
		on switchSettingsTab(tabTitle)
			if running of application "Elgato Stream Deck" is false then return
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			
			tell application "System Events" to tell process "Safari"
				try
					click radio button tabTitle of group 2 of settingsWindow
				end try
			end tell
		end switchSettingsTab
	end script
end decorate
