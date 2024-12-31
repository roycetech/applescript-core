(*
	@Purpose:
		This decorator will contain common meeting actions for mic.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/zoom.us/6.0.x/dec-zoom-meeting-actions

	@Created: Monday, August 19, 2024 at 2:29:13 PM
	@Last Modified: 2024-12-31 19:33:22
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
		Manual: Mute Microphone
		Manual: Unmute Microphone
		Manual: Set Mic to System
		Manual: Set Mic
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
	logger's infof("Is mic on: {}", sut's isMicOn())
	logger's infof("Selected mic: {}", sut's getSelectedMic())

	logger's infof("Audio Button Popup Open: {}", sut's isAudioPopupOpen())

	sut's triggerAudioButtonPopup()
	logger's infof("Audio Button Popup Open after trigger: {}", sut's isAudioPopupOpen())
	logger's infof("Selected Audio at index 1: {}", sut's getSelectedItemAtIndex(1))
	logger's infof("Selected Audio at index 2: {}", sut's getSelectedItemAtIndex(2))
	logger's infof("Selected Audio at index 99: {}", sut's getSelectedItemAtIndex(99))
	sut's closeAudioPopup()

	logger's infof("Audio Button Popup Open after trigger: {}", sut's isAudioPopupOpen())
	logger's infof("Selected Audio at index 1: {}", sut's getSelectedItemAtIndex(1))
	logger's infof("Selected Audio at index 2: {}", sut's getSelectedItemAtIndex(2))
	logger's infof("Selected Audio at index 99: {}", sut's getSelectedItemAtIndex(99))

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's mute()

	else if caseIndex is 3 then
		sut's unmute()

	else if caseIndex is 4 then
		sut's setMicToSystem()


	else if caseIndex is 5 then
		sut's setMic("MacBook Pro Microphone")

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	set cliclick to cliclickLib's new()

	script ZoomMeetingActionsAudioDecorator
		property parent : mainScript

		on triggerAudioButtonPopup()
			if running of application "zoom.us" is false then return

			tell application "System Events" to tell process "zoom.us"
				click (first button of window "Zoom Meeting" whose description is "Audio sub menu")
			end tell
		end triggerAudioButtonPopup


		on closeAudioPopup()
			if not isAudioPopupOpen() then return

			triggerAudioButtonPopup()
		end closeAudioPopup


		on isAudioPopupOpen()
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
		end isAudioPopupOpen


		on isMicOn()
			if running of application "zoom.us" is false then return false

			set meetingWindow to getMeetingWindow()
			if meetingWindow is missing value then return false

			tell application "System Events" to tell process "zoom.us"
				try
					return exists menu item "Mute Audio" of menu 1 of menu bar item "Meeting" of menu bar 1
				end try
			end tell

			false
		end isMicOn

		on mute()
			_clickMenuAction("Mute Audio")
		end mute


		on unmute()
			_clickMenuAction("Unmute Audio")
		end unmute


		on getSelectedMic()
			if running of application "zoom.us" is false then return missing value
			triggerAudioButtonPopup()
			set selectedMicDescription to getSelectedItemAtIndex(1)
			closeAudioPopup()
			selectedMicDescription
		end getSelectedMic


		on setMicToSystem()
			_clickAudioSubMenu("Same as system")
		end setMicToSystem


		on setMic(descriptionStart)
			_clickAudioSubMenu(descriptionStart)
		end setMic


		on _clickAudioSubMenu(buttonStartDescription)
			if running of application "zoom.us" is false then return

			tell application "System Events" to tell process "zoom.us"
				if not (window "Zoom Meeting" exists) then return

				click (first button of window "Zoom Meeting" whose description is "Audio sub menu")
				set targetRow to (first row of table 1 of scroll area 1 of window "Menu window" whose value of static text 1 of UI element 1 of UI element 1 starts with buttonStartDescription)
			end tell
			lclick of cliclick at targetRow -- regular click fails to work.
		end _clickAudioSubMenu


	end script
end decorate
