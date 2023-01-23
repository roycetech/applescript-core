global std, regex, textUtil, listUtil, sb

(*
	Wrapper for the calendar UI event. Currently implemented with zoom.us, to be extracted.
*)

property initialized : false
property logger : missing value
property referenceDate : missing value
property IS_SPOT : false -- global initially, breaks when ran as dependency.

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "calendar-event-spotCheck"
	logger's start()
	
	set IS_SPOT to true
	
	-- If you haven't got these imports already.
	set cases to listUtil's splitByLine("
		To JSON String
		Manual: Find a suitable calendar event for testing.
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set calendarEventLib to new()
	if caseIndex is 1 then
		set sut to calendarEventLib's new({|description|:"Spot Meeting. Starts on Apr 9"})
		logger's infof("JSON String: {}", sut's toJsonString())
		
	else if caseIndex is 2 then
		
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
		on new(meetingStaticText)
			tell application "System Events" to tell process "Calendar"
				logger's debugf("MY IS_SPOT: {}", my IS_SPOT)
				if my IS_SPOT then
					set meetingDescription to |description| of meetingStaticText
				else
					set meetingDescription to description of meetingStaticText
				end if
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
				property body : missing value
				property active : false
				property actioned : true
				
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
					set attributeNames to listUtil's _split("title, organizer, startTime, endTime, meetingId, meetingPassword, passcode, active, actioned", ", ")
					set attributeValues to {my title, my organizer, my startTime, my endTime, my meetingId, my meetingPassword, my passcode, my active, my actioned}
					
					set nameValueList to {}
					set jsonBuilder to sb's new("{")
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
				try
					set attendeesButton to first button of group 1 of splitter group 1 of window "Calendar" whose description is "Edit Attendees"
				end try
				if attendeesButton is missing value then
					try
					set attendeesButton to first button of pop over 1 of window "Calendar" whose description is "Edit Attendees"
					end try
				end if
				
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
				set its actioned to meetingDescription does not end with "Needs action"
				try
					set startTimePart to regex's firstMatchInString("(?<=at )\\d{1,2}:\\d{2} [AP]M", meetingDescription)
					if my referenceDate is missing value then
						set its startTime to date startTimePart
					else
						set its startTime to date (my referenceDate & " " & startTimePart)
					end if
				end try -- when startTime is not available
				try
					set endTimePart to regex's firstMatchInString("(?<=ends at )\\d{1,2}:\\d{2} [AP]M", meetingDescription)
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
	end script
	
	std's applyMappedOverride(result)
end new



-- Private Codes below =======================================================

(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("calendar-event")
	set regex to std's import("regex")
	set textUtil to std's import("string")
	set listUtil to std's import("list")
	set sb to std's import("string-builder")
	
	tell application "System Events"
		set scriptName to get name of (path to me)
		set my IS_SPOT to scriptName is equal to "calendar-event.applescript"
	end tell
end init
