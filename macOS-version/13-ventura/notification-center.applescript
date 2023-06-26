(* 
	User/client facing library. 
	
	@Version:
		macOS Ventura
		
	@Changes:
		scroll area is now moved under a group
		buttons no longer have name, title, nor description, so we need refer to them by index which is of course ambiguous.
	
	@Plists:
		notification-appname - contains mapping for app id to app name.
		
	@Known Issues
		For grouped notifications, if you want to dismiss the first notification only, the client code should expand the notification first.
*)

use script "Core Text Utilities"
use scripting additions

use listUtil : script "list"
use regex : script "regex"

use loggerLib : script "logger"
use plutilLib : script "plutil"
use notificationCenterHelperLib : script "notification-center-helper"

property logger : loggerLib's new("notification-center")
property plutil : plutilLib's new()
property notificationCenterHelper : notificationCenterHelperLib's new()

(*
	Problem with expanding notification of a Slack status report.
	
	Stacked notification will have the date of the latest notice.
	
	@TODO:
		Dismiss All dismissed only one notification.
*)

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	set thisCaseId to "notification-spotCheck"
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: Stacked Notice Details - toString()
		Manual: App Names
		Manual: For Each - Notification Helper
		Manual: Notifications By App (Try diff apps) 
		Manual: Dismiss

		Manual: Delete Mail
		Manual: Notifications Count
		Manual: Dismiss All - Didn't work initially
		Manual: Expand Notification
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
		set hasNotice to false
		tell application "System Events" to tell process "Notification Center"
			set hasNotice to exists window "Notification Center"
			
			if hasNotice then set notice to sut's new(group 1 of UI element 1 of scroll area 1 of group 1 of window "Notification Center")
		end tell
		
		if hasNotice then
			logger's infof("Notice: {}", notice's toString())
			logger's infof("Is Stacked: {}", notice's isStacked())
			
		end if
		
	else if caseIndex is 2 then
		set appNames to sut's getAppNames()
		if appNames is missing value or the (count of appNames) is 0 then
			logger's info("No notifications detected.")
			
		else
			repeat with nextAppName in appNames
				logger's infof("Next App Name: {}", nextAppName)
			end repeat
		end if
		
	else if caseIndex is 3 then
		script PrintTitle
			on next(notice)
				logger's infof("Title: {}", notice's title)
				-- 				log notice's toString()
			end next
		end script
		notificationCenterHelper's _forEach(result)
		
	else if caseIndex is 4 then
		set sutAppName to "Mail"
		set sutAppName to "Slack"
		set notices to sut's getNotificationsByAppName(sutAppName)
		
		if notices is missing value or the (count of notices) is 0 then
			logger's infof("There are no notifications for app name: {}", sutAppName)
		else
			repeat with nextNotice in notices
				logger's infof("Title: {}", nextNotice's title)
			end repeat
		end if
		
	else if caseIndex is 5 then
		tell application "System Events" to tell process "Notification Center"
			set hasANotice to exists window "Notification Center"
			if hasANotice then
				set currentNotice to sut's new(group 1 of UI element 1 of scroll area 1 of group 1 of window "Notification Center")
				if currentNotice's isStacked() then
					sut's expandNotification()
					delay 0.1 -- We want to dismiss the notification on the top, fails without this delay.
					set currentNotice to sut's new(last group of UI element 1 of scroll area 1 of group 1 of window "Notification Center")
				end if
			end if
			
			-- set currentNotice to sut's new(group 1 of UI element 1 of scroll area 1 of group 1 of window "Notification Center")
		end tell
		
		if hasANotice then
			logger's debugf("Dismissing: {}", currentNotice's title)
			logger's debugf("Body: {}", currentNotice's body)
			currentNotice's dismiss()
		end if
		
	else if caseIndex is 6 then
		set mailNotices to sut's getNotificationsByAppName("Mail")
		set hasANotice to (count of mailNotices) is not 0
		if hasANotice then
			set sut to first item of mailNotices
			sut's deleteMail()
			
		else
			logger's info("No mail notice was found.")
		end if
		
		
	else if caseIndex is 7 then
		logger's infof("Notifications Count: {}", count of sut's getNotificationsUI())
		
	else if caseIndex is 8 then
		sut's dismissAll()
		
	else if caseIndex is 9 then
		sut's expandNotification()
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	script NotificationCenterInstance
		
		on expandNotification()
			tell application "System Events" to tell process "Notification Center"
				if (count of windows) is 0 then return
				
				set topNoticeUI to missing value
				try
					set topNoticeUI to last group of UI element 1 of scroll area 1 of group 1 of window "Notification Center"
				end try
				
				if topNoticeUI is not missing value then
					perform action "AXPress" of topNoticeUI
					
				end if
			end tell
		end expandNotification
		
		(* 
			Works on regular notifications, not the time-sensitive ones.
		*)
		on dismissAll()
			tell application "System Events" to tell process "Notification Center"
				try
					if not (exists button 2 of UI element 1 of scroll area 1 of group 1 of window 1) then -- Clear All
						click last group of UI element 1 of scroll area 1 of group 1 of window 1
						delay 0.1
					end if
					repeat 2 times
						click button 2 of UI element 1 of scroll area 1 of group 1 of window 1
						delay 0.1
					end repeat
				end try
			end tell
		end dismissAll
		
		
		(* Accomplished by clicking on the time in the menu bar items *)
		on activateNotifications()
			tell application "System Events" to tell process "ControlCenter"
				try
					click menu bar item "Clock" of first menu bar
				end try
			end tell
		end activateNotifications
		
		
		on notify(theTitle, theSubtitle)
			tell application "System Events" to display notification with title theTitle subtitle theSubtitle sound name "Glass"
		end notify
		
		
		on getNotificationsUI()
			tell application "System Events" to tell process "Notification Center"
				set hasNotice to exists window "Notification Center"
				if hasNotice then return groups of UI element 1 of scroll area 1 of group 1 of window "Notification Center"
			end tell
			{}
		end getNotificationsUI
		
		
		--	START REFACTORNG HERE.
		(* *)
		on dismissPastNotifications(minuteThreshold as integer)
			script DismissPastScript
				to next(notice)
					if notice's olderThanMinutes(minuteThreshold) then
						logger's debugf("Dismissing: {}", title of notice)
						notice's dismiss()
					end if
				end next
			end script
			
			repeat 2 times -- Sometime we miss some on first run.
				notifCenterHelper's _reverseLoop(DismissPastScript)
			end repeat
		end dismissPastNotifications
		
		
		on dismissByTitleAndSubtitle(appName, theTitle, subtitle)
			_expandNotifications()
			
			script DismissBySubTitleScript
				to next(notice as script)
					if notice's appName is not equal to appName or notice's title is not equal to theTitle and notices's body is not equal to the subtitle then return
					
					logger's debugf("Dismissed: {} - {}: {}", {appName, theTitle, subtitle})
					notice's dismiss()
				end next
			end script
			notificationCenterHelper's _reverseLoop(result)
		end dismissByTitleAndSubtitle
		
		
		on dismissByTitle(appName, theTitle)
			_expandNotifications()
			
			script DismissByTitleScript
				to next(notice as script)
					if notice's appName is not equal to appName or notice's title is not equal to theTitle then return
					
					logger's debugf("Dismissed: {} - {}", {appName, theTitle})
					notice's dismiss()
				end next
			end script
			notificationCenterHelper's _reverseLoop(result)
		end dismissByTitle
		
		
		(* *)
		on deleteEmailNotifications()
			activateNotifications()
			_expandNotifications()
			
			script DeletePastMailScript
				on next(notice as script)
					log notice's appName
					if notice's appName is not equal to "MAIL" or not notice's isPast() then return
					
					notice's deleteNotice()
				end next
			end script
			notificationCenterHelper's _reverseLoop(result)
		end deleteEmailNotifications
		
		
		(* GENERAL HANDLERS *)
		on expandNotificationsByAppName(targetAppName as text)
			_expandNotifications for targetAppName
		end expandNotificationsByAppName
		
		
		(* 
			Could not store objects into list.
			@returns list of notification records.
		*)
		on getNotificationsByAppName(appName)
			expandNotificationsByAppName(appName)
			
			set appNotifications to {}
			script AppNotificationsScript
				on next(notice)
					if notice's appName is equal to the appName then set end of appNotifications to notice
				end next
			end script
			notificationCenterHelper's _forEach(result)
			
			appNotifications
		end getNotificationsByAppName
		
		
		(* @returns list of app names with active notification windows. *)
		on getAppNames()
			set retval to {}
			activate application "NotificationCenter"
			
			script AppNameScript
				on next(notice)
					set retval to retval & notice's appName
				end next
			end script
			notificationCenterHelper's _forEach(result)
			
			retval
		end getAppNames
		
		
		on new(theNotification)
			script NotificationInstance
				property appName : ""
				property when : missing value
				property header : missing value
				property title : missing value
				property subtitle : missing value
				property body : missing value
				property startTime : missing value
				
				property stacked : false
				property _actualNotification : theNotification
				
				on isStacked()
					stacked
				end isStacked
				
				(* Used for Mail notifications. *)
				on isPast()
					if when is missing value and startTime is missing value then return missing value
					
					isActualTime() or when starts with "Yesterday" or when contains "ago"
				end isPast
				
				on olderThanMinutes(targetMinute)
					if when contains "Yesterday" or when contains "days ago" or isActualTime() then return true
					when ends with "m ago" and regex's findFirst(when, "\\d{1,2}(?=m ago)") is greater than or equal to targetMinute
				end olderThanMinutes
				
				on isActualTime()
					regex's matches("^\\d{1,2}:\\d{1,2} [AP]M$", when)
				end isActualTime
				
				on hasActualTime()
					regex's matches("\\d{1,2}:\\d{1,2} [AP]M", when)
				end hasActualTime
				
				on hasStarted()
					if my startTime is missing value then return missing value
					
					date (my startTime) is less than or equal to (current date)
				end hasStarted
				
				-- Actions
				on clickNotice()
					tell application "System Events"
						click _actualNotification
						delay 0.5 -- 1 works well, let's experiment with shorter delay
					end tell
				end clickNotice
				
				(* Need further testing on Mac 21. *)
				on dismiss()
					if isStacked() then
						performAction("Clear All")
						return
					end if
					
					performAction("Close")
				end dismiss
				
				on deleteMail()
					if appName is not "Mail" then tell me to error "Invalid action for app " & appName
					
					tell application "System Events" to perform action 3 of item 1 of theNotification -- Trigger the delete button. Improve, don't use the number.		
				end deleteMail
				
				(* 
					@actionKeyword label that uniquely identifies the action
					
					@returns true of the action with name containing the keyword was found
				*)
				on performAction(actionKeyword)
					tell application "System Events" to tell process "Notification Center"
						repeat with actionIndex from 1 to (count of (actions of theNotification))
							if (name of action actionIndex of theNotification) contains actionKeyword then
								perform action actionIndex of theNotification
								return true
							end if
						end repeat
					end tell
					return false
				end performAction
				
				on toString()
					set theString to format {"App Name: {}
Header: {}
Title: {}
Subtitle: {}
When: {}
Body: {}
Is Stacked: {}
", {my appName, my header, my title, my subtitle, my when, my body, my isStacked()}}
				end toString
			end script
			
			set appNameMap to plutil's new("notification-app-id-name")
			tell application "System Events" to tell application process "Notification Center"
				set appId to get value of attribute "AXStackingIdentifier" of theNotification
			end tell
			
			-- logger's debugf("appId: {}", appId)
			
			set mappedAppName to appNameMap's getValue(appId)
			-- logger's debugf("mappedAppName: {}", mappedAppName)
			
			if mappedAppName is missing value then set mappedAppName to appId
			tell NotificationInstance to set its appName to mappedAppName
			
			tell application "System Events"
				repeat with nextStaticText in static texts of theNotification
					set uiId to get value of attribute "AXIdentifier" of nextStaticText
					set uiValue to get value of nextStaticText
					if uiId is equal to "header" then
						set the header of NotificationInstance to uiValue
						
					else if uiId is "title" then
						set the |title| of NotificationInstance to uiValue
						
					else if uiId is "subtitle" then
						set the subtitle of NotificationInstance to uiValue
						set parsedStartTime to regex's firstMatchInString("(?<=Today at )\\d{1,2}:\\d{1,2} [AP]M", uiValue)
						if parsedStartTime is not missing value then set the startTime of NotificationInstance to parsedStartTime
						
					else if uiId is equal to "body" then
						-- logger's debugf("uiValue: {}", uiValue)
						
						set the body of NotificationInstance to uiValue
						
					else if uiId is "date" then
						set the when of NotificationInstance to uiValue
						
					end if
				end repeat
				
				if help of theNotification is "Activate to expand" then set the stacked of NotificationInstance to true
			end tell
			NotificationInstance
		end new
		
		
		-- Private Codes below ======================================================
		on _expandNotifications for appName : missing value
			logger's debug("_expandNotifications....")
			try
				appName
			on error
				set appName to missing value
			end try
			
			activate application "NotificationCenter"
			script ExpandNoticeScript
				on next(notice)
					if not notice's isStacked() then return
					
					if appName is missing value then
						notice's clickNotice()
						return
					end if
					
					set noticeAppName to appName of notice
					if noticeAppName is equal to appName then notice's clickNotice()
				end next
			end script
			notificationCenterHelper's _reverseLoop(result)
		end _expandNotifications
	end script
end new

-- End Of Script
