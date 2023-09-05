(*
	User/client facing library.

	@Plists:
		notification-appname - contains mapping for app id to app name.

	@Last Modified: 2023-09-05 12:05:52

	For Mail notifications, the grouping must be set to Off.
*)

use script "Core Text Utilities"
use scripting additions

use listUtil : script "list"
use regex : script "regex"
use loggerFactory : script "logger-factory"

use loggerLib : script "logger"
use plutilLib : script "plutil"
use notificationCenterHelperLib : script "notification-center-helper"

use spotScript : script "core/spot-test"

property logger : missing value
property plutil : missing value
property notificationCenterHelper : missing value

(*
	Problem with expanding notification of a Slack status report.

	Stacked notification will have the date of the latest notice.
*)

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Info
		Manual: Expand First Notice
		Manual: For Each - Notification Util
		Manual: Notifications By App (Try diff apps)
		Dismiss

		Delete Mail
		Notifications Count
		Dismiss All - For further testing.
		Manual: Perform Action (Approve for an hour)
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()

	if caseIndex is 0 then
		logger's finish()
		return
	end if


	set sut to new()
	if caseIndex is 1 then
		logger's infof("Has Notification: {}", sut's hasNotification())

		set firstNotice to sut's firstNotice()
		if firstNotice is not missing value then
			logger's info(sut's firstNotice()'s toString())
		end if

		set lastNotice to sut's lastNotice()
		if lastNotice is not missing value then
			logger's info(sut's lastNotice()'s toString())
		end if

		set appNames to sut's getAppNames()

		if appNames is missing value or the (count of appNames) is 0 then
			logger's info("No notifications detected.")

		else
			repeat with nextAppName in appNames
				logger's infof("Next App Name: {}", nextAppName)
			end repeat
		end if

	else if caseIndex is 2 then
		set firstNotice to sut's firstNotice()
		firstNotice's expandNotification()


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
		set firstNotice to sut's firstNotice()
		if firstNotice is not missing value then
			firstNotice's dismiss()
		end if

		(*
		tell application "System Events" to tell process "Notification Center"
			set hasANotice to exists window "Notification Center"
			if hasANotice then
				set currentNotice to sut's new(group 1 of UI element 1 of scroll area 1 of window "Notification Center")
			end if
		end tell

		if hasANotice then
			logger's debugf("Dismissing: {}", currentNotice's title)
			logger's debugf("Body: {}", currentNotice's body)
			currentNotice's dismiss()
		end if
*)

	else if caseIndex is 6 then
		set mailNotices to sut's getNotificationsByAppName("Mail")
		set hasANotice to (count of mailNotices) is not 0
		if hasANotice then
			set sut to first item of mailNotices
			sut's deleteMail()

		else
			logger's info("No mail notice was found.")
			try
				set firstNotice to sut's firstNotice()
				firstNotice's deleteMail()
				logger's info("Deleted the first notice instead")

			end try
		end if


	else if caseIndex is 7 then
		logger's infof("Notifications Count: {}", count of sut's getNotificationsUI())

	else if caseIndex is 8 then
		sut's dismissAll()

	else if caseIndex is 9 then
		set lastNotice to sut's lastNotice()
		if lastNotice is not missing value then
			logger's info(sut's lastNotice()'s toString())
		end if

		lastNotice's performAction("Approve for an hour")

	end if

	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's inject(me)
	set plutil to plutilLib's new()
	notificationCenterHelperLib's inject(me)

	script NotificationCenterInstance

		on hasNotification()
			tell application "System Events" to tell process "Notification Center"
				exists window "Notification Center"
			end tell
		end hasNotification


		(* Top most on screen. *)
		on firstNotice()
			set noticeGroups to missing value
			tell application "System Events" to tell process "Notification Center"
				if not (window "Notification Center" exists) then return missing value

				try
					set noticeGroups to groups of UI element 1 of scroll area 1 of window "Notification Center"
				end try
			end tell
			if noticeGroups is missing value then return missing value

			set sortedGroup to notificationCenterHelper's _simpleSort(noticeGroups)
			new(first item of sortedGroup)
		end firstNotice



		(* Bottom on the screen. *)
		on lastNotice()
			set noticeGroups to missing value
			tell application "System Events" to tell process "Notification Center"
				if not (window "Notification Center" exists) then return missing value

				try
					set noticeGroups to groups of UI element 1 of scroll area 1 of window "Notification Center"
				end try
			end tell
			if noticeGroups is missing value then return missing value

			set sortedGroup to notificationCenterHelper's _simpleSort(noticeGroups)
			new(last item of sortedGroup)
		end lastNotice



		(*
			Works on regular notifications, not the time-sensitive ones.
		*)
		on dismissAll()
			tell application "System Events" to tell process "Notification Center"
				try
					if not (exists button "Clear" of UI element 1 of scroll area 1 of window 1) then
						click last group of UI element 1 of scroll area 1 of window 1
						delay 0.1
					end if
					repeat 2 times
						click button "Clear" of UI element 1 of scroll area 1 of window 1
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
				if hasNotice then return groups of UI element 1 of scroll area 1 of window "Notification Center"
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
			notifCenterHelper's _reverseLoop(result)
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
					log notice's appName
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

				on expand()
					expandNotification()
				end expand

				-- Actions
				on expandNotification()
					-- performAction("Show")
					clickNotice()
				end expandNotification

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
					-- if appName is not "Mail" then tell me to error "Invalid action for app " & appName

					-- tell application "System Events" to perform action 3 of item 1 of theNotification -- Trigger the delete button. Improve, don't use the number.
					tell application "System Events"
						-- to perform action 3 of item 1 of theNotification
						try
							perform (first action of theNotification whose description contains "Delete")
						end try
					end tell

					-- Trigger the delete button. Improve, don't use the number.
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
				(* This attribute may only work when the notifications are grouped. *)
				set appId to get value of attribute "AXStackingIdentifier" of theNotification
			end tell

			-- logger's debugf("appId: {}", appId)

			set mappedAppName to appNameMap's getValue(appId)
			-- logger's debugf("mappedAppName: {}", mappedAppName)

			if mappedAppName is missing value then set mappedAppName to appId
			tell NotificationInstance to set its appName to mappedAppName

			tell application "System Events"
				repeat with nextStaticText in static texts of theNotification
					try
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
					end try -- Some static texts doesn't have AXIdentifier attribute like the Screen Time Request: Leave on Time Sonsitive Notification...
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