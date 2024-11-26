(*
	@Purpose:
		This decorator contains the handlers that are used around sound settings.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh macOS-version/14-sonoma/control-center_sound

	@Migrated:
		September 25, 2023 11:35 AM
*)

use loggerFactory : script "core/logger-factory"
use kbLib : script "core/keyboard"
use retryLib : script "core/retry"
use ccLib : script "core/control-center"



property logger : missing value
property kb : missing value
property retry : missing value
property cc : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set spotScript to script "core/spot-test"
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Manual: Is Mic In Use (Off, Mic only, Mic and Camera)
		Manual: Switch to AirPods (N/A, Happy, Already Selected)
		Manual: Switch to Default (Happy, Already Selected)
		Manual: WIP: Activate AirPods Noise Cancellation
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

	if caseIndex is 1 then
		logger's infof("Handler Result: {}", sut's isMicInUse())

	else if caseIndex is 2 then
		set switchResult to sut's switchAudioOutput("AirPods Pro")
		logger's infof("Switch Result: {}", switchResult)

	else if caseIndex is 3 then
		set switchResult to sut's switchAudioOutput("MacBook Pro Speakers")
		logger's infof("Switch Result: {}", switchResult)

	else if caseIndex is 4 then
		set sutTarget to "unicorn"
		set sutTarget to "Off" -- Doesn't work, use Transparency instead.
		set sutTarget to "Transparency"
		-- set sutTarget to "Adaptive"
		set sutTarget to "Noise Cancellation"

		logger's debugf("sutTarget: {}", sutTarget)
		set switchResult to sut's switchNoiseControl(sutTarget)


	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


on newSpotBase()
	script SpotBaseInstance
		property template : missing value
		property decorators : missing value
	end script
end newSpotBase


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set kb to kbLib's new()
	set retry to retryLib's new()

	script ControlCenterSoundDecorator
		property parent : mainScript


		(*
			@newValue - Transparency, Adaptive, or Noise Cancellation.  Note that "Off" doesn't work.
		*)
		on switchNoiseControl(newValue)
			_activateControlCenter()
			_activateSoundPane()

			if newValue is "Off" then
				set idx to 3
			else if newValue is "Transparency" then
				set idx to 4
			else if newValue is "Adaptive" then
				set idx to 5
			else if newValue is "Noise Cancellation" then
				set idx to 6
			else
				logger's warnf("{} unrecognized.", newValue)
				return
			end if

			(* Hard-coding checkboxes 2-6. No identifying attribute or ID found. *)
			tell application "System Events" to tell process "ControlCenter"
				try
					click checkbox idx of scroll area 1 of group 1 of window 1
				end try -- AirPods not connected.
			end tell
		end switchNoiseControl


		on isMicInUse()
			(*
			tell application "System Events" to tell process "ControlCenter"
				exists (first menu bar item of menu bar 1 whose description is "Microphone is in use")
			end tell
			*)

			tell application "System Events" to tell process "Control Center"
				set controlCenterDescription to description of first menu bar item of menu bar 1 whose value of attribute "AXAttributedDescription" starts with "Control Center"
			end tell
			controlCenterDescription contains "Camera and microphone are in use" or controlCenterDescription contains "Microphone is in use"
		end isMicInUse


		(* @returns true if the output is found. *)
		on switchAudioOutput(outputName)
			_activateControlCenter()
			_activateSoundPane()

			set clickResult to false
			tell application "System Events" to tell process "ControlCenter"
				set targetCheckbox to first checkbox of scroll area 1 of group 1 of first window whose value of attribute "AXIdentifier" ends with outputName
				set currentState to value of targetCheckbox
				logger's debugf("currentState: {}", currentState)

				if currentState is 0 then
					try
						click targetCheckbox
						set clickResult to true
					end try
				end if
			end tell

			kb's pressKey("esc")
			clickResult
		end switchAudioOutput


		on _activateSoundPane()
			tell application "System Events" to tell process "ControlCenter"
				perform first action of static text "Sound" of group 1 of window "Control Center"
			end tell

			set retry to retryLib's new()
			script SoundPanelWaiter
				tell application "System Events" to tell process "ControlCenter" to tell front window to tell group 1
					if exists (first checkbox of scroll area 1 of group 1 of first window whose value of attribute "AXIdentifier" ends with "MacBook Pro Speakers") then return true
				end tell
			end script
			exec of retry on result for 10 by 0.2
		end _activateSoundPane
	end script
end decorate
