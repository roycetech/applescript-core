global std, retryLib, kb, unic, textUtil

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
		Manual: List of Hotspot (Maybe used to identify your hotpot key, mind the unicode apostrophe, test no hotspot available)
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
		logger's infof("DND Status: {}", getDNDStatus())
		
	else if caseIndex is 6 then
		set switchResult to switchAudioOutput("AirPods Pro")
		logger's infof("Switch Result: {}", switchResult)
		
	else if caseIndex is 7 then
		logger's infof("Handler Result: {}", isMicInUse())
		
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
		joinHotspot("iPhone")
		-- joinHotspot("Galaxy")
		
	else if caseIndex is 10 then
		(* Toggle below cases. *)
		joinHotspot("Care")
		-- joinHotspot("Careless")
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck

(*
	@hotspotKey - the hotspot identifier to join, e.g. "Joe's iPhone". (Use the correct unicode apostrophe)
*)
on joinHotspot(hotspotKey)
	joinNetwork(hotspotKey)
end joinHotspot

(* 
	Joins the first network matching the given key.
	
	@hotspotKey - the hotspot identifier to join, e.g. "Joe's iPhone". (Use the correct unicode apostrophe)
*)
on joinNetwork(networkKey)
	_activateControlCenter()
	_activateWifiPane()
	
	set retry to retryLib's new()
	
	logger's infof("Hotspot: {}", networkKey)
	tell application "System Events" to tell process "ControlCenter"
		script HotspotClicker
			tell application "System Events" to tell process "ControlCenter" to tell window "Control Center"
				set matchedConnections to checkbox 1 of scroll area 1 of group 1 whose value of attribute "AXIdentifier" contains networkKey
				if the number of items in matchedConnections is 0 then return "not found"
				
				set currentState to value of first item in matchedConnections
				logger's debugf("Current State: {}", currentState)
				if currentState is 1 then
					return "already connected"
				end if
				
				click (first checkbox of scroll area 1 of group 1 whose value of attribute "AXIdentifier" contains networkKey)
				true
			end tell
		end script
		set clickResult to exec of retry on result for 3 by 1
		
		if clickResult is "not found" then
			error "The given hotspot key: " & networkKey & " was not found"
			
		else if clickResult is "already connected" then
			kb's pressKey("esc")
			logger's warn("You are already connected ")
			
		else if clickResult is missing value then
			kb's pressKey("esc")
			logger's fatal("Could not click your hotspot " & networkKey & ", make sure it is available")
			
		else
			kb's pressKey("esc")
			
		end if
	end tell
end joinNetwork


(* 
	Joins the first hotspot matching the given key.
	
	@hotspotKey - the hotspot identifier to join, e.g. "Joe's iPhone". (Use the correct unicode apostrophe)
*)
on joinWifi(sidKey)
	joinNetwork(sidKey)
end joinWifi


on getListOfAvailableHotspot()
	set retry to retryLib's new()
	set listOfHotspot to {}
	
	_activateControlCenter()
	_activateWifiPane()
	
	set startOffset to the (length of "wifi-network-") + 1
	set headingCount to 0
	
	tell application "System Events" to tell process "ControlCenter"
		repeat with nextUIElement in UI elements of scroll area 1 of group 1 of front window
			if value of attribute "AXRole" of the nextUIElement is "AXHeading" then set headingCount to headingCount + 1
			if headingCount is greater than 1 then exit repeat
			
			if value of attribute "AXRole" of the nextUIElement is "AXCheckBox" then
				set axIdentifier to value of attribute "AXIdentifier" of the nextUIElement
				set hotspotName to the text startOffset thru -1 in axIdentifier
				set end of listOfHotspot to hotspotName
			end if
		end repeat
	end tell
	
	kb's pressKey("esc")
	
	listOfHotspot
end getListOfAvailableHotspot


on isMicInUse()
	tell application "System Events" to tell process "ControlCenter"
		exists (first menu bar item of menu bar 1 whose description is "Microphone is in use")
	end tell
end isMicInUse


(* @returns true if the output is found. *)
on switchAudioOutput(outputName)
	_activateControlCenter()
	_activateSoundPane()
	
	set clickResult to false
	tell application "System Events" to tell process "ControlCenter"
		set targetCheckbox to first checkbox of scroll area 1 of group 1 of first window whose value of attribute "AXIdentifier" ends with outputName
		set currentState to value of targetCheckbox
		logger's debugf("currentState: {}", currentState)
		
		if currentState is 0 then
			try
				click targetCheckbox
				set clickResult to true
			end try
		end if
	end tell
	
	kb's pressKey("esc")
	clickResult
end switchAudioOutput

(* Accomplished by clicking on the time in the menu bar items *)
on showWidgets()
	tell application "System Events" to tell process "ControlCenter"
		try
			click (first menu bar item of first menu bar whose description is "Clock")
		end try
	end tell
end showWidgets


on setDoNotDisturbOn()
	_setDoNotDisturb(true)
	
end setDoNotDisturbOn

on setDoNotDisturbOff()
	_setDoNotDisturb(false)
