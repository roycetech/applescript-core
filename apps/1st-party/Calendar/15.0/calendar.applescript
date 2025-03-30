(*
	@Requires:
		Permission to access the Calendar app.

	@Plists
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

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Calendar/15.0/calendar
*)


use scripting additions

use script "core/Text Utilities"

use textUtil : script "core/string"
use regex : script "core/regex"
use dt : script "core/date-time"

use loggerFactory : script "core/logger-factory"

use decoratorCalendarView : script "core/dec-calendar-view"
use decoratorCalendarMeeting : script "core/dec-calendar-meetings"
use calendarEventLib : script "core/calendar-event"

use sbLib : script "core/string-builder"
use uiutilLib : script "core/ui-util"
use retryLib : script "core/retry"
use configLib : script "core/config"
use mapLib : script "core/map"
use plutilLib : script "core/plutil"
use processLib : script "core/process"

use decoratorLib : script "core/decorator"

property logger : missing value
property uiutil : missing value
property retry : missing value
property plutil : missing value
property configUser : missing value
property calendarProcess : missing value
property calendarEvent : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	(* Manual Visual Verification. *)
	set listUtil to script "core/list"
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

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
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
				logger's infof("Next meeting today: {}", meetingASDictionary's toJsonString())
			end repeat
		end if

	else if caseIndex is 4 then
		set meetingsAtThisTime to sut's getMeetingsAtThisTime()
		logger's infof("Count of Meetings Now: {}", count of meetingsAtThisTime)
		repeat with nextActive in meetingsAtThisTime
			logger's infof("Next Active Meeting: {}", nextActive's toJsonString())
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
	loggerFactory's injectBasic(me)
	set uiutil to uiutilLib's new()
	set retry to retryLib's new()
	set plutil to plutilLib's new()
	set configUser to configLib's new("user")
	set calendarProcess to processLib's new("Calendar")
	set calendarEvent to calendarEventLib's new()

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
				set dateString to "Monday, February 27, 2023 at 7:30:00 AM"
				return date dateString
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
	end script

	decoratorCalendarMeeting's decorate(result)
	decoratorCalendarView's decorate(result)

	set decorator to decoratorLib's new(result)
	decorator's decorateByName("CalendarInstance")
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

	calendarProcess's terminate()

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
