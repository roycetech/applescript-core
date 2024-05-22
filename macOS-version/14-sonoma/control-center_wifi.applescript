(*
	@Purpose:
		This script provides wifi-related functionalities to the control-center library.


	@Version
		14. Sonoma

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh macOS-version/14-sonoma/control-center_wifi

	@Created:
		Tuesday, May 21, 2024 at 10:04:55 PM
*)


use listUtil : script "core/list"
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use loggerLib : script "core/logger"
use kbLib : script "core/keyboard"
use retryLib : script "core/retry"
use uiutilLib : script "core/ui-util"
use ccLib : script "core/control-center"

use spotScript : script "core/spot-test"

property logger : missing value
property kb : missing value
property retry : missing value
property uiUtil : missing value
property cc : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	(*
		Re-run manual tests with the Microphone ON.
	*)
	set cases to listUtil's splitByLine("
		NOOP:
		Turn Off
		Turn On
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	-- activate application ""
	set cc to ccLib's new()
	set sut to decorate(cc)

	logger's infof("WiFi Status: {}", sut's getWiFiStatus())
	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's setWiFiOff()

	else if caseIndex is 3 then
		sut's setWiFiOn()

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

	set kb to kbLib's new()
	set retry to retryLib's new()
	set uiUtil to uiutilLib's new()

	script ControlCenterFocusDecorated
		property parent : mainScript

		(*
			@returns 0 if off, 1 if on, missing value on error.
		*)
		on getWiFiStatus()
			set currentState to 0
			_activateControlCenter()

			set currentState to missing value
			tell application "System Events" to tell process "Control Center"
				try
					set currentState to value of first checkbox of group 1 of front window whose value of attribute "AXIdentifier" is "controlcenter-WiFi"
				on error
					set currentState to missing value
				end try
			end tell

			kb's pressKey("esc")
			currentState
		end getWiFiStatus


		on setWiFiOn()
			_setWiFi(true)
		end setWiFiOn

		on setWiFiOff()
			_setWiFi(false)
		end setWiFiOff


		(*
			Cases:
				Mic is Off
					1.a If Focus UI is unchecked, and new value is true then just click on the focus button.
				Mic is On
					2.a Set to ON
						Activate focus pane
						Get current state
						Click if different

			@newValue boolean true to activate DND, false to deactivate.
		*)
		on _setWiFi(newValue)
			_activateControlCenter()

			tell application "System Events" to tell process "Control Center"
				-- Duplicated code to get current state because the standalone getWiFiStatus method will open and close the control center panel and we want to open and close it only once.
				set currentStatus to value of first checkbox of group 1 of front window whose value of attribute "AXIdentifier" is "controlcenter-wifi"

				if currentStatus is 0 and newValue is false or currentStatus is 1 and newValue is true then
					kb's pressKey("esc")
					return
				end if

				click (first checkbox of group 1 of front window whose value of attribute "AXIdentifier" is "controlcenter-wifi")
			end tell
		end _setWiFi
	end script
end decorate
