(*
	This script contains the most basic wrapper functions for the current zoom app. Mostly starting a meeting and login-related functions only for the sake of simplicity.

	@Plists
		config-business:
			Domain Key

	@Related:
		zoom-actions.applescript - contains mic, video, hand raise, end meeting, sound source controls
		zoom-participants - participant-related functions.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/zoom.us/6.7/zoom

	Usage:
		-- join given id:"12345678"
		join given id:125678, domain:"apple" username:"john.appleseed.com" password:4321

	PREREQUISITES:
		[/] Automatically join audio by computer when joining a meeting.

	Must configure zoom to be muted on join, this button is used as indicator
		for some tasks that the meeting window is ready, one of which task is
		to arrange the windows. (NOT NEEDED)

	@Testing:
		@Plists:
			config-business
				Zoom User Meeting ID

	@Created: Wed, Aug 14, 2024 at 10:15:17 AM
	@Last Modified: 2026-03-24 17:31:36
*)
use scripting additions
use script "core/Text Utilities"

use std : script "core/std"
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use configLib : script "core/config"
use plutilLib : script "core/plutil"
use retryLib : script "core/retry"
use kbLib : script "core/keyboard"
use systemSettingLib : script "core/system-settings"
use cliclickLib : script "core/cliclick"

use decoratorLib : script "core/decorator"

property configBusiness : missing value
property plutil : missing value
property configZoom : missing value
property retry : missing value
property kb : missing value

property logger : missing value

property systemSetting : missing value
property cliclick : missing value

property CONFIG_BUSINESS : "business"
property CONFIG_ZOOM : "zoom.us/config"

(* For Testing Only. *)
property CONFIG_KEY_DOMAIN_KEY : "Domain Key"
property CONFIG_KEY_USER_MEETING_ID : "User Meeting ID"
property CONFIG_KEY_USERNAME : "Username"

if the name of current application is "Script Editor" then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		NOOP
		Manual: Wait Main Window
		Manual: Switch Tab
		Manual: New Meeting
		Manual: Integration: Already Logged In, New Meeting

		Manual: End meeting
		Start Personal Meeting - End to End
		Decorated: End Meeting - Prefer to leave meeting vs end the meeting
		Show Participants
		Join Current Meeting

		Reset Windows
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()
	logger's infof("Current tab name: {}", sut's getTabName())
	logger's infof("Meeting in progress?: {}", sut's isMeetingInProgress())

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's waitMainWindowReady()
		logger's infof("Handler result: {}", result)

	else if caseIndex is 3 then
		set targetTabName to "Unicorn"
		set targetTabName to "Home"
		-- set targetTabName to "Meetings"
		-- logger's infof("Handler result: {}", sut's switchTab(targetTabName))
		assertThat of std given condition:sut's switchTab(targetTabName), messageOnFail:"Switch tab failed"

	else if caseIndex is 4 then
		sut's newMeeting()

		(* Re-visit every cases below *)

	else if caseIndex is 5 then
		sut's endMeeting()


	else if caseIndex is 3 then

		activate application "zoom.us"
		sut's _loginViaPassword()

	else if caseIndex is 2 then
		sut's newMeeting()

	else if caseIndex is 2 then
		-- set useSSO of sut to true
		set meetingID to configZoom's getValue(CONFIG_KEY_USER_MEETING_ID)
		set username to configZoom's getValue(CONFIG_KEY_USERNAME)
		logger's infof("meetingID: {}", meetingID)
		logger's infof("username: {}", username)
		set domainKey to configBusiness's getValue(CONFIG_KEY_DOMAIN_KEY)
		logger's infof("domainKey: {}", domainKey)
		tell me to error "abort" -- IS THIS PROMINENT ENOUGH?!!!

		join of sut given id:meetingID, username:username, domain:domainKey


	else if caseIndex is 3 then
		sut's endMeeting()

	else if caseIndex is 4 then
		log isWaitingForSignIn()

	else if caseIndex is 5 then
		showParticipants()
		log isParticipantSidebarVisible()

	else if caseIndex is 6 then
		hideParticipants()
		log isParticipantSidebarVisible()

	else if caseIndex is 7 then
		log getParticipants()

	else if caseIndex is 10 then
		sut's cycleCamera()

	else if caseIndex is 12 then
		resetWindows()

	else if caseIndex is 13 then
		log isSharing()



	else if caseIndex is 15 then
		raiseHand()

	end if

	logger's finish()
	spot's finish()
