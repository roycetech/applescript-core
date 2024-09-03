(*
	@Purpose:
		This decorator will contain handlers for screen sharing.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/zoom.us/6.0.x/dec-zoom-meeting-actions-sharing

	@Created: Wed, Aug 21, 2024 at 2:18:13 PM
	@Last Modified: 2024-08-21 14:29:51
	@Change Logs:
*)
use unic : script "core/unicodes"
use cliclickLib : script "core/cliclick"

use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"

property logger : missing value
property cliclick : missing value
property kb : missing value

property SHARING_WIN_NAME : "zoom share toolbar window"
-- property SELECT_SHARE_WIN_NAME : "Select a window or an application that you want to share"
property SELECT_SHARE_WIN_NAME : "Share screen window"
property SHARING_STATUSBAR_WIN_NAME : "zoom share statusbar window"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()


on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Main: INFO
		Manual: Start Sharing with Audio
		Manual: Start Sharing without Audio
		Manual: Stop Screen Sharing
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

	(* NOTE: Check also during when meeting controls are not shown. *)
	logger's infof("Always show controls: {}", sut's isAlwaysShowControls())
	logger's infof("Is sharing on: {}", sut's isScreenSharing())
	logger's infof("Is sharing selection present: {}", sut's isSharingSelectionPresent())

	if caseIndex is 1 then

	else if caseIndex is 2 then
		startSharing of sut with audio

	else if caseIndex is 3 then
		startSharing of sut without audio

	else if caseIndex is 4 then
		sut's stopSharing()

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

	set cliclick to cliclickLib's new()
	set kb to kbLib's new()

	script ZoomMeetingActionsDecorator
		property parent : mainScript

		on isAlwaysShowControls()
			if running of application "zoom.us" is false then return false

			tell application "System Events" to tell process "zoom.us"
				try
					return unic's MENU_CHECK is equal to the value of attribute "AXMenuItemMarkChar" of menu item "Always Show Meeting Controls" of menu 1 of menu bar item "Window" of menu bar 1
				end try
			end tell

			false
		end isAlwaysShowControls


		on isScreenSharing()
			if running of application "zoom.us" is false then return false

			tell application "System Events" to tell process "zoom.us"
				exists window SHARING_WIN_NAME
			end tell
		end isScreenSharing


		on isSharingSelectionPresent()
			if not running of application "zoom.us" then return false

			tell application "System Events" to tell process "zoom.us"
				window SELECT_SHARE_WIN_NAME exists
			end tell
		end isSharingSelectionPresent


		(* Too slow when in a big meeting. *)
		on startSharing given audio:theAudio as boolean
			if not running of application "zoom.us" then return

			set soundRequested to false
			try
				theAudio
				set soundRequested to theAudio
			end try

			if isScreenSharing() then
				-- FOR REVIEW.
				logger's debug("Already sharing...")

				tell application "System Events" to tell process "zoom.us"
					set sharingSound to (count of (images of window SHARING_STATUSBAR_WIN_NAME whose help starts with "You are sharing sound")) is not 0
				end tell
				set synched to sharingSound is equal to soundRequested
				logger's debug("Synched: " & synched)
				if synched then return

				my stopSharing()
			end if

			_clickMenuAction("Start share")

			logger's debug("Waiting for the share screen system dialogue window...")
			repeat until isSharingSelectionPresent()
				delay 0.5
			end repeat

			tell application "System Events" to tell process "zoom.us"
				set shareSoundCheckbox to checkbox 1 of scroll area 2 of window SELECT_SHARE_WIN_NAME
				set doTurnOn to soundRequested and value of shareSoundCheckbox is 0
				set doTurnOff to soundRequested is false and value of shareSoundCheckbox is 1

				if doTurnOff or doTurnOn then
					logger's info("Flip share sound option")
					click (first checkbox of scroll area 2 of window SELECT_SHARE_WIN_NAME whose description is "Share sound")
				end if

				tell window SELECT_SHARE_WIN_NAME to click (first button whose description starts with "Share ")
			end tell
		end startSharing


		on stopSharing()
			if not running of application "zoom.us" then return

			if isScreenSharing() is false then
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

	end script
end decorate
