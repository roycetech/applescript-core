(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Stream Deck/7.1.x/dec-stream-deck-settings-profiles'

	@Created: Thu, Jan 29, 2026 at 02:09:37 PM
	@Last Modified: Thu, Jan 29, 2026 at 02:09:37 PM
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
		Manual: Trigger Bottom Menu
		Manual: Trigger Backup All
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
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's triggerBottomMenu()
		
	else if caseIndex is 3 then
		sut's triggerBottomMenu()
		delay 0.5
		sut's triggerCreateBackup()
		
	else if caseIndex is 4 then
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script StreamDeckSettingsProfilesDecorator
		property parent : mainScript
		
		on triggerBottomMenu()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			
			tell application "System Events" to tell process "Stream Deck"
				set frontmost to true
				perform action "AXShowMenu" of menu button 2 of group 1 of group 1 of settingsWindow -- click doesn't work.
			end tell
		end triggerBottomMenu
		
		
		(* Invoke this after #triggerBottomMenu. *)
		on triggerCreateBackup()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			
			tell application "System Events" to tell process "Stream Deck"
				-- properties of windows whose description is "dialog"
				set popupWindow to the first window whose title is ""
				-- set popupWindow to the last window whose title is ""
				if popupWindow is missing value then return
				
				-- menu item "Backup All" of popupWindow
				-- menu item "Backup All" of window 2
				-- menu item 6 of window 2
				menu item 6 of popupWindow
				
				actions of (first menu item of menu item "Backup All" of popupWindow whose title starts with "Create Backup")
			end tell
		end triggerCreateBackup
	end script
end decorate
