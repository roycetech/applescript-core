(*
	@requires notification-center to be deployed first.
*)

use scripting additions


use listUtil : script "list"

use loggerLib : script "logger"
use notificationCenterLib : script "notification-center"

use spotScript : script "spot-test"

property speech : false
property logger : loggerLib's new("notification-center-helper")
property notificationCenter : notificationCenterLib's new()

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	set thisCaseId to "notification-center-helper-spotCheck"
	logger's start()
	
	set cases to listUtil's splitByLine("
		Notice Meetings
		First Notice
		Last Notice
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	if caseIndex is 1 then
		repeat with nextActiveMeeting in sut's getActiveMeetingsFromNotices()
			logger's infof("Next Active Meeting: {}", nextActiveMeeting's toString())
		end repeat
		
	else if caseIndex is 2 then
		logger's infof("First Notice: {}", sut's firstNotice()'s toString())
		
	else
		logger's infof("Last Notice: {}", sut's lastNotice()'s toString())
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	script NotificationCenterHelperInstance
		on getActiveMeetingsFromNotices() -- For Migration.
			set meetingNotices to {}
			
			script AScript
				on next(notice)
					if zoomId of notice is not missing value and date (startTime of notice) is less than (current date) then
						set end of meetingNotices to notice
					end if
				end next
			end script
			_forEach(result)
			
			meetingNotices
		end getActiveMeetingsFromNotices
		
		
		(* Top most on screen. *)
		on firstNotice()
			tell application "System Events" to tell process "Notification Center"
				if not (window "Notification Center" exists) then return missing value
				
				try
					set noticeGroups to groups of UI element 1 of scroll area 1 of window "Notification Center"
				end try
			end tell
			
			set sortedGroup to _simpleSort(noticeGroups)
			notificationCenter's new(first item of sortedGroup)
		end firstNotice
		
		
		(* Bottom on the screen. *)
		on lastNotice()
			tell application "System Events" to tell process "Notification Center"
				if not (window "Notification Center" exists) then return missing value
				
				try
					set noticeGroups to groups of UI element 1 of scroll area 1 of window "Notification Center"
				end try
			end tell
			
			set sortedGroup to _simpleSort(noticeGroups)
			notificationCenter's new(last item of sortedGroup)
		end lastNotice
		
		
		-- Private Codes below =======================================================
		on _forEach(scriptObj)
			tell application "System Events" to tell process "Notification Center"
				if not (window "Notification Center" exists) then return
				
				try
					set noticeGroups to groups of UI element 1 of scroll area 1 of window "Notification Center"
				end try
			end tell
			
			set sortedGroup to _simpleSort(noticeGroups)
			repeat with nextNotice in sortedGroup
				scriptObj's next(notificationCenter's new(nextNotice))
			end repeat
		end _forEach
		
		
		on _reverseLoop(scriptObj)
			tell application "System Events" to tell process "Notification Center"
				if not (window "Notification Center" exists) then return
				
				try
					set noticeGroups to groups of UI element 1 of scroll area 1 of window "Notification Center"
				end try
			end tell
			
			set sortedGroup to _simpleSort(noticeGroups)
			repeat with i from (count noticeGroups) to 1 by -1
				scriptObj's next(notificationCenter's new(item i of noticeGroups))
			end repeat
		end _reverseLoop
		
		
		on _simpleSort(noticeList)
			set the index_list to {}
			set the sorted_list to {}
			
			repeat (the number of items in noticeList) times
				set the low_item to missing value
				set the low_item_position to missing value
				
				repeat with i from 1 to (number of items in noticeList)
					if i is not in the index_list then
						set this_item to item i of noticeList
						tell application "System Events" to tell process "Notification Center"
							set coord to get position of this_item
							set this_item_position to last item of coord as integer
						end tell
						
						if the low_item is missing value then
							set the low_item to this_item
							set the low_item_index to i
							set the low_item_position to this_item_position
							
						else if this_item_position is less than low_item_position then
							set the low_item to this_item
							set the low_item_position to this_item_position
							set the low_item_index to i
							
						end if
					end if
				end repeat
				
				set the end of sorted_list to the low_item
				set the end of the index_list to the low_item_index
			end repeat
			
			sorted_list
		end _simpleSort
	end script
end new
