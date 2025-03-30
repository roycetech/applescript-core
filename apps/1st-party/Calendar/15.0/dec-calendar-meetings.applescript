(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Calendar/15.0/dec-calendar-meetings

	@Created: Sun, Mar 23, 2025 at 11:00:07 AM
	@Last Modified: 2025-03-23 17:47:13
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"
use dateTimeLib : script "core/date-time"
use calendarEventLib : script "core/calendar-event"
use uiutilLib : script "core/ui-util"

property logger : missing value
property kb : missing value
property dateTime : missing value
property calendarEvent : missing value
property uiutil : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	-- activate application ""
	set sutLib to script "core/calendar"
	set sut to sutLib's new()
	set sut to decorate(sut)

	logger's infof("PopOver present?: {}", sut's isPopOverPresent())
	logger's infof("Event Selected?: {}", sut's isEventSelected())
	logger's infof("Info window present?: {}", sut's isInfoWindowPresent())

	set sutDow to dateTime's getCurrentDayOfWeek()
	logger's debugf("sutDow: {}", sutDow)

	set mapLib to script "core/map"
	set meetingsOfDay to sut's getMeetingsOfTheDay(sutDow)
	if the (count of items in meetingsOfDay) is 0 then
		logger's info("There are no meetings for {}", sutDow)
	else
		repeat with nextMeeting in meetingsOfDay
			logger's infof("Meetings of the day {}: [{}]", {sutDow, nextMeeting's toString()})
		end repeat
	end if


	if caseIndex is 1 then

	else if caseIndex is 2 then

	else if caseIndex is 3 then

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set kb to kbLib's new()
	set dateTime to dateTimeLib's new()
	set calendarEvent to calendarEventLib's new()
	set uiutil to uiutilLib's new()

	script CalendarMeetingsDecorator
		property parent : mainScript


		on isPopOverPresent()
			if running of application "Calendar" is false then return false

			tell application "System Events" to tell process "Calendar"
				try
					return exists pop over 1 of window "Calendar"
				end try
			end tell
			false
		end isPopOverPresent


		on cancelPopOver()
			if not isPopOverPresent() then return

			tell application "System Events" to tell process "Calendar"
				perform action "AXCancel" of pop over 1 of window "Calendar"
			end tell
		end cancelPopOver



		on isEventSelected()
			if running of application "Calendar" is false then return false

			tell application "System Events" to tell process "Calendar"
				not (exists static text "No Event Selected" of group 1 of splitter group 1 of front window)
			end tell
		end isEventSelected


		on isInfoWindowPresent()
			tell application "System Events" to tell process "Calendar"
				try
					return static text "Info" of (first window whose description is "window") exists
				end try
			end tell

			false
		end isInfoWindowPresent


		(* @returns record (not script object). *)
		on getNextMeetingToday()
			set currentDate to getCurrentDate()
			logger's debugf("currentDate: {}", currentDate)

			set currentWeekDay to weekday of currentDate as text
			set meetingsToday to getMeetingsOfTheDay(currentWeekDay)
			repeat with nextMeeting in meetingsToday
				if nextMeeting's actioned and _asDate(nextMeeting's startTime) is greater than currentDate then
					return nextMeeting
				end if
			end repeat

			{}
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
			@dayOfTheWeek - [text] Sunday,Monday,...
			@returns list of CalendarEventInstance
		*)
		on getMeetingsOfTheDay(dayOfTheWeek)
			initCalendarApp()
			-- activate application "Calendar" -- Is this required?
			if isPopOverPresent() then cancelPopOver()
			-- or isEventSelected() then kb's pressKey("esc")

			set origView to getViewType()
			logger's debugf("origView: {}", origView)

			logger's debug("Switching to Day View")
			switchToDayView()

			set targetYyyyMMdd to dateTime's formatYyyyMmDd(getCurrentDate(), "/")
			logger's debugf("targetYyyyMMdd: {}", targetYyyyMMdd)

			gotoDate(targetYyyyMMdd) -- slash separated

			set targetMmDdYyyy to dateTime's formatMmDdYyyy(getCurrentDate(), "/")

			set referenceDate of calendarEvent to targetMmDdYyyy
			logger's debugf("referenceDate: {}", referenceDate of calendarEvent)

			set meetingDetails to {}

			tell application "System Events" to tell application process "Calendar"
				set staticTexts to static texts of list 1 of group 1 of splitter group 1 of window "Calendar"
				repeat with nextST in staticTexts
					perform action "AXPress" of nextST
					(* Can be text field or static text. *)
					set uiSutBody to uiutil's findUiWithIdAttribute(UI elements of group 1 of splitter group 1 of window "Calendar", "notes-field")
					set meetingDetail to calendarEvent's new(nextST, uiSutBody)

					logger's debug("Appending next meeting detail...")
					set end of meetingDetails to meetingDetail
				end repeat
			end tell

			cancelPopOver()
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
end decorate


