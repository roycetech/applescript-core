(*
	@Purpose:
		This script provides focus-related functionalities to the control-center library.


	@Version
		13. Ventura

	Possible focus IDs
		focus-mode-activity-com.apple.donotdisturb.mode.default
		focus-mode-activity-com.apple.focus.work
		focus-mode-activity-com.apple.sleep.sleep-mode
		focus-mode-activity-com.apple.donotdisturb.mode.stethoscope
		focus-mode-activity-com.apple.donotdisturb.mode.emoji.face.grinning
		focus-mode-activity-com.apple.donotdisturb.mode.driving

	@Project:
		applescript-core

	@Build:
		make build-control-center

	@Created:
		2023
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
		Manual: DND Status( ON, OFF, Other Focus)
		Manual: DND On (Off, On, From Work Focus)
		Manual: DND Off (Off, On, From Work Focus)
		Manual: Switch Focus (DND Off, DND On, Happy, Not Found)
		Manual: Activate Focus Pane (Mic on/off)
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
		logger's infof("DND Status: {}", sut's getDNDStatus())
		delay 0.4 -- Allow dismiss transition, 0.2 fails intermittently.
		logger's infof("Current Focus Keyword: {}", sut's getCurrentFocusKeyword())
		logger's infof("Mic is active: {}", sut's _isMicrophoneActive())

	else if caseIndex is 2 then
		sut's setDoNotDisturbOn()

	else if caseIndex is 3 then
		sut's setDoNotDisturbOff()

	else if caseIndex is 4 then
		(* Only one focus case must be active at a time. *)
		-- sut's setFocus("Not Found")
		sut's setFocus("donotdisturb.mode.driving")

	else if caseIndex is 5 then
		sut's _activateControlCenter()
		sut's _activateFocusPane()
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

		on getDNDStatus()
			set currentState to 0
			_activateControlCenter()

			set currentState to missing value
			if not _isMicrophoneActive() then
				tell application "System Events" to tell process "ControlCenter"
					set currentState to the value of first checkbox of group 1 of front window whose value of attribute "AXIdentifier" is "controlcenter-focus-modes"
				end tell
			end if

			if currentState is missing value then
				_activateFocusPane()

				tell application "System Events" to tell process "ControlCenter" to tell front window to tell group 1
					set currentState to value of first checkbox whose value of attribute "AXIdentifier" is "focus-mode-activity-com.apple.donotdisturb.mode.default"
				end tell
			end if

			-- if exists (first checkbox of front window whose title is "Do Not Disturb") then set currentState to 1
			kb's pressKey("esc")
			currentState
		end getDNDStatus


		on getCurrentFocusKeyword()
			set currentFocus to missing value
			_activateControlCenter()
			_activateFocusPane()

			tell application "System Events" to tell process "ControlCenter" to tell front window to tell group 1
				try
					set checkedCheckbox to first checkbox whose value is 1
					-- uiUtil's printAttributeValues(checkedCheckbox)
					set currentFocusRaw to value of attribute "AXIdentifier" of checkedCheckbox
					-- logger's debugf("currentFocusRaw: {}", currentFocusRaw)
					set currentFocus to textUtil's stringAfter(currentFocusRaw, "focus-mode-activity-com.apple.")
				end try
			end tell

			kb's pressKey("esc")
			currentFocus
		end getCurrentFocusKeyword


		on setFocus(focusId)
			_activateControlCenter()
			_activateFocusPane()

			tell application "System Events" to tell process "ControlCenter" to tell front window to tell group 1
				try
					set targetUi to first checkbox whose value of attribute "AXIdentifier" contains focusId
					set currentValue to the value of targetUi
					if currentValue is 0 then
						click targetUi
						delay 0.1 -- Fails without this delay
					else
						logger's infof("{} is already selected", focusId)
					end if
				end try
			end tell

			kb's pressKey("esc")
		end setFocus


		on setDoNotDisturbOn()
			_setDoNotDisturb(true)

		end setDoNotDisturbOn

		on setDoNotDisturbOff()
			_setDoNotDisturb(false)
		end setDoNotDisturbOff


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
		on _setDoNotDisturb(newValue)
			_activateControlCenter()

			set currentState to 1
			-- set focusUi to first UI element whose value of attribute "AXIdentifier" is "controlcenter-focus-modes" -- fails to work, that's why we manually iterate instead.
			tell application "System Events" to tell process "ControlCenter"
				set focusUi to uiUtil's findUiContainingIdAttribute(UI elements of group 1 of front window, "controlcenter-focus-modes")

				assertThat of std given condition:focusUi is not missing value, messageOnFail:"focusUi is missing value"

				-- set currentFocusId to value of attribute "AXIdentifier" of second checkbox
				-- uiUtil's printAttributeValues(focusUi)

				set focusUiRole to value of attribute "AXRole" of focusUi -- AXButton or AXCheckBox
				if focusUiRole is "AXCheckBox" then
					set currentState to value of focusUi
					logger's debugf("_setDoNotDisturb currentState: {}", currentState)
					logger's debugf("newValue: {}", newValue)
					set changeRequested to currentState is 0 and newValue or currentState is 1 and newValue is false
					logger's debugf("changeRequested: {}", changeRequested)
					if changeRequested then
						click focusUi
					end if

				else -- Mic Active
					my _activateFocusPane()
					set dndOption to first checkbox of group 1 of front window whose value of attribute "AXIdentifier" is "focus-mode-activity-com.apple.donotdisturb.mode.default"
					set currentState to value of dndOption
					set changeRequested to currentState is 0 and newValue or currentState is 1 and newValue is false
					if changeRequested then
						click dndOption
					end if

				end if

				kb's pressKey("esc")
			end tell
		end _setDoNotDisturb


		on _isMicrophoneActive()
			tell application "System Events" to tell process "ControlCenter"
				(description of first menu bar item of menu bar 1 whose value of attribute "AXIdentifier" contains "com.apple.menuextra.controlcenter") is "Microphone is in use"
			end tell
		end _isMicrophoneActive

		(*
			TOFIX:
			While the Control Center is already visible, it moves to the Focus pane by triggering the "Show Details" of the Focus check box
		*)
		on _activateFocusPane()
			tell application "System Events" to tell process "ControlCenter"
				set focusUi to uiUtil's findUiContainingIdAttribute(UI elements of group 1 of front window, "controlcenter-focus-modes")

				set focusUiRole to value of attribute "AXRole" of focusUi -- AXButton or AXCheckBox

				if focusUiRole is "AXButton" then
					perform action 1 of focusUi
				else
					perform action 2 of focusUi
				end if

				-- Below does not always work.
				-- perform action 2 of (first UI element of group 1 of front window whose value of attribute "AXIdentifier" contains "controlcenter-focus-modes")
			end tell

			set retry to retryLib's new()
			script FocusPanelWaiter
				tell application "System Events" to tell process "ControlCenter" to tell front window to tell group 1
					if exists (first checkbox whose value of attribute "AXIdentifier" is "focus-mode-activity-com.apple.donotdisturb.mode.default") then return true
				end tell
			end script
			exec of retry on result for 10 by 0.2
		end _activateFocusPane
	end script
end decorate
