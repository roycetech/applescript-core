(*
	@Purpose:
		Wrapper for CleanShot X app. To be used only after the settings window has already bean launched manually.

	NOTE: Only settings I personally use is implemented right now. Add handlers on as needed basis.
		See decorators for per-tab handlers. Tab with few handlers implemented are included in this main script.

	@Issues:
		Tab switching works but the highlighted tab doesn't change. Minor visual quirk.	

	@Project:
		applescript-core
		
	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/CleanShot X/4.7.4/cleanshot-x'

	@Created: Sunday, December 29, 2024 at 8:01:57 PM
	@Last Modified: July 24, 2023 10:56 AM
*)
use scripting additions

use loggerFactory : script "core/logger-factory"
use cliclickLib : script "core/cliclick"
use retryLib : script "core/retry"

use decCleanShotXGeneral : script "core/dec-cleanshot-x-general"
use decCleanShotXShortcuts : script "core/dec-cleanshot-x-shortcuts"
use decCleanShotXQuickAccess : script "core/dec-cleanshot-x-quick-access"
use decCleanShotXAdvanced : script "core/dec-cleanshot-x-advanced"

property logger : missing value
property cliclick : missing value
property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set processLib to script "core/process"
	set spotScript to script "core/spot-test"
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP:
		Manual: Show Settings
		Manual: Switch Tab
		Manual: Wallpaper: Set Transparent
		Manual: Wallpaper: Set With wallpaper
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	sut's showSettings()
	
	logger's infof("Window: Screenshot: {}", sut's getWindowScreenshot())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's showSettings()
		
	else if caseIndex is 3 then
		set tabTitle to "Unicorn"
		set tabTitle to "General"
		-- set tabTitle to "Wallpaper"
		-- set tabTitle to "Cloud"
		
		
		logger's debugf("tabTitle: {}", tabTitle)
		sut's switchTab(tabTitle)
		
		set csxProcess to processLib's new("CleanShot X")
		csxProcess's moveFirstWindow(1000, 30)
		
	else if caseIndex is 4 then
		sut's setScreenshot("Transparent")
		
	else if caseIndex is 5 then
		sut's setScreenshot("With wallpaper")
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *) 
on new()
	loggerFactory's inject(me)
	set cliclick to cliclickLib's new()
	set retry to retryLib's new()
	
	script CleanShotXInstance
		on showSettings()
			-- activate application "CleanShot X"
			open location "cleanshot://open-settings"
			
			script WindowWaiter
				tell application "System Events" to tell process "CleanShot X"
					if exists (window 1) then return true
				end tell
			end script
			exec of retry on result for 3
			
			tell application "System Events" to tell process "CleanShot X"
				if not my isAllowApplicationsToControlCleanShot() then
					my toggleAllowApplicationsToControlCleanShot()
				end if
			end tell
		end showSettings
		
		
		on toggleAllowApplicationsToControlCleanShot()
			if running of application "CleanShot X" is false then return
			
			tell application "System Events" to tell process "CleanShot X"
				try
					click checkbox "Allow applications to control CleanShot" of front window
				end try
			end tell
		end toggleAllowApplicationsToControlCleanShot
		
		
		on isAllowApplicationsToControlCleanShot()
			tell application "System Events" to tell process "CleanShot X"
				try
					return value of checkbox "Allow applications to control CleanShot" of front window is 1
				end try
			end tell
			false
		end isAllowApplicationsToControlCleanShot
		
		
		(*
			@tabkey - general, wallpaper, shortcuts, quickaccess, recording, screenshots, annotate, cloud, advanced, about.
		*)
		on switchTab(tabKey)
			if running of application "CleanShot X" is false then return
			
			open location "cleanshot://open-settings?tab=" & tabKey
			return
			
			tell application "System Events" to tell process "CleanShot X"
				set frontmost to true
				try
					-- click button tabTitle of toolbar 1 of front window
					lclick of cliclick at button tabTitle of toolbar 1 of front window
				on error the errorMessage number the errorNumber
					log errorMessage
				end try
			end tell
		end switchTab
		
		
		(* 
			Wall paper tab settings
			@returns 'With wallpaper' or Transparent 
		*)
		on getWindowScreenshot()
			if running of application "CleanShot X" is false then return
			
			tell application "System Events" to tell process "CleanShot X"
				if value of radio button 3 of window 1 is 1 then return "Transparent"
				if value of radio button 4 of window 1 is 1 then return "With wallpaper"
			end tell
			
			missing value
		end getWindowScreenshot
		
		
		on setScreenshot(newValue)
			if running of application "CleanShot X" is false then return
			
			tell application "System Events" to tell process "CleanShot X"
				if newValue is "Transparent" then click radio button 3 of window 1
				if newValue is "With wallpaper" then click radio button 4 of window 1
			end tell
		end setScreenshot
	end script
	
	decCleanShotXGeneral's decorate(result)
	decCleanShotXShortcuts's decorate(result)
	decCleanShotXQuickAccess's decorate(result)
	decCleanShotXAdvanced's decorate(result)
end new
