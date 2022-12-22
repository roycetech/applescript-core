global std, retryLib

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
	")
	
	set spotLib to std's import("spot")'s new()
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
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


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
		
		key code 53 -- escape
	end tell
	clickResult
end switchAudioOutput

(* Accomplished by clicking on the time in the menu bar items *)
to showWidgets()
	tell application "System Events" to tell process "ControlCenter"
		try
			click menu bar item "Clock" of first menu bar
		end try
	end tell
end showWidgets


to setDoNotDisturbOn()
	_setDoNotDisturb(true)
	
end setDoNotDisturbOn

to setDoNotDisturbOff()
	_setDoNotDisturb(false)
end setDoNotDisturbOff


on getDNDStatus()
	set currentState to 0
	tell application "System Events" to tell process "ControlCenter"
		click (first menu bar item of menu bar 1 whose name starts with "Control Center")
		if exists (first checkbox of front window whose title is "Do Not Disturb") then set currentState to 1
	end tell
	tell application "System Events" to key code 53 -- Escape
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
			tell application "System Events" to key code 53 -- Escape
			
		else if currentState is 0 and newValue then
			click (first checkbox of front window whose title is "Focus")
			tell application "System Events" to key code 53 -- Escape
			
		else if currentState is 1 and newValue is false then
			click (first checkbox of front window whose title is "Do Not Disturb")
			tell application "System Events" to key code 53 -- Escape
		else
			tell application "System Events" to key code 53 -- Escape
		end if
	end tell
end _setDoNotDisturb


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("control-center")
	set retryLib to std's import("retry")
end init
