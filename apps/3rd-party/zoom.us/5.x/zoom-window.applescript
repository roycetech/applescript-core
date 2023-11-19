(*
	Provides handlers about the meeting window.

	@Last Modified: 2023-11-10 10:16:24

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/zoom.us/5.x/zoom-window
*)

use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"
use usrLib : script "core/user"
use zoomUtilLib : script "core/zoom"

use spotScript : script "core/spot-test"

property usr : missing value
property logger : missing value
property zoomUtil : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Close Home Window (Screen Sharing/Non Sharing)
		Manual: Toggle Always on Top
		Manual: Turn On Always on Top
		Manual: Turn Off Always on Top
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
		sut's closeHomeWindow()

	else if caseIndex is 2 then
		sut's toggleAlwaysOnTop()

	else if caseIndex is 3 then
		sut's turnOnAlwaysOnTop()

	else if caseIndex is 4 then
		sut's turnOffAlwaysOnTop()

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

	script ZoomInstance
		property parent : mainScript

		(* POC, use the closeHomeWindow for now. *)
		on closeNonMeetingWindows()
			tell application "System Events" to tell process "zoom.us"
				-- click (first button of (windows whose subrole is "AXDialog") whose description is "Close") -- Don't do this, will result in closing the meeting window as well.


			end tell

			closeHomeWindow()
		end closeNonMeetingWindows

		(*
			NOTES:
				No need to activate the zoom app.
				Find the window with the home button, this is a tab bar.
				There will be 2 windows whose title is "Zoom", one contains "Home" button, and we want to close this window.
		*)
		on closeHomeWindow()
			if not running of application "zoom.us" then
				logger's debug("closeHomeWindow: zoom.us app is not running")
				return
			end if

			tell application "System Events" to tell process "zoom.us"
				set found to false
				repeat with nextWindow in (every window whose title is "Zoom")
					try
						set theSplitterGroup to first splitter group of nextWindow -- does not work
						if exists (first button of nextWindow whose value starts with "Home") then
							click (first button of nextWindow whose description is "close button")
							set found to true
							exit repeat
						end if
					end try
				end repeat

				if found then
					logger's debug("Zoom Home window was found and closed.")
					return
				end if

				logger's debug("The Zoom home window was not found")
			end tell
		end closeHomeWindow


		on turnOnAlwaysOnTop()
			if not running of application "zoom.us" then return

			if not running of application "zoom.us" then return

			tell application "System Events" to tell process "zoom.us"
				try
					if value of attribute "AXMenuItemMarkChar" of menu item "Keep on Top" of menu 1 of menu bar item "Meeting" of menu bar 1 is missing value then
						my toggleAlwaysOnTop()
					else
						logger's info("Keey on Top is already active")
					end if
				on error the errorMessage number the errorNumber
					logger's warn(errorMessage)
				end try
			end tell
		end turnOnAlwaysOnTop


		on turnOffAlwaysOnTop()
			if not running of application "zoom.us" then return

			tell application "System Events" to tell process "zoom.us"
				try
					if value of attribute "AXMenuItemMarkChar" of menu item "Keep on Top" of menu 1 of menu bar item "Meeting" of menu bar 1 is not missing value then
						my toggleAlwaysOnTop()
					else
						logger's info("Keey on Top is already inactive")
					end if
				on error the errorMessage number the errorNumber
					logger's warn(errorMessage)
				end try
			end tell
		end turnOffAlwaysOnTop


		on toggleAlwaysOnTop()
			if not running of application "zoom.us" then return false

			tell application "System Events" to tell process "zoom.us"
				try
					click menu item "Keep on Top" of menu 1 of menu bar item "Meeting" of menu bar 1
				end try
			end tell
		end toggleAlwaysOnTop
	end script
end decorate
