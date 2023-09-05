(*
	Update the following quite obvious if you read through the template code.:
	spotCheck()
		thisCaseId
		base library instantiation

		logger constructor parameter inside init handler

	decorate()
		instance name
		handler name

*)

use listUtil : script "list"

use loggerLib : script "logger"
use kbLib : script "keyboard"
use retryLib : script "retry"
use ccLib : script "control-center"

use spotScript : script "core/spot-test"

property logger : loggerLib's new("control-center_sound")
property kb : kbLib's new()
property retry : retryLib's new()
property cc : ccLib's new()

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Is Mic In Use
		Manual: Switch to AirPods (N/A, Happy, Already Selected)
		Manual: Switch to Default (Happy, Already Selected)
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	-- activate application ""
	set sut to decorate(cc)

	if caseIndex is 1 then
		logger's infof("Handler Result: {}", sut's isMicInUse())

	else if caseIndex is 2 then
		set switchResult to sut's switchAudioOutput("AirPods Pro")
		logger's infof("Switch Result: {}", switchResult)

	else if caseIndex is 3 then
		set switchResult to sut's switchAudioOutput("MacBook Pro Speakers")
		logger's infof("Switch Result: {}", switchResult)

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
	script ControlCenterSoundDecorated
		property parent : mainScript
		property decorators : []

		on isMicInUse()
			tell application "System Events" to tell process "ControlCenter"
				exists (first menu bar item of menu bar 1 whose description is "Microphone is in use")
			end tell
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

	if the decorators of mainScript is missing value then
		set mainScript's decorators to []
	end if
	set ControlCenterSoundDecorated's decorators to listUtil's clone(mainScript's decorators)
	set the end of ControlCenterSoundDecorated's decorators to the name of ControlCenterSoundDecorated

	ControlCenterSoundDecorated
end decorate