end setDoNotDisturbOff

(* 
	@Known Issues:
		
*)
on getDNDStatus()
	set currentState to 0
	_activateControlCenter()
	tell application "System Events" to tell process "ControlCenter"
		
		set currentState to the value of first checkbox of group 1 of front window whose value of attribute "AXIdentifier" is "controlcenter-focus-modes"
	end tell
	
	if currentState is 1 then
		_activateFocusPane()
		
		tell application "System Events" to tell process "ControlCenter" to tell front window to tell group 1
			set currentState to value of first checkbox whose value of attribute "AXIdentifier" is "focus-mode-activity-com.apple.donotdisturb.mode.default"
		end tell
	end if
	
	-- if exists (first checkbox of front window whose title is "Do Not Disturb") then set currentState to 1
	kb's pressKey("esc")
	currentState
end getDNDStatus


-- Private Codes below =======================================================
on _activateControlCenter()
	tell application "System Events" to tell process "ControlCenter"
		try
			click (first menu bar item of menu bar 1 whose description is "Control Center")
		on error
			click (first menu bar item of menu bar 1 whose description is "Microphone is in use")
		end try
	end tell
end _activateControlCenter

(*
	While the Control Center is already visible, it moves to the Focus pane by triggering the "Show Details" of the Focus check box
*)
on _activateFocusPane()
	tell application "System Events" to tell process "ControlCenter"
		perform action 2 of (first checkbox of group 1 of front window whose value of attribute "AXIdentifier" is "controlcenter-focus-modes")
	end tell
	
	set retry to retryLib's new()
	script FocusPanelWaiter
		tell application "System Events" to tell process "ControlCenter" to tell front window to tell group 1
			if exists (first checkbox whose value of attribute "AXIdentifier" is "focus-mode-activity-com.apple.donotdisturb.mode.default") then return true
		end tell
	end script
	exec of retry on result for 10 by 0.2
end _activateFocusPane


on _activateSoundPane()
	tell application "System Events" to tell process "ControlCenter"
		perform first action of static text "Sound" of group 1 of window "Control Center"
	end tell
	
	set retry to retryLib's new()
	script SoundPanelWaiter
		tell application "System Events" to tell process "ControlCenter" to tell front window to tell group 1
			if exists (first checkbox of scroll area 1 of group 1 of first window whose value of attribute "AXIdentifier" ends with "MacBook Pro Speakers") then return true
		end tell
	end script
	exec of retry on result for 10 by 0.2
end _activateSoundPane

(*
	@newValue boolean true to activate DND, false to deactivate.
*)
on _setDoNotDisturb(newValue)
	_activateControlCenter()
	
	tell application "System Events" to tell process "ControlCenter"
		set targetContainer to group 1 of front window
		tell targetContainer
			set currentState to 1
			set currentFocusId to value of attribute "AXIdentifier" of second checkbox
			logger's debugf("currentFocusId: {}", currentFocusId)
			
			try
				set currentState to value of first checkbox whose value of attribute "AXIdentifier" is "focus-mode-activity-com.apple.donotdisturb.mode.default"
			on error
				set currentState to value of second checkbox -- huh?!
			end try
			
			logger's debugf("_setDoNotDisturb currentState: {}", currentState)
			if currentState is 0 and newValue or currentState is 1 and newValue is false then
				perform action 2 of second checkbox
				
				set retry to retryLib's new()
				script SubWindowWaiter
					tell application "System Events" to tell process "ControlCenter" to tell front window to tell group 1
						if exists (first checkbox whose value of attribute "AXIdentifier" is "focus-mode-activity-com.apple.donotdisturb.mode.default") then return true
					end tell
				end script
				exec of retry on result for 10 by 0.2
				
				click (first checkbox whose value of attribute "AXIdentifier" is "focus-mode-activity-com.apple.donotdisturb.mode.default")
				kb's pressKey("esc")
				
			else
				kb's pressKey("esc")
			end if
		end tell
	end tell
end _setDoNotDisturb


(*
	While the Control Center is already visible, it moves to the Wi-Fi pane by triggering the "Show Details" of the Wi-Fi check box
*)
on _activateWifiPane()
	set retry to retryLib's new()
	tell application "System Events" to tell process "ControlCenter"
		perform action 2 of (first checkbox of group 1 of window "Control Center" whose value of attribute "AXIdentifier" is "controlcenter-wifi")
	end tell
	
	script WiFiAreaWaiter
		tell application "System Events" to tell process "ControlCenter"
			if exists (first static text of group 1 of front window whose name starts with "Wi" and name ends with "Fi") then return true			
		end tell
	end script
	set scrollWaitResult to exec of retry on result for 20 by 0.1
	if scrollWaitResult is missing value then
		error "Scroll Area with WIFI list did not appear within the allotted time"
	end if
end _activateWifiPane


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set unic to std's import("unicodes")
	set logger to std's import("logger")'s new("control-center")
	set retryLib to std's import("retry")
	set kb to std's import("keyboard")'s new()
	set textUtil to std's import("string")
end init