end spotCheck


on new()
	loggerFactory's inject(me)
	set systemSetting to systemSettingLib's new()
	set cliclick to cliclickLib's new()
	set plutil to plutilLib's new()
	set retry to retryLib's new()
	set kb to kbLib's new()

	set configBusiness to configLib's new(CONFIG_BUSINESS)
	set configZoom to plutil's new(CONFIG_ZOOM)

	set decoratorMeeting to script "core/dec-zoom-meeting"
	set decoratorMeetingActions to script "core/dec-zoom-meeting-actions"
	set decoratorMeetingActionsAudio to script "core/dec-zoom-meeting-actions-audio"
	set decoratorMeetingActionsVideo to script "core/dec-zoom-meeting-actions-video"
	set decoratorMeetingActionsSharing to script "core/dec-zoom-meeting-actions-sharing"
	set decoratorPreview to script "core/dec-zoom-preview"

	script ZoomInstance
		property useSSO : false

		(* @returns true if the main window is detected to be ready before timing out. *)
		on waitMainWindowReady()
			if running of application "zoom.us" is false then return false

			set retry to retryLib's new()
			script WaitNewMeetingButton
				tell application "System Events" to tell process "zoom.us"
					(*
					if exists (first button of my _getVerticalTabUI() whose help starts with "Home") then
						return true
					end if
					*)
					if exists (first UI element of my _getVerticalTabUI() whose help of button 1 starts with "Home") then
						return true
					end if

				end tell
			end script
			exec of retry on result for 5
			result is not missing value
		end waitMainWindowReady


		on _getVerticalTabUI()
			tell application "System Events" to tell process "zoom.us"
				group 1 of window "Zoom Workplace"
			end tell
		end _getVerticalTabUI


		(* @returns true if the switch didn't encounter an error. *)
		on switchTab(tabName)
			if running of application "zoom.us" is false then return false

			tell application "System Events" to tell process "zoom.us"
				try
					-- click (first button of my _getVerticalTabUI() whose help starts with tabName)
					first UI element of my _getVerticalTabUI() whose help of button 1 starts with tabName
					click first button of result
					return true

				end try
			end tell

			false
		end switchTab


		on getTabName()
			if running of application "zoom.us" is false then return missing value

			tell application "System Events" to tell process "zoom.us"
				try
					first UI element of group 1 of window "Zoom Workplace" whose help of button 1 contains "selected"
					help of button 1 of result
					return first item of textUtil's split(result, ", ")

				end try
			end tell

			missing value
		end getTabName


		(* Optional password. *)
		on join given id:meetingID, domain:domain, username:username, password:password : missing value, passcode:passcode : missing value

			set zoomUrlScheme to format {"zoommtg://{}.zoom.us/join?confno={}&zc=0&uname={}&stype=100", {domain, meetingID, username}}
			open location zoomUrlScheme

			set nextStep to waitForNextStepAfterJoining()
			logger's debugf("nextStep: {}", nextStep)

			if nextStep is "login" then
				logger's info("Logging in...")
				if useSSO then
					logger's info("Using SSO to login...")
					_loginViaSSO()
				else
					_loginViaPassword()
				end if

			else if nextStep is "passcode" then
				tell application "System Events" to tell process "zoom.us"
					set value of text field 1 of group 1 of window "" to passcode
					click (first button of window "" whose description is "Join")
				end tell
			end if

			doWaitForMeetingInProgress()
		end join
	end script

	decoratorMeeting's decorate(result)
	decoratorMeetingActions's decorate(result)
	decoratorMeetingActionsAudio's decorate(result)
	decoratorMeetingActionsVideo's decorate(result)
	decoratorMeetingActionsSharing's decorate(result)
	decoratorPreview's decorate(result)

	set decorator to decoratorLib's new(result)
	decorator's decorate()
end new
