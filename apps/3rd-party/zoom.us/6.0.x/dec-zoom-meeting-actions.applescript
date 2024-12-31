(*
	@Purpose:
		This decorator will contain common meeting handlers for audio, video, and screen sharing.

	NOTE:
		Leaving and ending meeting actions are not included here and instead can be found in dec-zoom-meeting.applescript.
		Mic and camera state will be checked against the menu items for better reliability. Using buttons does not work when meeting controls are hidden.


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/zoom.us/6.0.x/dec-zoom-meeting-actions

	@Created: Monday, August 19, 2024 at 2:29:13 PM
	@Last Modified: 2024-12-31 19:33:35
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
		Manual: Raise Hand
		Manual: Lower Hand
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
	logger's infof("Is hand raised? {}", sut's isHandRaised())

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's raiseHand()

	else if caseIndex is 3 then
		sut's lowerHand()

	else if caseIndex is 4 then
		startSharing of sut with audio

	else if caseIndex is 5 then

	else if caseIndex is 6 then
		sut's cycleCamera()

	else if caseIndex is 7 then
		-- sut's setCamera()  -- TODO:

	else if caseIndex is 8 then

	else if caseIndex is 9 then


	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


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
				exists window (my SHARING_WIN_NAME)
			end tell
		end isScreenSharing


		on isHandRaised()
			if running of application "zoom.us" is false then return false

			tell application "System Events" to tell process "zoom.us"
				try
					buttons of UI element 1 of window "Reactions" whose description is "Lower hand"
					return the number of items in result is not 0
				end try
			end tell

			false
		end isHandRaised


		on raiseHand()
			if running of application "zoom.us" is false then return false

			tell application "System Events" to tell process "zoom.us"
				set frontmost to true
				if name of front window is "Reactions" then
					logger's warn("Your virtual hand may already be raised")

				else if name of front window is "Zoom Meeting" then
					-- logger's debug("Pressing the hotkey...")
					kb's pressOptionKey("y")
				else
					logger's warn("Couldn't find the Zoom Meeting window")
				end if
			end tell
		end raiseHand


		on lowerHand()
			if running of application "zoom.us" is false then return false

			tell application "System Events" to tell process "zoom.us"
				set frontmost to true
				if name of front window is "Reactions" then
					kb's pressOptionKey("y")
				else
					logger's warn("Your virtual hand is not currently raised")
				end if
			end tell
		end lowerHand


		(*
			Meeting window changes when screen sharing is triggered. This handler simplifies this.
		*)
		on getMeetingWindow()
			if running of application "zoom.us" is false then return missing value

			tell application "System Events" to tell process "zoom.us"
				if my isScreenSharing() then return window "zoom share toolbar window"

				try
					return window "Zoom Meeting"
				end try
			end tell

			missing value
		end getMeetingWindow


		(* To Review Below for version 6.0.x. *)


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

				-- tell window "Zoom Meeting"
				-- click (first button whose description is "Share Screen")
				-- end tell
				my _clickMenuAction("Start share")

				logger's debug("Waiting for the share screen system dialogue window...")
				repeat until window SELECT_SHARE_WIN_NAME exists
					delay 0.5
				end repeat
				log "Wait completed"

				set doTurnOn to soundRequested and value of checkbox 1 of scroll area 2 of window SELECT_SHARE_WIN_NAME is 0
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


		(* Used to return the description of the selected item under the audio or video button popup. *)
		on getSelectedItemAtIndex(checkedIndex)
			if running of application "zoom.us" is false then return missing value

			tell application "System Events" to tell process "zoom.us"
				if not (exists window "Menu window") then return missing value
				set menuRows to rows of table 1 of scroll area 1 of window "Menu window"
			end tell
			set checkedCounter to 0

			repeat with nextRow in menuRows
				try
					tell application "System Events" to tell process "zoom.us"
						set sizeValueText to value of attribute "AXSize" of image 1 of UI element 1 of UI element 1 of nextRow as text
						set nextItemDescription to value of static text 1 of UI element 1 of UI element 1 of nextRow
					end tell

					if sizeValueText is not equal to "00" then
						set checkedCounter to checkedCounter + 1
						if checkedCounter is equal to checkedIndex then return nextItemDescription
					end if
				end try
			end repeat

			missing value
		end getSelectedItemAtIndex


		on _clickMenuAction(menuItemName)
			tell application "System Events" to tell process "zoom.us"
				try
					click menu item menuItemName of menu 1 of menu bar item "Meeting" of menu bar 1
				end try
			end tell
		end _clickMenuAction


		(*
			Will fail when the controls are not visible. Use menus instead for more reliability.
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
