(*
	Zoom-specific handlers to determine the meeting ID, password, and to check if you are the meeting facilitator (creator)

	@Plists:
		zoom.us/config
			Display Name

	@Testing Note:
		Manually disable override in the config-lib-factory to test this decorator without first deploying to the Script Library folder.

	@Testing Cases:
		Pick a date in the calendar with a zoom event
		Pick a date in the calendar with a non-zoom event


*)

use script "core/Text Utilities"
use scripting additions

use listUtil : script "core/list"
use regex : script "core/regex"

use loggerLib : script "core/logger"
use plutilLib : script "core/plutil"
use uiutilLib : script "core/ui-util"
use calendarLib : script "core/calendar"
use calendarEventLib : script "core/calendar-event"
use decoratorLib : script "core/decorator"

use spotScript : script "core/spot-test"

property logger : missing value

property config : missing value
property uiutil : missing value
property calendar : missing value
property calendarEvent : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Extract Info
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	activate application "Calendar"

	set decoratedEvent to decorate(calendarEvent)
	logger's debugf("Name of calendar event: {}", name of decoratedEvent)

	if caseIndex is 1 then
		set selectedEvent to _spotGetSelectedEvent(decoratedEvent)
		if selectedEvent is missing value then error "Selected Event is missing value"

		logger's logObj("selected event", selectedEvent)
		logger's infof("Meeting ID: {}", selectedEvent's meetingId)
		logger's infof("Meeting Password: {}", selectedEvent's meetingPassword)
		logger's infof("Is Facilitator: {}", selectedEvent's facilitator)

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
		set subTarget to group 1 of splitter group 1 of window "Calendar"

		try
			set selectedEvent to first static text of list 1 of subTarget whose focused is true
			set selectedEventBody to uiutil's findUiWithIdAttribute(UI elements of subTarget, "notes-field")
		end try -- When none is selected on the iterated dow.
	end tell

	decoratedEvent's new(selectedEvent, selectedEventBody)
end _spotGetSelectedEvent



(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	set plutil to plutilLib's new()
	set config to plutil's new("zoom.us/config")
	set uiutil to uiutilLib's new()
	set calendar to calendarLib's new()
	set calendarEvent to calendarEventLib's new()

	script CalendarEventZoomLibrary
		property parent : mainScript

		on _checkFacilitator(meetingBodyTextField)
			set isSpot to name of current application is "Script Editor"
			if isSpot is true then
				try
					set meetingBodyText to |description| of meetingBodyTextField
				on error
					tell application "System Events" to tell process "Calendar"
						set meetingBodyText to value of meetingBodyTextField
					end tell
				end try
			else
				tell application "System Events" to tell process "Calendar"
					set meetingBodyText to value of meetingBodyTextField
				end tell
			end if

			set displayName to config's getValue("Display Name")
			set keyword to format {"{} is inviting you to a scheduled Zoom meeting", {displayName}}
			(offset of keyword in meetingBodyText) is greater than 0
		end _checkFacilitator


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

	set decorator to decoratorLib's new(result)
	decorator's decorate()
end decorate
