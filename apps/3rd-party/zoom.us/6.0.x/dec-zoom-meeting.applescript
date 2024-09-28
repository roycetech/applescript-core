(*
	@Purpose:
		This script contains the very basic handlers for starting, leaving, and ending a meeting.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/zoom.us/6.0.x/dec-zoom-meeting

	@Created: Monday, August 12, 2024 at 4:29:20 PM
	@Last Modified: 2024-09-16 10:17:10
	@Change Logs:
*)
use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		NOOP: Info
		Manual: New Meeting
		Manual: End Meeting
		Manual: Leave Meeting
		Manual: End Meeting for All
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	-- activate application ""
	set sutLib to script "core/zoom"
	set sut to sutLib's new()
	set sut to decorate(sut)

	logger's infof("Meeting in progress?: {}", sut's isMeetingInProgress())
	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's newMeeting()

	else if caseIndex is 3 then
		sut's endMeeting()

	else if caseIndex is 4 then
		sut's leaveMeeting()

	else if caseIndex is 5 then
		sut's endMeetingForAll()

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


on newSpotBase()
	script SpotBaseInstance
		property template : missing value
	end script
end newSpotBase


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script ZoomMeetingDecorator
		property parent : mainScript

		(*
			Select the new meeting from the Home window.

			TODO: Check when user login is required.
		*)
		on newMeeting()
			if running of application "zoom.us" is false then
				logger's info("Launching zoom.us app...")
				activate application "zoom.us"
				delay 1
				waitMainWindowReady()
				if result is false then
					error "Could not start a new meeting"
				end if
			else
				logger's info("zoom.us is already running...")
				if isMeetingInProgress() then
					logger's info("Meeting is already in progress")
					return
				end if
			end if

			if getTabName() is not "Home" then
				switchTab("Home")
			end if

			tell application "System Events" to tell process "zoom.us"
				click (first button of splitter group 1 of window "Zoom Workplace" whose description starts with "Start a new meeting")
			end tell

			return


			set signinState to _waitForSignInOrSignedIn()
			if signinState is "signedin" then
				tell application "System Events" to tell process "zoom.us"
					click (first button of splitter group 1 of window "Zoom" whose description is "Start a new meeting with video on")
				end tell
			end if
		end newMeeting


		(*
			Used to detect that meeting has loaded and is in progress
			@returns true if meeting progress was detected.
		*)
		on waitForMeetingInProgress()
			set retry to retryLib's new()
			script MeetingProgressWaiter
				tell application "System Events" to tell process "zoom.us"
					if exists (first button of window "Zoom Meeting" whose description contains "mute") then return true
				end tell
			end script
			exec of retry on MeetingProgressWaiter
			result is not missing value
		end waitForMeetingInProgress


		on isMeetingInProgress()
			if running of application "zoom.us" is false then return false

			tell application "System Events" to tell process "zoom.us"
				try
					return exists (first button of window "Zoom Meeting" whose description contains "mute")
				end try
			end tell

			false
		end isMeetingInProgress


		(*
			Triggers the End button
		*)
		on endMeeting()
			if running of application "zoom.us" is false then return

			tell application "System Events" to tell process "zoom.us"
				try
					click (first button of window "Zoom Meeting" whose description is "End")
				end try
			end tell
		end endMeeting


		on endMeetingForAll()
			if running of application "zoom.us" is false then return

			endMeeting()
			delay 0.1

			tell application "System Events" to tell process "zoom.us"
				try
					click (first button of window "" whose description is "End meeting for all")
				end try
			end tell

		end endMeetingForAll

		on leaveMeeting()
			if running of application "zoom.us" is false then return

			endMeeting()
			delay 0.1

			tell application "System Events" to tell process "zoom.us"
				try
					click (first button of window "" whose description is "Leave meeting")
				end try
			end tell
		end leaveMeeting
	end script
end decorate
