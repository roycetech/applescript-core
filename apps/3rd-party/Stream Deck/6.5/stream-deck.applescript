(* 
	This script wraps some of the Elgato Stream Deck app functionality.
	This script is slow when changing profile via menu so we just ignored the 
	application response to prevent this script from blocking.
	
	@Version:
		6.5
	
	@Usage:
		use streamDeckLib : script "core/stream-deck"
		set streamDeck to streamDeckLib's new()

	@Requires:
		Elgato Stream Deck App
		lsusb installed via brew to check if stream deck via USB is plugged in.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Stream Deck/6.5/stream-deck'
		
	@Last Modified: July 25, 2023 9:02 PM
*)

use scripting additions

use std : script "core/std"
use loggerFactory : script "core/logger-factory"
use listUtil : script "core/list"
use textUtil : script "core/string"
use spotScript : script "core/spot-test"
use decoratorLib : script "core/decorator"

property logger : missing value
property isSpot : false

if {"Script Editor", "Script Debugger"} contains the name of current application then
	set isSpot to true
	spotCheck()
end if

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: Switch Profile: Found
		Manual: Switch Profile: Not Found
		Manual: Switch Profile: Percipio
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	logger's infof("USB Connected: {}", sut's isUsbConnected())
	(*
	if caseDesc starts with "Manual: Switch Profile:" then
		set caseProfile to textUtil's stringAfter(caseDesc, "Switch Profile: ")
		logger's debugf("caseProfile: {}", caseProfile)
		sut's switchProfile("Stream Deck XL", caseProfile)
		
	end if
*)
	
	if caseIndex is 1 then
		logger's infof("Switch Profile: Found: {}", sut's switchProfile("Stream Deck XL", "Work - Default"))
		-- logger's infof("Switch Profile: Found: {}", sut's switchProfile("Stream Deck XL", "Safari"))
		
	else if caseIndex is 2 then
		logger's infof("Switch Profile: Not Found: {}", sut's switchProfile("Stream Deck XL", "Unicorn"))
		
	else if caseIndex is 3 then
		logger's infof("Switch Profile: Percipio: {}", sut's switchProfile("Stream Deck XL", "Percipio"))
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	if std's appExists("Elgato Stream Deck") is false then error "Elgato Stream Deck app needs to be installed"
	loggerFactory's injectBasic(me)
	
	script StreamDeckInstance
		on isUsbConnected()
			try
				return (do shell script "/opt/homebrew/bin/lsusb | grep 'Stream Deck'") is not ""
			end try
			
			false
		end isUsbConnected
		
		(* 
			@returns true if the profile was found.
		*)
		on switchProfile(deviceName, profileName)
			
			tell application "System Events" to tell process "Stream Deck"
				try
					click menu item profileName of menu 1 of menu item deviceName of menu 1 of menu bar 2
					return true
				end try
			end tell
			
			false
		end switchProfile
	end script
	
	if not isSpot then
		set decorator to decoratorLib's new(StreamDeckInstance)
		return decorator's decorate()
	end if
	
	StreamDeckInstance
end new
