global std, retry, kb, unic, textUtil

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
		
		Switch to AirPods
		Is Mic In Use
		Manual: List of Hotspot (Maybe used to identify your hotpot key, mind the unicode apostrophe)
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
	
	if caseIndex is 1 then
		showWidgets()
		
	else if caseIndex is 2 then
		setDoNotDisturbOn()
		
	else if caseIndex is 3 then
		setDoNotDisturbOn()
		
	else if caseIndex is 4 then
		setDoNotDisturbOff()
		
	else if caseIndex is 5 then
		log getDNDStatus()
		
	else if caseIndex is 6 then
		log switchAudioOutput("AirPods")
		
	else if caseIndex is 7 then
		log isMicInUse()
		
	else if caseIndex is 8 then
		set hotspots to getListOfAvailableHotspot()
		repeat with nextHotspot in hotspots
			logger's info(nextHotspot)
		end repeat
		
	else if caseIndex is 9 then
		(* Toggle below cases. *)
		joinHotspot("iPhone")
		-- joinHotspot("Galaxy")
		
	else if caseIndex is 10 then
		(* Toggle below cases. *)
		-- joinHotspot("Care")
		joinHotspot("Careless")
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(* 
	Joins the first hotspot matching the given key.
	
	@hotspotKey - the hotspot identifier to join, e.g. "Joe's iPhone". (Use the correct unicode apostrophe)
*)
on joinHotspot(hotspotKey)
	logger's infof("Hotspot: {}", hotspotKey)
	script MenuClicker
		tell application "System Events" to tell process "ControlCenter"
			click (first menu bar item of menu bar 1 whose name contains "Control Center")
			true
		end tell
	end script
	exec of retry on result for 3 by 1
	
	_triggerWifi()
	
	tell application "System Events" to tell process "ControlCenter"
		script HotspotClicker
			tell application "System Events" to tell process "ControlCenter" to tell window "Control Center"
				set matchedConnections to checkboxes of scroll area 1 whose name contains hotspotKey
				if the number of items in matchedConnections is 0 then return "not found"
				
				set currentState to value of first item in matchedConnections
				logger's debugf("Current State: {}", currentState)
				if currentState is 1 then
					return "already connected"
				end if
				
				click (first checkbox of scroll area 1 whose name contains hotspotKey)
				true
			end tell
		end script
		set clickResult to exec of retry on result for 3 by 1
		
		if clickResult is "not found" then
			error "The given hotspot key: " & hotspotKey & " was not found"
			
		else if clickResult is "already connected" then
			kb's pressKey("esc")
			logger's warn("You are already connected ")
			
		else if clickResult is missing value then
			kb's pressKey("esc")
			logger's fatal("Could not click your hotspot " & hotspotKey & ", make sure it is available")
			
		else
			kb's pressKey("esc")
			
		end if
	end tell
end joinHotspot


(* 
	Joins the first hotspot matching the given key.
	
	@hotspotKey - the hotspot identifier to join, e.g. "Joe's iPhone". (Use the correct unicode apostrophe)
*)
on joinWifi(sidKey)
	logger's infof("Sid Key: {}", sidKey)
	script MenuClicker
		tell application "System Events" to tell process "ControlCenter"
			click (first menu bar item of menu bar 1 whose name contains "Control Center")
			true
		end tell
	end script
	exec of retry on result for 3 by 1
	
	_triggerWifi()
	
	tell application "System Events" to tell process "ControlCenter"
		script HotspotClicker
			tell application "System Events" to tell process "ControlCenter" to tell window "Control Center"
				set matchedConnections to checkboxes of scroll area 1 whose name contains sidKey
				if the number of items in matchedConnections is 0 then return "not found"
				
				set currentState to value of first item in matchedConnections
				logger's debugf("Current State: {}", currentState)
				if currentState is 1 then
					return "already connected"
				end if
				
				click (first checkbox of scroll area 1 whose name contains sidKey)
				true
			end tell
		end script
		set clickResult to exec of retry on result for 3 by 1
		
		if clickResult is "not found" then
			error "Could not find the WIFI SID key: " & sidKey
			
		else if clickResult is "already connected" then
			kb's pressKey("esc")
			logger's warn("You are already connected ")
			
		else if clickResult is missing value then
			kb's pressKey("esc")
			logger's fatal("Could not click your WIFI SID key " & sidKey & ", make sure it is available")
			
		end if
	end tell
end joinWifi


