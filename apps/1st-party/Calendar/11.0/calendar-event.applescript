
(*
	Wrapper for the calendar UI event. Originally implemented with zoom.us, 
	refactored to be vendor-agnostic.
	
	@Requires
		Calendar needs to be in "Day" view.
		
	@Build:
		make compile-lib SOURCE=apps/1st-party/Calendar/11.0/calendar-event

	@Last Modified: 2023-07-04 14:05:31
*)

use scripting additions

use listUtil : script "list"
use textUtil : script "string"
use regex : script "regex"

use loggerLib : script "logger"
use kbLib : script "keyboard"
use sbLib : script "string-builder"
use uiutilLib : script "ui-util"

use spotScript : script "spot-test"
use overriderLib : script "overrider"

property overrider : overriderLib's new()

property logger : loggerLib's new("calendar-event")
property kb : kbLib's new()
property uiutil : uiutilLib's new()

property referenceDate : missing value
property isSpot : false

tell application "System Events"
	set scriptName to get name of (path to me)
end tell

set isSpot to scriptName is equal to "calendar-event.applescript"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	set skip of overrider to true
	set thisCaseId to "calendar-event-spotCheck"
	logger's start()
	
	set my isSpot to true
	set cases to listUtil's splitByLine("
		Manual: To JSON String
		Manual: Find a suitable calendar event for testing.
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set calendarEventLib to new()
	if caseIndex is 1 then
		set sut to calendarEventLib's new({|description|:"Spot Meeting. Starts on Apr 9., "}, missing value)
		logger's infof("JSON String: {}", sut's toJsonString())
		
	else if caseIndex is 2 then
		set IS_SPOT to false
		tell application "System Events" to tell process "Calendar"
			-- Tested on Week with May 17, 2023
			set uiSut to static text 9 of list 1 of group 1 of splitter group 1 of window "Calendar"
			set uiSutBody to uiutil's findUiWithIdAttribute(UI elements of group 1 of splitter group 1 of window "Calendar", "notes-field") -- Can be text field or static text.
			-- set uiSutBody to text field 3 of group 1 of splitter group 1 of window "Calendar"
		end tell
		set sut to calendarEventLib's new(uiSut, uiSutBody)
		logger's infof("JSON String: {}", sut's toJsonString())
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*
	Returns early if unhappy conditions met.

	@meeting the system event UI element.
*)
on new()
	script CalendarEventLibrary
		on new(meetingStaticText, meetingBodyTextField)
			tell application "System Events" to tell process "Calendar"
				-- logger's debugf("MY IS_SPOT: {}", my IS_SPOT)
				if my isSpot then
					set meetingDescription to |description| of meetingStaticText
				else
					set meetingDescription to description of meetingStaticText
				end if
				-- logger's debugf("meetingDescription: {}", meetingDescription)
			end tell
			
			script CalendarEventInstance
				property meetingId : missing value
				property meetingPassword : missing value
				property passcode : missing value
				property title : missing value
				property startTime : missing value
				property endTime : missing value
				property organizer : missing value
				property eventUi : meetingStaticText
				property eventUiDetails : meetingBodyTextField
				property body : missing value
				property active : false
				property actioned : true
				property accepted : false
				property facilitator : false
				
				on isOnline()
					meetingId is not missing value
				end isOnline
				
				on toString()
					textUtil's formatNext("Title: {}
