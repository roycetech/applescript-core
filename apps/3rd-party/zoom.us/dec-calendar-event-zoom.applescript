global std, regex

(*
	@Testing Note:
		Manually disable override in the config-lib-factory to test this decorator without first deploying to the Script Library folder.
	
	@Testing Cases:
		Pick a date in the calendar with a zoom event
		Pick a date in the calendar with a non-zoom event
		
	
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "dec-calendar-event-zoom-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Manual: Extract Meeting ID
		Extract Meeting Password
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	activate application "Calendar"
	set calendar to std's import("calendar")'s new()
	set decoratedEvent to std's import("calendar-event")'s new()
	if name of decoratedEvent is not "CalendarEventZoomLibrary" then
		logger's info("Decorating...")
		set decoratedEvent to decorate(decoratedEvent)
	else
		error "Already decorated"
	end if
	logger's debugf("Name of calendar event: {}", name of decoratedEvent)
	
	if caseIndex is 1 then
		-- set selectedEvent to calendar's getSelectedEvent()
		set selectedEvent to _spotGetSelectedEvent(decoratedEvent)
		if selectedEvent is missing value then error "Selected Event is missing value"
		logger's logObj("selected event", selectedEvent)
		logger's infof("Meeting ID: {}", selectedEvent's meetingId)
		logger's infof("Meeting Password: {}", selectedEvent's meetingPassword)
		
	else if caseIndex is 2 then
		
	else if caseIndex is 3 then
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*
	Copied from calendar.applescript so that we can spot check this decorator.
*)
on _spotGetSelectedEvent(decoratedEvent)
	tell application "System Events" to tell process "Calendar"
		repeat with nextDay in lists of UI element 1 of group 1 of splitter group 1 of window "Calendar"
			try
				set selectedEvent to (first static text of nextDay whose focused is true)
				return decoratedEvent's new(selectedEvent)
			end try -- When none is selected on the iterated dow.
		end repeat
	end tell
	
	missing value
end _spotGetSelectedEvent



(*  *)
on decorate(mainScript)
	script CalendarEventZoomLibrary
		property parent : mainScript
		
		on extractMeetingId(meetingStaticText)
			set isSpot to name of current application is "Script Editor"
			if isSpot is true then
				try
					set meetingDescription to |description| of meetingStaticText
				on error
					tell application "System Events" to tell process "Calendar"
						set meetingDescription to description of meetingStaticText
					end tell
				end try
			else
				tell application "System Events" to tell process "Calendar"
					set meetingDescription to description of meetingStaticText
				end tell
			end if
			
			regex's firstMatchInString("(?<=zoom\\.us\\/j\\/)\\d+", meetingDescription)
		end extractMeetingId
		
		on extractMeetingPassword(meetingStaticText)
			set isSpot to name of current application is "Script Editor"
			if isSpot is true then
				try
					set meetingDescription to |description| of meetingStaticText
				on error
					tell application "System Events" to tell process "Calendar"
						set meetingDescription to description of meetingStaticText
					end tell
				end try
			else
				tell application "System Events" to tell process "Calendar"
					set meetingDescription to description of meetingStaticText
				end tell
			end if
			
			regex's firstMatchInString("(?<=pwd=)\\w+", meetingDescription)
		end extractMeetingPassword
	end script
end decorate


-- Private Codes below =======================================================


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("dec-calendar-event-zoom")
	set regex to std's import("regex")
end init
