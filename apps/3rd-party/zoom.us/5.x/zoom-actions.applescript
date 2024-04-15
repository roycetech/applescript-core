(*
	This decorator provides zoom action handlers.

	@Related:
		zoom.applescript

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/zoom.us/5.x/zoom-actions

	@Last Modified: 2024-04-15 11:04:46
*)

use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"
use usrLib : script "core/user"
use kbLib : script "core/keyboard"
use processLib : script "core/process"
use zoomUtilLib : script "core/zoom"
use cliclickLib : script "core/cliclick"

use spotScript : script "core/spot-test"

property logger : missing value

property usr : missing value
property kb : missing value
property cliclick : missing value

property SHARING_WIN_NAME : "zoom share toolbar window"
property SELECT_SHARE_WIN_NAME : "Select a window or an application that you want to share"
property SHARING_STATUSBAR_WIN_NAME : "zoom share statusbar window"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual Mute
		Manual: Unmute
		Manual: Start Video
		Manual: Stop Video
		Manual: Raise Hand

		Manual: Lower Hand
		Manual: Start Screen Sharing
		Manual: Stop Screen Sharing
		Manual: End Meeting
		Manual: Cycle Camera

		Manual: Switch to iPhone Camera

	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to zoomUtilLib's new()
	set sut to decorate(sut)

	if caseIndex is 1 then
		sut's mute()

	else if caseIndex is 2 then
		sut's unmute()

	else if caseIndex is 3 then
		sut's cameraOn()

	else if caseIndex is 4 then
		sut's cameraOff()

	else if caseIndex is 5 then
		sut's raiseHand()

	else if caseIndex is 6 then
		sut's lowerHand()

	else if caseIndex is 7 then
		sut's startSharing()

	else if caseIndex is 8 then
		sut's stopSharing()

	else if caseIndex is 9 then
		sut's endMeeting()

	else if caseIndex is 10 then
		sut's cycleCamera()

	else if caseIndex is 11 then
		sut's switchCamera("iPhone Camera")

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

	set usr to usrLib's new()
	set kb to kbLib's new()
	set cliclick to cliclickLib's new()

	(* Use the same name as the parent because this decorator is only meant to organize the handlers. *)
	script ZoomInstance
		property parent : mainScript
		property currentCamera : missing value


		(**)
		on switchCamera(cameraKeyword)
			_clickVideoSubMenu(cameraKeyword)
		end switchCamera

		(**)
		on cycleCamera(listOfCamera)
			# TODO
		end cycleCamera


		on mute()
			_clickMenuAction("Mute Audio")
		end mute


		on unmute()
			_clickMenuAction("Unmute Audio")
		end unmute


		on cameraOn()
			_clickMainButton("Start Video")
		end cameraOn


		on cameraOff()
			_clickMainButton("Stop Video")
		end cameraOff


		on setMicToSystem()
			_clickAudioSubMenu("MacBook Pro Microphone (MacBook Pro Microphone)")
		end setMicToSystem


		on setAudioToSystem()
			_clickAudioSubMenu("MacBook Pro Speakers (MacBook Pro Speakers)")
		end setAudioToSystem


		on raiseHand()
			if running of application "zoom.us" is false then return false

			activate application "zoom.us"
			delay 0.1
			tell application "System Events" to tell process "zoom.us"
				if name of front window is "Reactions" then
					logger's warn("Your virtual hand may already be raised")

				else if name of front window is "Zoom Meeting" then
					kb's pressOptionKey("y")
				else
					logger's warn("Couldn't find the Zoom Meeting window")
				end if
			end tell
		end raiseHand

		on lowerHand()
			if running of application "zoom.us" is false then return false

			activate application "zoom.us"
			delay 0.1
			tell application "System Events" to tell process "zoom.us"
				if name of front window is "Reactions" then
					kb's pressOptionKey("y")
				else
					logger's warn("Your virtual hand is not currently raised")
				end if
			end tell
		end lowerHand


		(* Too slow when in a big meeting. *)
		on startSharing given audio:theAudio as boolean
			if not running of application "zoom.us" then return

			set soundRequested to false
			try
				theAudio
				set soundRequested to theAudio
			end try

			tell application "System Events" to tell process "zoom.us"
				if exists (window SHARING_WIN_NAME) then
					logger's debug("Already sharing...")

					set sharingSound to (count of (images of window "zoom share statusbar window" whose help starts with "You are sharing sound")) is not 0
					set synched to sharingSound is equal to soundRequested
					logger's debug("Synched: " & synched)
					if synched then return

					my stopSharing()
				end if

				tell window "Zoom Meeting"
					click (first button whose description is "Share Screen")
				end tell

				logger's debug("Waiting for the share screen system dialogue window...")
				repeat until window SELECT_SHARE_WIN_NAME exists
					delay 0.5
				end repeat

				set doTurnOn to soundRequested and value of checkbox 1 of window SELECT_SHARE_WIN_NAME is 0
				set doTurnOff to soundRequested is false and value of checkbox 1 of window SELECT_SHARE_WIN_NAME is 1

				if doTurnOff or doTurnOn then
					click (first checkbox of window SELECT_SHARE_WIN_NAME whose description is "Share sound")
				end if

				tell window SELECT_SHARE_WIN_NAME to click (first button whose description starts with "Share ")
			end tell
		end startSharing


		on stopSharing()
			if not running of application "zoom.us" then return

			if usr's isScreenSharing() is false then
				logger's warn("Screen sharing appears to be off already.")
				return
			end if

			logger's debug("Stopping shared...")
			tell application "System Events" to tell process "zoom.us" to tell window "zoom share statusbar window"
				ignoring application responses
					click (first button whose description is "Stop Share")
				end ignoring
			end tell
		end stopSharing


		on endMeeting()
			if not running of application "zoom.us" then return false

			tell application "System Events" to tell process "zoom.us"
				set meetingWindowAbsent to not (exists (window "Zoom Meeting"))
			end tell

			if meetingWindowAbsent then
				set zoomProcess to process's new("zoom.us")
				zoomProcess's terminate()
				return
			end if

			tell application "System Events" to tell process "zoom.us"
				click (first button of window "Zoom Meeting" whose role description is "close button")
				delay 0.1

				try
					click (first button of window "" whose description is "Leave Meeting")
				on error
					click (first button of window "" whose description is "End Meeting for All")
				end try
			end tell
		end endMeeting


		on _clickAudioSubMenu(buttonDescription)
			if running of application "zoom.us" is false then return

			tell application "System Events" to tell process "zoom.us"
				if not (window "Zoom Meeting" exists) then return

				click (first button of window "Zoom Meeting" whose description is "Audio sub menu")
				set targetRow to (first row of table 1 of scroll area 1 of window "Menu window" whose value of static text 1 of UI element 1 of UI element 1 contains buttonKey)

				try
					-- click (first button of window "Menu window" whose description is buttonDescription)
				on error the errorMessage number the errorNumber
					-- logger's warn(errorMessage)
				end try
			end tell
			lclick of cliclick at targetRow
		end _clickAudioSubMenu


		on _clickVideoSubMenu(buttonKey)
			logger's debugf("buttonKey: {}", buttonKey)
			if running of application "zoom.us" is false then return

			tell application "System Events" to tell process "zoom.us"
				if not (window "Zoom Meeting" exists) then return

				click (first button of window "Zoom Meeting" whose description is "Video sub menu")
				set targetRow to missing value
				try
					set targetRow to (first row of table 1 of scroll area 1 of window "Menu window" whose value of static text 1 of UI element 1 of UI element 1 contains buttonKey)
				end try
			end tell

			if targetRow is not missing value then
				lclick of cliclick at targetRow without smoothing
			else
				tell application "System Events" to tell process "zoom.us"
					-- Click again to dismiss.
					click (first button of window "Zoom Meeting" whose description is "Video sub menu")
				end tell
			end if
		end _clickVideoSubMenu


		on _clickMenuAction(menuItemName)
			tell application "System Events" to tell process "zoom.us"
				try
					click menu item menuItemName of menu 1 of menu bar item "Meeting" of menu bar 1
				end try
			end tell
		end _clickMenuAction


		(*
			Will fail when the controls are not visible. We'll use menus instead for better predictability.
		*)
		on _clickMainButton(buttonStartName)
			if running of application "zoom.us" is false then return

			tell application "System Events" to tell process "zoom.us" to tell my _getMeetingWindow()
				try
					click (first button whose description starts with buttonStartName)
				on error the errorMessage number the errorNumber
					logger's warn(errorMessage)
				end try
			end tell
		end _clickMainButton
	end script
end decorate
