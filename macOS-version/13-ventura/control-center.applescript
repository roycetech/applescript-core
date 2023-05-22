global std, kb, unic

(* 
	NOTE: This script requires accessibility access, grant when prompted.
	
	Depends on the position of the focus checkbox to be the 2nd one. 

*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "control-center-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
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
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
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
	set decoratorNetwork to std's import("control-center_network")
	set decoratorSound to std's import("control-center_sound")
	set decoratorFocus to std's import("control-center_focus")
	
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


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set unic to std's import("unicodes")
	set logger to std's import("logger")'s new("control-center")
end init
