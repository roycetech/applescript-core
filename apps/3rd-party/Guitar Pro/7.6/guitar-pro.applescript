(*
	@Project:
		applescript-core
		
	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Guitar Pro/7.6/guitar-pro'

	@Created: Thursday, April 25, 2024 at 6:13:37 PM
	@Last Modified: July 24, 2023 10:56 AM
*)

use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"

use spotScript : script "core/spot-test"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: nil
		Manual: Turn On Metronome
		Manual: Turn Off Metronome
		Manual: Turn On Count-in 
		Manual: Turn Off Count-in
		
		Manual: Play from beginning
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	logger's infof("Metronome: {}", sut's metronomeStatus())
	logger's infof("Count-in: {}", sut's countInStatus())
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's turnOnMetronome()
		
	else if caseIndex is 3 then
		sut's turnOffMetronome()
		
	else if caseIndex is 4 then
		sut's turnOnCountIn()
		
	else if caseIndex is 5 then
		sut's turnOffCountIn()
		
	else if caseIndex is 6 then
		sut's playFromBeginning()
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck

(*  *)
on new()
	loggerFactory's inject(me)
	
	script GuitarProInstance
		on startPlaying()
			if running of application "Guitar Pro 7" is false then return
			
			tell application "System Events" to tell process "GuitarPro7"
				try
					click menu item "Play" of menu 1 of menu bar item "Sound" of menu bar 1
				end try
			end tell
		end startPlaying
		
		on stopPlaying()
			if running of application "Guitar Pro 7" is false then return
			
			tell application "System Events" to tell process "GuitarPro7"
				try
					click menu item "Stop" of menu 1 of menu bar item "Sound" of menu bar 1
				end try -- Menu not available when it's not even playing.
			end tell
		end stopPlaying
		
		on turnOnMetronome()
			if running of application "Guitar Pro 7" is false then return
			
			if metronomeStatus() then return
			
			tell application "System Events" to tell process "GuitarPro7"
				click menu item "Metronome" of menu 1 of menu bar item "Sound" of menu bar 1
			end tell
		end turnOnMetronome
		
		on metronomeStatus()
			if running of application "Guitar Pro 7" is false then return missing value
			
			tell application "System Events" to tell process "GuitarPro7"
				value of attribute "AXMenuItemMarkChar" of menu item "Metronome" of menu 1 of menu bar item "Sound" of menu bar 1 is not missing value
			end tell
		end metronomeStatus
		
		on turnOffMetronome()
			if running of application "Guitar Pro 7" is false then return
			
			if not metronomeStatus() then return
			
			tell application "System Events" to tell process "GuitarPro7"
				click menu item "Metronome" of menu 1 of menu bar item "Sound" of menu bar 1
			end tell
		end turnOffMetronome
		
		on turnOnCountIn()
			if running of application "Guitar Pro 7" is false then return
			
			if countInStatus() then return
			
			tell application "System Events" to tell process "GuitarPro7"
				click menu item "Count-in" of menu 1 of menu bar item "Sound" of menu bar 1
			end tell
		end turnOnCountIn
		
		on countInStatus()
			if running of application "Guitar Pro 7" is false then return missing value
			
			tell application "System Events" to tell process "GuitarPro7"
				value of attribute "AXMenuItemMarkChar" of menu item "Count-in" of menu 1 of menu bar item "Sound" of menu bar 1 is not missing value
			end tell
		end countInStatus
		
		on turnOffCountIn()
			if running of application "Guitar Pro 7" is false then return
			
			if not countInStatus() then return
			
			tell application "System Events" to tell process "GuitarPro7"
				click menu item "Count-in" of menu 1 of menu bar item "Sound" of menu bar 1
			end tell
		end turnOffCountIn
		
		on playFromBeginning()
			if running of application "Guitar Pro 7" is false then return
			
			tell application "System Events" to tell process "GuitarPro7"
				click menu item "Play from the Beginning" of menu 1 of menu bar item "Sound" of menu bar 1
			end tell
		end playFromBeginning
	end script
end new
