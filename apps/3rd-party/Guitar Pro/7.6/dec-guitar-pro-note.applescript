(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Guitar Pro/7.6/dec-guitar-pro-note'

	@Created: Monday, August 12, 2024 at 12:49:49 PM
	@Last Modified: Monday, August 12, 2024 at 12:49:49 PM
	@Change Logs:
*)
use listUtil : script "core/list"
use loggerFactory : script "core/logger-factory"

use unic : script "core/unicodes"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Main
		Manual: Decrease note duration
		Manual: Increase note duration
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	-- activate application "" 
	set sutLib to script "core/guitar-pro"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	logger's infof("Current note duration: {}", sut's getNoteDuration())
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's decreaseNoteDuration()
		
	else if caseIndex is 3 then
		sut's increaseNoteDuration()
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	
	script GuitarProNoteDecorator
		property parent : mainScript
		property NOTE_DURATIONS : missing value
		
		on getNoteDuration()
			if running of application "Guitar Pro 7" is false then return missing value
			
			tell application "System Events" to tell process "Guitar Pro 7"
				try
					title of (first menu item of menu 1 of menu item "Duration" of menu 1 of menu bar item "Note" of menu bar 1 whose value of attribute "AXMenuItemMarkChar" is equal to unic's MENU_CHECK)
				end try
			end tell
		end getNoteDuration
		
		
		on increaseNoteDuration()
			if running of application "Guitar Pro 7" is false then return
			
			set currentDuration to getNoteDuration()
			if currentDuration is missing value then return
			
			set durationIndex to listUtil's indexOf(NOTE_DURATIONS, currentDuration)
			logger's debugf("durationIndex: {}", durationIndex)
			
			if durationIndex is equal to the 1 then
				logger's info("Cannot increase, end reached")
				return
			end if
			
			set newDurationIndex to durationIndex - 1
			set newDurationTitle to item newDurationIndex of NOTE_DURATIONS
			
			tell application "System Events" to tell process "Guitar Pro 7"
				try
					click (first menu item of menu 1 of menu item "Duration" of menu 1 of menu bar item "Note" of menu bar 1 whose title is newDurationTitle)
				end try
			end tell
		end increaseNoteDuration
		
		
		on decreaseNoteDuration()
			if running of application "Guitar Pro 7" is false then return
			
			set currentDuration to getNoteDuration()
			if currentDuration is missing value then return
			
			set durationIndex to listUtil's indexOf(NOTE_DURATIONS, currentDuration)
			logger's debugf("durationIndex: {}", durationIndex)
			
			if durationIndex is greater than or equal to the number of items in NOTE_DURATIONS then
				logger's info("Cannot decrease, end reached")
				return
			end if
			
			set newDurationIndex to durationIndex + 1
			set newDurationTitle to item newDurationIndex of NOTE_DURATIONS
			
			tell application "System Events" to tell process "Guitar Pro 7"
				try
					click (first menu item of menu 1 of menu item "Duration" of menu 1 of menu bar item "Note" of menu bar 1 whose title is newDurationTitle)
				end try
			end tell
		end decreaseNoteDuration
	end script
	
	if running of application "Guitar Pro 7" then
		tell application "System Events" to tell process "Guitar Pro 7"
			try
				set GuitarProNoteDecorator's NOTE_DURATIONS to title of menu items of menu 1 of menu item "Duration" of menu 1 of menu bar item "Note" of menu bar 1 whose title contains "(+/-)"
			end try
		end tell
	end if
	
	GuitarProNoteDecorator
end decorate

