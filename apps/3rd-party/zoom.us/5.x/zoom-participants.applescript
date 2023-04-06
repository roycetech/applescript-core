global std, usr, retry, regex

(*
	Update the following quite obvious if you read through the template code.:
	spotCheck()
		thisCaseId
		base library instantiation

	init()
		logger constructor parameter inside init handler

	decorate()
		instance name
		handler name

*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "#zoom-participants-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Manual: Is Participants View Visible
		Manual: Show Participants View (Absent, Already Present)
		Manual: Hide Participants View (Absent, Already Present)
		Manual: Get Participants
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to std's import("zoom")'s new()
	try
		sut's isParticipantSidebarVisible
	on error
		set sut to decorate(sut)
	end try
	
	if caseIndex is 1 then
		logger's infof("isParticipantSidebarVisible: {}", sut's isParticipantSidebarVisible())
		
	else if caseIndex is 2 then
		sut's showParticipants()
		
	else if caseIndex is 3 then
		sut's hideParticipants()
		
	else if caseIndex is 4 then
		set participants to sut's getParticipants()
		if participants is missing value or the (count of participants) is 0 then
			logger's warn("No participants found")
		else
			repeat with nextParticipant in participants
				logger's infof("Next Participant: {}", nextParticipant)
			end repeat
		end if
		
		logger's infof("Host: {}", _detectedHost of sut)
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on newSpotBase()
	script SpotBaseInstance
		property template : missing value
	end script
end newSpotBase


(*  *)
on decorate(mainScript)
	
	(* Use the same name as the parent because this decorator is only meant to organize the handlers. *)
	script ZoomInstance
		property parent : mainScript
		property _detectedHost : missing value
		property _detectedCoHost : missing value -- TODO
		
		(*
			@returns list of meeting participants.
		*)
		on getParticipants()
			set participants to {}
			
			if not running of application "zoom.us" then return participants
			
			set origParticipantVisibility to isParticipantSidebarVisible()
			showParticipants()
			
			tell application "System Events" to tell process "zoom.us"
				repeat with nextRow in rows of outline 1 of scroll area 1 of window "Zoom Meeting"
					set nextParticipant to value of static text 1 of UI element 1 of nextRow as text
					-- logger's debugf("nextParticipant: {}", nextParticipant)
					
					set regexMatch to regex's firstMatchInString(".*(?=\\s\\()", nextParticipant)
					if regexMatch is missing value then
						set nextParticipantName to nextParticipant
					else
						set nextParticipantName to regexMatch
					end if
					
					if nextParticipant contains "(Host, me)" then
						set _detectedHost to "me"
					else if nextParticipant contains "Host" then
						set _detectedHost to "me"
					end if
					
					set end of participants to nextParticipantName
				end repeat
			end tell
			
			if origParticipantVisibility is false then hideParticipants()
			participants
		end getParticipants
		
		
		on isParticipantSidebarVisible()
			if not running of application "zoom.us" then return false
			
			tell application "System Events" to tell process "zoom.us"
				try
					return exists (menu item "Close Manage Participants" of menu 1 of menu bar item "View" of menu bar 1)
				end try
			end tell
			false
		end isParticipantSidebarVisible
		
		
		on showParticipants()
			if not running of application "zoom.us" then return
			
			tell application "System Events" to tell process "zoom.us"
				try
					click menu item "Show Manage Participants" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
			
			script WaitMenu
				tell application "System Events" to tell process "zoom.us"
					if exists (menu item "Close Manage Participants" of menu 1 of menu bar item "View" of menu bar 1) then return true
				end tell
			end script
			exec of retry on result for 3
		end showParticipants
		
		
		on hideParticipants()
			if not running of application "zoom.us" then return
			
			tell application "System Events" to tell process "zoom.us"
				try
					click menu item "Close Manage Participants" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
			
			script WaitMenu
				tell application "System Events" to tell process "zoom.us"
					if not (exists (menu item "Close Manage Participants" of menu 1 of menu bar item "View" of menu bar 1)) then return true
				end tell
			end script
			exec of retry on result for 3
		end hideParticipants
	end script
end decorate


-- Private Codes below =======================================================



(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set usr to std's import("user")'s new()
	set logger to std's import("logger")'s new("zoom-participants")
	set retry to std's import("retry")'s new()
	set regex to std's import("regex")
end init
