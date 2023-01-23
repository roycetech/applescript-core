global std, config, regex, textUtil, retry, sb, calendarEvent, counter, plutil, dt, kb
global decoratorCalView, calProcess

use script "Core Text Utilities"
use scripting additions

(*
	@Plists
		counter
			calendar.getMeetingsAtThisTime - for other scripts to limit this slow, user-interrupting check to once perday.

	When parsing meetings for the day, list of records will be returned. In 
	parallel, a list ACTIVE_MEETINGs will contain the references to the UI.
	
	TODO: 
		Broken when using 24H time format.
		- Organizer still unreliably derived as of March 2, 2022
		- Re-implement using native scripting
		
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "calendar-next-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	(* Manual Visual Verification. *)
	set cases to listUtil's splitByLine("
		Go to Today
		Go to date: Jan 7, 2021
		(Not Covered Here) Current Meeting/s - Non Cached
		Current Meeting/s
		Next Meeting
		
		Switch View - extension
		Manual: Selected Event
		Clear Cache on First Run of the Day
	")
	
	set spotLib to std's import("spot")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	set IS_TEST of sut to true
	-- set IS_TEST of sut to false -- when testing in real time.
	
	if caseIndex is 1 then
		if running of application "Calendar" is false then activate application "Calendar"
		sut's gotoToday()
		
	else if caseIndex is 2 then
		sut's gotoDate("2021/01/07")
		
	else if caseIndex is 3 then
		-- sut's clearCache()
		tell sut
			set its IS_TEST to true
			set its TEST_DATETIME to date "Tuesday, June 14, 2022 at 8:00:00 AM"
		end tell
		
		set meetingsAtThisTime to sut's getMeetingsAtThisTime()
		log ("Meetings at this time: " & (count of meetingsAtThisTime))
		repeat with nextActive in meetingsAtThisTime
			log nextActive
		end repeat
		
	else if caseIndex is 4 then
		set meetingsAtThisTime to sut's getMeetingsAtThisTime()
		logger's infof("Count of Meetings Now: {}", count of meetingsAtThisTime)
		repeat with nextActive in meetingsAtThisTime
			logger's infof("Next Active Meeting: {}", nextActive)
		end repeat
		
	else if caseIndex is 5 then
		set upcomingMeeting to sut's getNextMeetingToday()
		if upcomingMeeting is missing value then
			log "No more meetings today, is that right?"
		else
			log "Upcoming meeting found:"
			log upcomingMeeting
		end if
		
	else if caseIndex is 6 then
		sut's switchToYearView()
		
	else if caseIndex is 7 then
		(* NOTE: Sometimes the selected event is still not detected :( *)
		set selectedEvent to sut's getSelectedEvent()
		if selectedEvent is missing value then error "Select an event in week-view to demonstrate this feature. Other view types are not yet implemented."
		
		logger's infof("Selected Event JSON: {}", selectedEvent's toJsonString())
		
	else if caseIndex is 8 then
		
		set meetingsAtThisTime to sut's getMeetingsAtThisTime()
		log (count of meetingsAtThisTime)
		repeat with nextActive in meetingsAtThisTime
			log (nextActive)
		end repeat
		
	end if
	
	set IS_TEST of sut to false
	activate
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	script CalendarInstance
		property IS_TEST : false
		property TEST_DATETIME : missing value
		property appAlreadyRunning : false
		
		(* WARNING: Manually modify for testing *)
		on getCurrentDate()
			-- logger's debugf("IS_TEST: {}", IS_TEST)
			if IS_TEST is false then return the (current date)
			
			if TEST_DATETIME is missing value then
				return date "Wednesday, March 2, 2022 at 1:15:00 PM"
			end if
			
			TEST_DATETIME
		end getCurrentDate
		
		on gotoToday()
			if running of application "Calendar" is false then return
			
			tell application "System Events" to tell process "Calendar"
				if (count of windows) is 0 then return
				
				click button "Today" of group 1 of group 1 of splitter group 1 of window "Calendar"
			end tell
		end gotoToday
		
		(* @dateString date in the format yyyy/MM/dd *)
		on gotoDate(dateString)
			if running of application "Calendar" is false then return
			
			if not regex's matchesInString("\\d{4}/\\d{2}/\\d{2}", dateString) then return
			
			set {yyyy, mm, dd} to textUtil's split(dateString, "/")
			set parsableFormat to format {"{}/{}/{}", {mm, dd, yyyy}}
			set targetDate to date parsableFormat
			
			tell application "Calendar" to view calendar at targetDate
		end gotoDate
		
		(* @returns record (not script object). *)
		on getNextMeetingToday()
			set currentDate to getCurrentDate()
			-- logger's debugf("currentDate: {}", currentDate)
			set currentWeekDay to weekday of currentDate as text
			set meetingsToday to getMeetingsOfTheDay(currentWeekDay)
			repeat with nextMeeting in meetingsToday
				if nextMeeting's actioned and _asDate(nextMeeting's startTime) is greater than currentDate then
					return nextMeeting
				end if
			end repeat
			missing value
		end getNextMeetingToday
		
		
		(* 
			TODO: For other view types. 
			@returns calendar-event instance.
		*)
		on getSelectedEvent()
			set currentViewType to getViewType()
			logger's debugf("currentViewType: {}", currentViewType)
			logger's debugf("name of event lib: {}", name of calendarEvent)
			
			if currentViewType is "Week" then
				tell application "System Events" to tell process "Calendar"
					repeat with nextDay in lists of UI element 1 of group 1 of splitter group 1 of window "Calendar"
						try
							set selectedEvent to (first static text of nextDay whose focused is true)
							return calendarEvent's new(selectedEvent)
							-- on error the errorMessage number the errorNumber
							-- 	logger's debug(errorMessage) -- Temp log, comment out for prod.	
						end try -- When none is selected on the iterated dow.
					end repeat
				end tell
			end if
			
			missing value
		end getSelectedEvent
		
		
		on getMeetingsOfTheDay(dayOfTheWeek)
			initCalendarApp()
			activate application "Calendar"
			kb's pressKey("esc")
			
			set origView to getViewType()
			switchToDayView()
			set targetYyyyMMdd to dt's formatYyyyMmDd(getCurrentDate(), "/")
			gotoDate(targetYyyyMMdd) -- slash separated
			set targetMmDdYyyy to dt's formatMmDdYyyy(getCurrentDate(), "/")
			set referenceDate of calendarEvent to targetMmDdYyyy
			
			set meetingDetails to {}
			
			-- Select the first event	
			activate application "Calendar"
			repeat 10 times
				kb's pressKey("up")
			end repeat
			
			tell application "System Events" to tell application process "Calendar"
				repeat with nextST in static texts of list 1 of group 1 of splitter group 1 of window "Calendar"
					set meetingDetail to calendarEvent's new(nextST)
					my _moveToNextEventViaUI()
					
					set end of meetingDetails to meetingDetail
				end repeat
			end tell
			
			switchToViewByTitle(origView)
			meetingDetails
		end getMeetingsOfTheDay
		
		
		(* 
			Only the action-ed meeting events are included.
			@returns list of record (not script object). I'm curious why this 
			runs fine despite outside of the instance object. 
		*)
		on getMeetingsAtThisTime()
			set theNow to getCurrentDate()
			-- logger's debugf("currentDate: {}", theNow)
			set currentWeekDay to weekday of theNow as text
			
			set theRetval to {}
			set meetingsToday to getMeetingsOfTheDay(currentWeekDay)
			
			set activeMeetingIdx to 0
			repeat with idx from (count meetingsToday) to 1 by -1
				set meetingDetail to item idx of meetingsToday
				if meetingDetail's startTime is not missing value then
					set startTriggerTime to _asDate(meetingDetail's startTime) - 2 * minutes
					set isActive to theNow is greater than or equal to startTriggerTime and theNow is less than _asDate(meetingDetail's endTime) - 2 * minutes
					set active of meetingDetail to isActive
					
					if isActive then set end of theRetval to meetingDetail
				end if
			end repeat
			
			theRetval
		end getMeetingsAtThisTime
	end script
	
	decoratorCalView's decorate(CalendarInstance)
	std's applyMappedOverride(result)
end new


-- Refactor below
on initCalendarApp()
	
	if running of application "Calendar" then
		tell application "System Events" to tell process "Calendar"
			if (count of windows) is 1 then
				set my appAlreadyRunning to true
				return
			end if
		end tell
	end if
	
	calProcess's terminate()
	
	_launchAndWaitCalendarApp()
	logger's debug("App launched")
end initCalendarApp

on _launchAndWaitCalendarApp()
	activate application "Calendar"
	script WindowWaiter
		tell application "System Events" to tell process "Calendar"
			if (count of windows) is greater than 0 then return true
		end tell
	end script
	exec of retry on result for 3
end _launchAndWaitCalendarApp


-- Private Codes below =======================================================
on _moveToNextEventViaUI()
	-- This is so we don't trigger the popup. Using click or select trigger's popup but pressing up/down arrows don't.
	activate application "Calendar"
	kb's pressKey("down")
end _moveToNextEventViaUI


on computeDurationMinutes(timeStart, timeEnd)
	set dateTimeStart to _timeToDateTime(timeStart)
	set dateTimeEnd to _timeToDateTime(timeEnd)
	
	(dateTimeEnd - dateTimeStart) / minutes
end computeDurationMinutes


on _timeToDateTime(theTime as text)
	set theDate to date string of getCurrentDate()
	date (theDate & " " & theTime)
end _timeToDateTime

(* @dateParam change to date when fetched from json, otherwise return as is. *)
on _asDate(dateParam)
	if class of dateParam is date then return dateParam
	if dateParam is missing value then return missing value
	
	date dateParam
end _asDate


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("calendar")
	set config to std's import("config")
	
	set textUtil to std's import("string")
	set regex to std's import("regex")
	set retry to std's import("retry")'s new()
	set sb to std's import("string-builder")
	set decoratorCalView to std's import("dec-calendar-view")
	set calendarEvent to std's import("calendar-event")'s new()
	
	set counter to std's import("counter")
	set plutil to std's import("plutil")'s new()
	set dt to std's import("date-time")
	set calProcess to std's import("process")'s new("Calendar")
	set kb to std's import("keyboard")'s new()
end init