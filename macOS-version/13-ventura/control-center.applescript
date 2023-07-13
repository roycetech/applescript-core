(* 
	NOTE: This script requires accessibility access, grant when prompted.
	
	Depends on the position of the focus checkbox to be the 2nd one. 

*)

use unic : script "unicodes"
use listUtil : script "list"

use loggerLib : script "logger"
use kbLib : script "keyboard"

use spotScript : script "spot-test"
use decoratorNetwork : "control-center_network"
use decoratorSound : "control-center_sound"
use decoratorFocus : "control-center_focus"

property logger : loggerLib's new("control-center")
property kb : kbLib's new()

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: Show Widgets 
		
		DND On
		Manual: DND On - From Work Focus
		DND Off
		Get DND Status - Manually check 3 cases: none, DND On, Other Focus
		
		Manual: Switch to AirPods (N/A, Happy, Already Selected)
		Manual: Is Mic In Use
		
		Manual: List of Hotspot (Maybe used to identify your hotpot key, mind the Unicode apostrophe, test no hotspot available)
		Manual: Join Hotspot (Not Joined, Already Joined, Not Found)
		Manual: Join WIFI (Not Joined, Already Joined, Not Found)
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	if caseIndex is 1 then
		sut's showWidgets()
		
	else if caseIndex is 2 then
		sut's setDoNotDisturbOn()
		
	else if caseIndex is 3 then
		sut's setDoNotDisturbOn()
		
	else if caseIndex is 4 then
		sut's setDoNotDisturbOff()
		
	else if caseIndex is 5 then
		logger's infof("DND Status: {}", sut's getDNDStatus())
		
	else if caseIndex is 6 then
		set switchResult to sut's switchAudioOutput("AirPods Pro")
		logger's infof("Switch Result: {}", switchResult)
		
	else if caseIndex is 7 then
		logger's infof("Handler Result: {}", sut's isMicInUse())
		
	else if caseIndex is 8 then
		set hotspots to getListOfAvailableHotspot()
		if the number of items in hotspots is 0 then
			logger's info("No hotspot found")
		else
			repeat with nextHotspot in hotspots
				logger's info(nextHotspot)
			end repeat
		end if
		
	else if caseIndex is 9 then
		(* Toggle below cases. *)
		sut's joinHotspot("iPhone")
		-- joinHotspot("Galaxy")
		
	else if caseIndex is 10 then
		(* Toggle below cases. *)
		sut's joinHotspot("Care")
		-- joinHotspot("Careless")
		
	end if
	
	log decorators of sut
	
	spot's finish()
	logger's finish()
end spotCheck


on new()	
	script ControlCenterInstance
		property decorators : []
		
		(* Accomplished by clicking on the time in the menu bar items *)
		on showWidgets()
			tell application "System Events" to tell process "ControlCenter"
				try
					click (first menu bar item of first menu bar whose description is "Clock")
				end try
			end tell
		end showWidgets
		
		
		-- Private Codes below =======================================================
		on _activateControlCenter()
			tell application "System Events" to tell process "ControlCenter"
				try
					click (first menu bar item of menu bar 1 whose value of attribute "AXIdentifier" is "com.apple.menuextra.controlcenter")
				end try
			end tell
		end _activateControlCenter
		
	end script
	
	decoratorFocus's decorate(result)
	decoratorSound's decorate(result)
	decoratorNetwork's decorate(result)
end new
