(*
	This script contains the most basic wrapper functions for the current zoom app. Mostly starting a meeting and login-related functions only for the sake of simplicity.

	@Version: 6.0.x

	@Plists
		config-business:
			Domain Key

	@Related:
		zoom-actions.applescript - contains mic, video, hand raise, end meeting, sound source controls
		zoom-participants - participant-related functions.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/zoom.us/6.0.x/zoom

	@Testing:
		@Plists
			config-user.plist
				Zoom User Meeting ID - Personal ->
				Work Key (e.g. apple)
				Work Email

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
	@Last Modified: 2024-08-23 10:40:09
*)

use textUtil : script "core/string"
use listUtil : script "core/list"

use zoomMeeting : script "core/dec-zoom-meeting"

use decoratorMeeting : script "core/dec-zoom-meeting"
use decoratorMeetingActions : script "core/dec-zoom-meeting-actions"
use decoratorMeetingActionsAudio : script "core/dec-zoom-meeting-actions-audio"
use decoratorMeetingActionsVideo : script "core/dec-zoom-meeting-actions-video"
use decoratorMeetingActionsSharing : script "core/dec-zoom-meeting-actions-sharing"

use zoomParticipants : script "core/zoom-participants"
use zoomWindow : script "core/zoom-window"

use loggerFactory : script "core/logger-factory"

use configLib : script "core/config"
use plutilLib : script "core/plutil"
use retryLib : script "core/retry"
use kbLib : script "core/keyboard"
use systemSettingLib : script "core/system-settings"
use cliclickLib : script "core/cliclick"


use decoratorLib : script "core/decorator"

use spotScript : script "core/spot-test"

property configBusiness : missing value
property plutil : missing value
property configZoom : missing value
property retry : missing value
property kb : missing value

use script "core/Text Utilities"
use scripting additions

property logger : missing value
property systemSetting : missing value
property cliclick : missing value

if the name of current application is "Script Editor" then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		NOOP
		Manual: Wait Main Window
		Manual: Switch Tab
		Manual: Already Logged In, New Meeting
		Manual: End meeting

		Manual: New Meeting
		Start Personal Meeting - End to End
		Decorated: End Meeting - Prefer to leave meeting vs end the meeting
		Show Participants

		Join Current Meeting
		Reset Windows
	")

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
		logger's infof("Handler result: {}", sut's switchTab(targetTabName))

		(* Re-visit every cases below *)
	else if caseIndex is 4 then
		sut's newMeeting()


	else if caseIndex is 5 then
		sut's endMeeting()


	else if caseIndex is 3 then

		activate application "zoom.us"
		sut's _loginViaPassword()

	else if caseIndex is 2 then
		sut's newMeeting()

	else if caseIndex is 2 then
		-- set useSSO of sut to true
		set meetingID to configZoom's getValue("User Meeting ID")
		set username to configZoom's getValue("Username")
		logger's infof("meetingID: {}", meetingID)
		logger's infof("username: {}", username)
		set domainKey to configBusiness's getValue("Domain Key")
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

	set configBusiness to configLib's new("business")
	set plutil to plutilLib's new()
	set configZoom to plutil's new("zoom.us/config")
	set retry to retryLib's new()
	set kb to kbLib's new()

	script ZoomInstance
		property useSSO : false

		(* @returns true if the main window is detected to be ready before timing out. *)
		on waitMainWindowReady()
			if running of application "zoom.us" is false then return false

			set retry to retryLib's new()
			script WaitNewMeetingButton
				tell application "System Events" to tell process "zoom.us"
					if exists (first button of window "Zoom Workplace" whose value starts with "Home") then
						return true
					end if
				end tell
			end script
			exec of retry on result for 5
			result is not missing value
		end waitMainWindowReady


		(* @returns true if the switch didn't encounter an error. *)
		on switchTab(tabName)
			if running of application "zoom.us" is false then return false

			tell application "System Events" to tell process "zoom.us"
				try
					click (first button of window "Zoom Workplace" whose value starts with tabName)
					return true
				end try
			end tell

			false
		end switchTab


		on getTabName()
			if running of application "zoom.us" is false then return missing value

			tell application "System Events" to tell process "zoom.us"
				try
					value of (first button of window "Zoom Workplace" whose value ends with "selected")
					return first item of textUtil's split(result, ", ")
				on error the errorMessage number the errorNumber
					log errorMessage
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

	set decorator to decoratorLib's new(result)
	decorator's decorate()
end new
