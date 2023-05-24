global std, regex, textUtil, retry, sb, calendarEvent, counter, plutil, dt, kb, configUser, uiutil
global decoratorCalView, calProcess

use script "Core Text Utilities"
use scripting additions

(*
	@Plists
		counter
			calendar.getMeetingsAtThisTime - for other scripts to limit this 
			slow, user-interrupting check to once per day.

		config-user.plist
			User Country - User configured location country, used to select the 
			default timezone when reading the calendar events.

	@Testing
		Modify the handler getCurrentDate() for the desired test date.
		Morning today

	When parsing meetings for the day, list of records will be returned. In 
	parallel, a list ACTIVE_MEETINGs will contain the references to the UI.
	
	TODO: 
		Broken when using 24H time format.
		- Organizer still unreliably derived as of March 2, 2022
		- Re-implement using native scripting
		- Add multiple timezone support.
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
	set map to std's import("map")
	
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
		Manual: Get Online Meetings
		Manual: Get Next Online Meeting
		
		Manual: Switch to the user-configured timezone
		Manual: Switch to another timezone
		Manual: Current Timezone
	")
	
	(* Manually configure this. *)
	set spotData to {online_only:date "Wednesday, January 26, 2022 at 7:30:00 AM", online_and_offline:date "Wednesday, November 23, 2022 at 7:00:00 AM"}
	
	set spotLib to std's import("spot-test")'s new()
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
		(*
			Cases:
				No Meetings
				One online meetings
				Two online meetings
				One online, one offline meeting
		*)
		
		tell sut
			set its IS_TEST to true
			set its TEST_DATETIME to online_and_offline of spotData
		end tell
		
		set meetingsAtThisTime to sut's getMeetingsAtThisTime()
		set meetingCount to the count of meetingsAtThisTime
		logger's infof("Meetings at this time: {}", meetingCount)
		if meetingCount is not 0 then
			repeat with nextMeeting in meetingsAtThisTime
				set meetingASDictionary to map's fromRecord(nextMeeting)
				logger's infof("Next meeting today: {}", meetingASDictionary's toJSONString())
			end repeat
		end if
		
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
		
		logger's infof("Selected Event JSON: {}", selectedEvent's toJSONString())
		
	else if caseIndex is 8 then
		
		set meetingsAtThisTime to sut's getMeetingsAtThisTime()
		log (count of meetingsAtThisTime)
		repeat with nextActive in meetingsAtThisTime
			log (nextActive)
		end repeat
		
	else if caseIndex is 9 then
		try
			sut's clearCache()
		end try -- clear cache in not available by default but highly recommended
		
		tell sut
			set its IS_TEST to true
			set its TEST_DATETIME to online_and_offline of spotData
		end tell
		
		set currentOnlineMeetings to sut's getOnlineMeetingsAtThisTime()
		set meetingCount to the count of currentOnlineMeetings
		logger's infof("Online Meetings at this time: {}", meetingCount)
		if meetingCount is not 0 then
			repeat with nextMeeting in currentOnlineMeetings
				set meetingASDictionary to map's fromRecord(nextMeeting)
				logger's infof("Next meeting today: {}", meetingASDictionary's toStringPretty())
			end repeat
		end if
		
	else if caseIndex is 10 then
		set IS_TEST of sut to false
		set upcomingMeeting to sut's getNextOnlineMeeting()
		if upcomingMeeting is missing value then
			logger's info("No more meetings today, is that right?")
		else
			logger's info("Upcoming meeting found:")
			set meetingASDictionary to map's fromRecord(upcomingMeeting)
			logger's infof("Next online meeting today: {}", meetingASDictionary's toStringPretty())
		end if
		
	else if caseIndex is 11 then
		(*
			Check when configured on/off.
		*)
		logger's infof("Result: {}", sut's switchToDefaultTimezone())
		
		
	else if caseIndex is 12 then
		logger's infof("Result: {}", sut's switchTimezone("Au"))
		
	else if caseIndex is 13 then
		logger's infof("Result: {}", sut's getCurrentTimezone())
		
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
		
		on getCurrentTimezone()
			tell application "System Events" to tell process "Calendar"
				if not (exists pop up button 1 of group 3 of toolbar 1 of window "Calendar") then return missing value
				
				try
					return value of pop up button 1 of group 3 of toolbar 1 of window "Calendar"
				end try
			end tell
			missing value
		end getCurrentTimezone
		
		(*
			@returns true if the operation was completed without issues.
		*)
		on switchTimezone(timezoneKeyword)
			tell application "System Events" to tell process "Calendar"
				if not (exists pop up button 1 of group 3 of toolbar 1 of window "Calendar") then return false
				
				try
					click pop up button 1 of group 3 of toolbar 1 of window "Calendar"
				end try
				delay 0.1
				
				try
					click (first menu item of menu 1 of group 3 of toolbar 1 of window 1 whose name contains timezoneKeyword)
					return true
				end try
			end tell
			false
		end switchTimezone
		
		(*
			In case of the user enabling the timezone support in Calendar 
			preferences, this script assumes that the user prefers to get the 
			events relative to the current user timezone clock and what is 
			configured in config-user.plist.
		*)
		on switchToDefaultTimezone()
			set userCountry to configUser's getValue("User Country")
			if userCountry is not missing value then
				set userCountry to text 1 thru -2 of userCountry
			end if
			
			switchTimezone(userCountry)
		end switchToDefaultTimezone
		
		
		(* WARNING: Manually modify for testing *)
		on getCurrentDate()
			if IS_TEST is false then return the (current date)
			
			if TEST_DATETIME is missing value then
				-- logger's debugf("IS_TEST: {}", IS_TEST)
				return date "Monday, February 27, 2023 at 7:30:00 AM"
			end if
			
			TEST_DATETIME
		end getCurrentDate
		
		on gotoToday()
			if running of application "Calendar" is false then return
			
			tell application "System Events" to tell process "Calendar"
				if (count of windows) is 0 then return
				
				try
					click button "Today" of group 1 of group 1 of splitter group 1 of window "Calendar"
				on error -- macOS 13.2.1 Ventura
					try
						click (first button of group 1 of group 1 of splitter group 1 of window "Calendar" whose description is "Today")
					end try
				end try
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
			@returns the next meeting with online meeting_id. This includes meetings that are not actioned.
		*)
		on getNextOnlineMeeting()
			set currentDate to getCurrentDate()
			-- logger's debugf("currentDate: {}", currentDate)
			set currentWeekDay to weekday of currentDate as text
			set meetingsToday to getMeetingsOfTheDay(currentWeekDay)
			repeat with nextMeeting in meetingsToday
				if _asDate(nextMeeting's startTime) is greater than currentDate and meetingId of nextMeeting is not missing value then
					return nextMeeting
				end if
			end repeat
			missing value
		end getNextOnlineMeeting
		
		
		(* 
			TODO: For other view types. 
			@returns calendar-event instance.
		*)
		on getSelectedEvent()
			set currentViewType to getViewType()
			-- logger's debugf("currentViewType: {}", currentViewType)
			-- logger's debugf("name of event lib: {}", name of calendarEvent)
			
			if currentViewType is "Week" then
				tell application "System Events" to tell process "Calendar"
					repeat with nextDay in lists of UI element 1 of group 1 of splitter group 1 of window "Calendar"
						try
							set selectedEvent to (first static text of nextDay whose focused is true)
							-- TOFIX:
							return calendarEvent's new(selectedEvent)
							-- on error the errorMessage number the errorNumber
							-- 	logger's debug(errorMessage) -- Temp log, comment out for prod.	
						end try -- When none is selected on the iterated dow.
					end repeat
				end tell
			end if
			
			missing value
		end getSelectedEvent
		
		
		(*
			@dayOfTheWeek - ?
		*)
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
					set uiSutBody to uiutil's findUiWithIdAttribute(UI elements of group 1 of splitter group 1 of window "Calendar", "notes-field") -- Can be text field or static text.
					-- assertThat of std given condition:uiSutBody is not missing value, messageOnFail:"Unable to get event body"
					
					set meetingDetail to calendarEvent's new(nextST, uiSutBody)
					my _moveToNextEventViaUI()
					set end of meetingDetails to meetingDetail
				end repeat
			end tell
			
			switchToViewByTitle(origView)
			meetingDetails
		end getMeetingsOfTheDay
		
		
		(* 
			
			Only the action-ed meeting events are included.
			@Test Cases:
				No Meetings
				One Meeting
				Multiple Meetings
			
			@returns list of record (not script object). The list of active meetings at the current time.
		*)
		on getMeetingsAtThisTime()
			set theNow to getCurrentDate()
			logger's debugf("currentDate: {}", theNow)
			set currentWeekDay to weekday of theNow as text
			
			set theRetval to {}
			set meetingsToday to getMeetingsOfTheDay(currentWeekDay)
			logger's debugf("meetingsToday count: {}", count of meetingsToday)
			
			set activeMeetingIdx to 0
			repeat with idx from (count meetingsToday) to 1 by -1
				set meetingDetail to item idx of meetingsToday
				(*
				log title of meetingDetail
				log startTime of meetingDetail
*)
				if meetingDetail's startTime is not missing value then
					set startTriggerTime to _asDate(meetingDetail's startTime) - 2 * minutes
					set isActive to theNow is greater than or equal to startTriggerTime and theNow is less than _asDate(meetingDetail's endTime) - 2 * minutes
					set active of meetingDetail to isActive
					
					if isActive then set end of theRetval to meetingDetail
				end if
			end repeat
			
			theRetval
		end getMeetingsAtThisTime
		
		
		on getOnlineMeetingsAtThisTime()
			set meetingsAtThisTime to getMeetingsAtThisTime()
			set onlineMeetings to {}
			repeat with nextMeeting in meetingsAtThisTime
				if nextMeeting's meetingId is not missing value then set end of onlineMeetings to nextMeeting
			end repeat
			onlineMeetings
		end getOnlineMeetingsAtThisTime
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
	
	set configUser to std's import("config")'s new("user")
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
	set uiutil to std's import("ui-util")'s new()
end init