on getListOfAvailableHotspot()
	set listOfHotspot to {}
	script MenuClicker
		tell application "System Events" to tell process "ControlCenter"
			click (first menu bar item of menu bar 1 whose name contains "Control Center")
			true
		end tell
	end script
	exec of retry on result for 3 by 1
	
	_triggerWifi()
	
	tell application "System Events" to tell process "ControlCenter"
		repeat with nextCheckbox in (checkboxes of scroll area 1 of window "Control Center" whose name contains "pot")
			set nameTokens to textUtil's split(name of nextCheckbox, ",")
			set end of listOfHotspot to the first item of nameTokens
		end repeat
	end tell
	
	kb's pressKey("esc")
	
	listOfHotspot
end getListOfAvailableHotspot


(*
	See WIFI Sub Window
*)
on _triggerWifi()
	tell application "System Events" to tell process "ControlCenter"
		perform action 2 of checkbox (unic's WIFI) of window "Control Center"
	end tell
	
	script ScrollAreaWaiter
		tell application "System Events" to tell process "ControlCenter"
			if exists (scroll area 1 of window "Control Center") then return true
		end tell
	end script
	set scrollWaitResult to exec of retry on result for 20 by 0.1
	if scrollWaitResult is missing value then
		error "Scroll Area with WIFI list did not appear within the alotted time"
	end if
end _triggerWifi


on isMicInUse()
	tell application "System Events" to tell process "ControlCenter"
		try
			return (name of (first menu bar item of menu bar 1 whose name starts with "Control Center") as text) contains "Microphone in use"
		end try
	end tell
	
	false
end isMicInUse


(* @returns true if the output is found. *)
on switchAudioOutput(outputName)
	tell application "System Events" to tell process "ControlCenter"
		click (first menu bar item of menu bar 1 whose name starts with "Control Center")
		perform first action of static text "Sound" of window "Control Center"
		delay 1
		set clickResult to false
		try
			click (first checkbox of scroll area 1 of first window whose title contains outputName)
			set clickResult to true
		end try
	end tell
	kb's pressKey("esc")
	clickResult
end switchAudioOutput

(* Accomplished by clicking on the time in the menu bar items *)
on showWidgets()
	tell application "System Events" to tell process "ControlCenter"
		try
			click menu bar item "Clock" of first menu bar
		end try
	end tell
end showWidgets


on setDoNotDisturbOn()
	_setDoNotDisturb(true)
	
end setDoNotDisturbOn

on setDoNotDisturbOff()
	_setDoNotDisturb(false)
end setDoNotDisturbOff


on getDNDStatus()
	set currentState to 0
	tell application "System Events" to tell process "ControlCenter"
		click (first menu bar item of menu bar 1 whose name starts with "Control Center")
		if exists (first checkbox of front window whose title is "Do Not Disturb") then set currentState to 1
	end tell
	kb's pressKey("esc")
	currentState
end getDNDStatus


-- Private Codes below =======================================================
on _setDoNotDisturb(newValue as boolean)
	tell application "System Events" to tell process "ControlCenter"
		click (first menu bar item of menu bar 1 whose name starts with "Control Center")
		
		set currentState to 1
		set currentFocusName to name of second checkbox of front window as text
		try
			set currentState to value of first checkbox of front window whose title is "Focus"
		on error
			set currentState to value of second checkbox of front window
		end try
		
		-- logger's debugf("currentState: {}", currentState)
		
		if name of second checkbox of front window is not "Focus" then
			perform action 2 of second checkbox of front window
			
			set retry to retryLib's new()
			script SubWindowWaiter
				tell application "System Events" to tell process "ControlCenter"
					if exists (first checkbox of front window whose title is "Do Not Disturb") then return true
				end tell
			end script
			exec of retry on result for 10 by 0.2
			
			if newValue is true then
				click (first checkbox of front window whose title is "Do Not Disturb")
			else
				click (first checkbox of front window whose title is currentFocusName)
			end if
			kb's pressKey("esc")
			
		else if currentState is 0 and newValue then
			click (first checkbox of front window whose title is "Focus")
			kb's pressKey("esc")
			
		else if currentState is 1 and newValue is false then
			click (first checkbox of front window whose title is "Do Not Disturb")
			kb's pressKey("esc")
		else
			kb's pressKey("esc")
		end if
	end tell
end _setDoNotDisturb


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set unic to std's import("unicodes")
	set logger to std's import("logger")'s new("control-center")
	set retry to std's import("retry")'s new()
	set kb to std's import("keyboard")'s new()
	set textUtil to std's import("string")
end init
