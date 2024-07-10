(*
	NOTE: This script requires accessibility access, grant when prompted.

	The position of the Focus checkbox in the control center pane important.  It must be the 2nd one. (To improve to make it more robust.)

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh macOS-version/14-sonoma/control-center
*)

use unic : script "core/unicodes"
use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"
use kbLib : script "core/keyboard"
use retryLib : script "core/retry"

use spotScript : script "core/spot-test"
use decoratorNetwork : script "core/control-center_network"
use decoratorSound : script "core/control-center_sound"
use decoratorFocus : script "core/control-center_focus"
use decoratorBluetooth : script "core/control-center_bluetooth"
use decoratorWifi : script "core/control-center_wifi"

property logger : missing value
property kb : missing value
property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		NOOP
		Manual: Show Widgets
		DND On
		Manual: DND On - From Work Focus
		DND Off

		Manual: Switch to AirPods (N/A, Happy, Already Selected)
		Manual: Is Mic In Use
		Manual: List of Hotspot (Maybe used to identify your hotpot key, mind the Unicode apostrophe, test no hotspot available)
		Manual: Join Hotspot (Not Joined, Already Joined, Not Found)
		Manual: Join WIFI (Not Joined, Already Joined, Not Found)

		Manual: Activate Control Center
		Manual: Voice Control: Start Listening
		Manual: Voice Control: Stop Listening
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()
	logger's infof("Voice Control is active: {}", sut's isVoiceControlActive())
	logger's infof("Voice Control is Awake: {}", sut's isVoiceControlAwake())

	(* Manually check 3 cases: none, DND On, Other Focus *)

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's showWidgets()

	else if caseIndex is 3 then
		sut's setDoNotDisturbOn()
		logger's infof("New DND Status: {}", sut's getDNDStatus())

	else if caseIndex is 4 then
		sut's setDoNotDisturbOn()
		logger's infof("New DND Status: {}", sut's getDNDStatus())

	else if caseIndex is 5 then
		sut's setDoNotDisturbOff()
		logger's infof("New DND Status: {}", sut's getDNDStatus())

	else if caseIndex is 6 then
		set switchResult to sut's switchAudioOutput("AirPods Pro")
		logger's infof("Switch Result: {}", switchResult)

	else if caseIndex is 7 then
		logger's infof("Handler Result: {}", sut's isMicInUse())

	else if caseIndex is 8 then
		set hotspots to getListOfAvailableHotspot()
		if the number of items in hotspots is 0 then
			logger's info("No hotspot found")
		else
			repeat with nextHotspot in hotspots
				logger's info(nextHotspot)
			end repeat
		end if

	else if caseIndex is 9 then
		(* Toggle below cases. *)
		sut's joinHotspot("iPhone")
		-- joinHotspot("Galaxy")

	else if caseIndex is 10 then
		(* Toggle below cases. *)
		sut's joinHotspot("Care")
		-- joinHotspot("Careless")

	else if caseIndex is 11 then
		sut's _activateControlCenter()

	else if caseIndex is 12 then
		sut's startListening()

	else if caseIndex is 13 then
		sut's stopListening()
	end if

	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's inject(me)
	set kb to kbLib's new()
	set retry to retryLib's new()

	script ControlCenterInstance
		on isCameraInUse()
			tell application "System Events" to tell process "Control Center"
	set controlCenterDescription to description of first menu bar item of menu bar 1 whose value of attribute "AXAttributedDescription" starts with "Control Center"
end tell
controlCenterDescription contains "Camera and microphone are in use" or controlCenterDescription contains "Camera is in use"
		end isCameraInUse


		on isWindowActive()
			tell application "System Events" to tell process "ControlCenter"
				exists window 1
			end tell

		end isWindowActive

		(* Accomplished by clicking on the time in the menu bar items *)
		on showWidgets()
			tell application "System Events" to tell process "ControlCenter"
				try
					click (first menu bar item of first menu bar whose description is "Clock")
				end try
			end tell
		end showWidgets

		(*
			@returns true if Voice Control is active (regardless if listening or not.)
		*)
		on isVoiceControlActive()
			tell application "System Events" to tell process "Control Center"
				exists (first menu bar item of menu bar 1 whose value of attribute "AXAttributedDescription" starts with "Voice Control")
			end tell
		end isVoiceControlActive


		on isVoiceControlAwake()
			tell application "System Events" to tell process "Control Center"
				exists (first menu bar item of menu bar 1 whose value of attribute "AXAttributedDescription" starts with "Voice Control, Awake")
			end tell
		end isVoiceControlAwake


		on isVoiceControlAsleep()
			not isVoiceControlAwake()
		end isVoiceControlAsleep


		(*
			Sets the voice control to listen if it is active.
		*)
		on startListening()
			if not isVoiceControlActive() then return

			tell application "System Events" to tell process "Control Center"
				click (first menu bar item of menu bar 1 whose value of attribute "AXAttributedDescription" starts with "Voice Control")
			end tell

			script EnsureClick
				tell application "System Events" to tell process "Control Center"
					click button 2 of group 1 of window 1 -- No nicer way to click this button other than the index.
				end tell
				true
			end script
			exec of retry on result for 3
		end startListening


		(*
			Sets the voice control to listen if it is active.
		*)
		on stopListening()
			if not isVoiceControlActive() then return

			tell application "System Events" to tell process "Control Center"
				click (first menu bar item of menu bar 1 whose value of attribute "AXAttributedDescription" starts with "Voice Control")
			end tell

			script EnsureClick
				tell application "System Events" to tell process "Control Center"
					click button 1 of group 1 of window 1 -- No nicer way to click this button other than the index.
				end tell
				true
			end script
			exec of retry on result for 3
		end stopListening


		-- Private Codes below =======================================================
		on _activateControlCenter()
			script WindowWaiter
				tell application "System Events" to tell process "ControlCenter"
					if exists window 1 then return true -- Already present.

					click (first menu bar item of menu bar 1 whose value of attribute "AXIdentifier" is "com.apple.menuextra.controlcenter")
					delay 0.1
					exists window 1
				end tell
			end script
			exec of retry on result for 3
		end _activateControlCenter

		on dismissControlCenter()
			tell application "System Events" to tell process "ControlCenter"
				if not (exists window 1) then return -- Already absent.

				click (first menu bar item of menu bar 1 whose value of attribute "AXIdentifier" is "com.apple.menuextra.controlcenter")
			end tell
		end dismissControlCenter

	end script

	decoratorFocus's decorate(result)
	decoratorSound's decorate(result)
	decoratorNetwork's decorate(result)
	decoratorBluetooth's decorate(result)
	decoratorWifi's decorate(result)
end new
