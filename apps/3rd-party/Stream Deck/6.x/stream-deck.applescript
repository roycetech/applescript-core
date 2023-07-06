(* 
	This script wraps some of the Elgato Stream Deck app functionality.
	This script is slow when changing profile via menu so we just ignored the 
	application response to prevent this script from blocking.
	
	@Requires:
		Elgato Stream Deck App
		Keyboard Maestro with Custom Macros

	@Installation:
		Run `make install` from this file's sub directory.		
*)

use std : script "std"
use loggerFactory : script "logger-factory"
use listUtil : script "list"
use textUtil : script "string"
use spotScript : script "spot-test"
use overriderLib : script "overrider"

property logger : missing value
property isSpot : false

if {"Script Editor", "Script Debugger"} contains the name of current application then
	set isSpot to true
	spotCheck()
end if

on spotCheck()
	loggerFactory's injectBasic(me, "stream-deck")
	set thisCaseId to "stream-deck-spotCheck"
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: Switch Profile: Found
		Manual: Switch Profile: Not Found
		Manual: Switch Profile: Percipio
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	if caseDesc starts with "Manual: Switch Profile:" then
		set caseProfile to textUtil's stringAfter(caseDesc, "Switch Profile: ")
		logger's debugf("caseProfile: {}", caseProfile)
		sut's switchProfile(caseProfile)
		
	end if
	if caseIndex is 1 then
		logger's infof("Switch Profile: Found: {}", sut's switchProfile("Work - Default"))
		
	else if caseIndex is 2 then
		logger's infof("Switch Profile: Not Found: {}", sut's switchProfile("Unicorn"))
		
	else if caseIndex is 3 then
		logger's infof("Switch Profile: Percipio: {}", sut's switchProfile("Percipio"))
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	if std's appExists("Elgato Stream Deck") is false then error "Elgato Stream Deck app needs to be installed"
	
	loggerFactory's injectBasic(me, "stream-deck")
	
	script StreamDeckInstance
		
		(* 
			Very slow without the ignoring block.
			
			@returns true if the profile was found, else false. (Not implemented due to performance issue)
		*)
		on switchProfile(profileName)
			ignoring application responses
				tell application "System Events" to tell process "Stream Deck"
					try
						click menu bar item 1 of menu bar 2
					end try
				end tell
			end ignoring
			
			delay 0.1
			
			ignoring application responses
				tell application "System Events" to tell process "Stream Deck"
					try
						click menu item profileName of menu 1 of menu bar item 1 of menu bar 2
						return true
					end try
				end tell
			end ignoring
			false
		end switchProfile
	end script
	
	if not isSpot then 
		set overrider to overriderLib's new()
		return overrider's applyMappedOverride(StreamDeckInstance)
	end if

	StreamDeckInstance
end new
