(*
	@Purpose:
		This decorator will contain common meeting actions for camera.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/zoom.us/6.0.x/dec-zoom-meeting-actions

	@Created: Monday, August 19, 2024 at 2:29:13 PM
	@Last Modified: 2024-08-21 13:43:16
	@Change Logs:
*)
use unic : script "core/unicodes"
use cliclickLib : script "core/cliclick"

use loggerFactory : script "core/logger-factory"

property logger : missing value
property cliclick : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Main: INFO
		Manual: Camera Off
		Manual: Camera On
		Manual: Cycle Camera
		Manual: Set Camera
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
	logger's infof("Is camera on: {}", sut's isCameraOn())
	logger's infof("Selected camera: {}", sut's getSelectedCamera())

	logger's infof("Video Button Popup Open: {}", sut's isVideoPopupOpen())

	sut's triggerVideoButtonPopup()
	logger's infof("Video Button Popup Open after trigger: {}", sut's isVideoPopupOpen())
	sut's closeVideoPopup()

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's cameraOff()

	else if caseIndex is 3 then
		sut's cameraOn()

	else if caseIndex is 4 then
		sut's cycleCamera()


	else if caseIndex is 5 then
		sut's switchCamera("Desk View")

	else if caseIndex is 6 then

	else if caseIndex is 7 then
		-- sut's setCamera()  -- TODO:

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

	set cliclick to cliclickLib's new()

	script ZoomMeetingActionsVideoDecorator
		property parent : mainScript

		on isCameraOn()
			if running of application "zoom.us" is false then return false

			set meetingWindow to getMeetingWindow()
			if meetingWindow is missing value then return false

			tell application "System Events" to tell process "zoom.us"
				return exists menu item "Stop Video" of menu 1 of menu bar item "Meeting" of menu bar 1
			end tell
		end isCameraOn


		on cameraOn()
			-- _clickMainButton("Start Video")
			_clickMenuAction("Start Video")
		end cameraOn


		on cameraOff()
			-- _clickMainButton("Stop Video")
			_clickMenuAction("Stop Video")
		end cameraOff


		(**)
		on cycleCamera()
			if not isCameraOn() then
				logger's info("Cannot cycle camera while it is off")
				return
			end if

			_clickMenuAction("Switch camera")
		end cycleCamera

		on getSelectedCamera()
			if running of application "zoom.us" is false then return missing value
			triggerVideoButtonPopup()
			set selectedCameraDescription to getSelectedItemAtIndex(1)
			closeVideoPopup()
			selectedCameraDescription
		end getSelectedCamera

		(* To Review Below for version 6.0.x. *)


		(**)
		on switchCamera(cameraKeyword)
			_clickVideoSubMenu(cameraKeyword)
		end switchCamera


		on triggerVideoButtonPopup()
			if running of application "zoom.us" is false then return

			tell application "System Events" to tell process "zoom.us"
				click (first button of window "Zoom Meeting" whose description is "Video sub menu")
			end tell
		end triggerVideoButtonPopup


		on isVideoPopupOpen()
			if running of application "zoom.us" is false then return false

			set meetingWindow to getMeetingWindow()
			if meetingWindow is missing value then return false

			tell application "System Events" to tell process "zoom.us"
				if not (exists window "Menu window") then return false

				try
					return value of static text 1 of UI element 1 of UI element 1 of row 1 of table 1 of scroll area 1 of window "Menu window" is equal to "Select a microphone"
				end try
			end tell

			false
		end isVideoPopupOpen


		on closeVideoPopup()
			if not isVideoPopupOpen() then return

			triggerVideoButtonPopup()
		end closeVideoPopup


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
	end script
end decorate