Organizer: {}
Start: {}
End: {}
Meeting ID: {}
Meeting Password: {}
Passcode: {}
", {my title, my organizer, my startTime, my endTime, my meetingId, my meetingPassword, my passcode})
				end toString
				
				(* BattleScar, interpolation bugs out. *)
				on toJsonString()
					set attributeNames to listUtil's _split("title, organizer, startTime, endTime, meetingId, meetingPassword, passcode, active, actioned, accepted, facilitator", ", ")
					set attributeValues to {my title, my organizer, my startTime, my endTime, my meetingId, my meetingPassword, my passcode, my active, my actioned, my accepted, my facilitator}
					
					set nameValueList to {}
					set jsonBuilder to sbLib's new("{")
					repeat with i from 1 to count of attributeNames
						if i is not 1 then jsonBuilder's append(", ")
						set nextName to item i of attributeNames
						set nextValue to item i of attributeValues
						
						set end of nameValueList to nextName
						set end of nameValueList to nextValue
						
						jsonBuilder's append("\"" & nextName & "\": ")
						if nextValue is missing value then
							jsonBuilder's append("null")
							
						else if {integer, real, boolean} contains class of nextValue then
							jsonBuilder's append(nextValue)
							
						else
							jsonBuilder's append("\"" & nextValue & "\"")
						end if
					end repeat
					jsonBuilder's append("}")
					jsonBuilder's toString()
				end toJsonString
			end script
			
			set eventOrganizer to missing value
			set attendeesButton to missing value
			tell application "System Events" to tell process "Calendar"
				-- try
				-- 	set attendeesButton to first button of group 1 of splitter group 1 of window "Calendar" whose description is "Edit Attendees"
				-- end try
				-- if attendeesButton is missing value then
				-- 	try
				-- 		set attendeesButton to first button of pop over 1 of window "Calendar" whose description is "Edit Attendees"
				-- 	end try
				-- end if
				set attendeesButton to uiutil's findUiWithIdAttribute(buttons of group 1 of splitter group 1 of front window, "invitees-button")
				if attendeesButton is not missing value then
					repeat with nextStaticText in static texts of attendeesButton
						try
							set eventOrganizer to get value of text field 1 of nextStaticText
							exit repeat
						end try
					end repeat
				end if
				
				try
					set CalendarEventInstance's body to value of first static text of group 1 of splitter group 1 of window "Calendar" whose value of attribute "AXPlaceholderValue" is "Add Notes"
				end try
				
				if CalendarEventInstance's body is not missing value then
					set CalendarEventInstance's passcode to regex's firstMatchInString("(?<=Passcode: )\\d+", CalendarEventInstance's body)
				end if
			end tell
			
			tell CalendarEventInstance
				set its title to regex's firstMatchInString("^.*?(?=\\. Starts on | at)", meetingDescription)
				set its organizer to regex's firstMatchInString(".*(?= \\(organizer\\))", eventOrganizer)
				-- set its meetingId to regex's firstMatchInString("(?<=zoom\\.us\\/j\\/)\\d+", meetingDescription)
				set its meetingId to my extractMeetingId(meetingStaticText)
				-- set its meetingPassword to regex's firstMatchInString("(?<=pwd=)\\w+", meetingDescription)
				set its meetingPassword to my extractMeetingPassword(meetingStaticText)
				-- logger's debugf("meetingDescription: {}", meetingDescription)
				set its actioned to meetingDescription does not end with "Needs action"
				-- set its accepted to meetingDescription does not end with "Needs action" and textUtil's rtrim(meetingDescription) does not end with ","
				try
					set its facilitator to my _checkFacilitator(meetingBodyTextField)
					if its facilitator then set its organizer to "you"
				end try -- TOFIX
				
				set acceptTicked to false
				-- set uiActionPerformed to false
				
				if not my skipEvent(meetingStaticText) and isSpot is false then
					tell application "System Events" to tell process "Calendar"
						try
							(*
							perform action "AXShowMenu" of meetingStaticText -- fails when accessing "my eventUi" from here.
							set uiActionPerformed to true
							get value of attribute "AXMenuItemMarkChar" of menu item "Accept" of menu 1 of meetingStaticText
							set acceptTicked to true
							*)
							set acceptTicked to "Accepted" is equal to the value of pop up button 2 of group 1 of splitter group 1 of window "Calendar"
							-- on error the errorMessage number the errorNumber
							-- logger's warn(errorMessage)
						end try
					end tell
					-- if uiActionPerformed then kb's pressKey("esc")
					-- logger's debugf("acceptTicked: {}", acceptTicked)
				end if
				set its accepted to acceptTicked
				
				try
					set startTimePart to regex's firstMatchInString("(?<=at )\\d{1,2}:\\d{2}(?::\\d{2})? [AP]M", meetingDescription)
					if my referenceDate is missing value then
						set its startTime to date startTimePart
					else
						set its startTime to date (my referenceDate & " " & startTimePart)
					end if
				end try -- when startTime is not available
				try
					set endTimePart to regex's firstMatchInString("(?<=ends at )\\d{1,2}:\\d{2}(?::\\d{2})? [AP]M", meetingDescription)
					if my referenceDate is missing value then
						set its endTime to date endTimePart
					else
						set its endTime to date (my referenceDate & " " & endTimePart)
					end if
				end try -- when endTime is not available
			end tell
			
			CalendarEventInstance
		end new
		
		(* 
			@Overridable
			Retrieve the online meeting ID based the user's set up. zoom.us, ms teams, etc.
		*)
		on extractMeetingId(meetingStaticText)
			missing value
		end extractMeetingId
		
		
		(* 
			@Overridable
			Retrieve the online meeting password based the user's set up. zoom.us, ms teams, etc.
		*)
		on extractMeetingPassword(meetingStaticText)
			missing value
		end extractMeetingPassword
		
		(*
			Used to determine if the current event accept state should be 
			computed because it is a slow operation which would benefit if we 
			can skip non-meeting events.

			@returns boolean.
		*)
		on skipEvent(meetingStaticText)
			false
		end skipEvent
		
		
		on _checkFacilitator(meetingBodyTextField)
			false
		end _checkFacilitator
	end script
	
	overrider's applyMappedOverride(result)
end new
