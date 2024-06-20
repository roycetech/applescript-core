(*
	@Purpose:
		Inspect a UI. It can more reliably trace the UI hierarchy than UI browser but with manual steps.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/ui-util

	@Created: Pre-2024.
	@Last Modified: 2024-06-13 14:02:29
*)
use std : script "core/std"

use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"

use spotScript : script "core/spot-test"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Find By ID - not found
		Manual: Find By ID - found
		Manual: Find Containing ID - found
		Manual: Print Attributes
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if


	tell application "System Events" to tell process "Safari"
		set uiButtons to buttons of group 1 of toolbar 1 of front window
	end tell
	set sut to new()

	if caseIndex is 1 then
		tell application "System Events" to tell process "Control Center"
			assertThat of std given condition:sut's findUiWithIdAttribute(menu bar item 2 of menu bar 1, "x") is missing value, messageOnFail:"Failed spot check"
		end tell

	else if caseIndex is 2 then
		tell application "System Events" to tell process "Control Center"
			assertThat of std given condition:sut's findUiWithIdAttribute(menu bar item 2 of menu bar 1, "com.apple.menuextra.controlcenter") is not missing value, messageOnFail:"Failed spot check"
		end tell

	else if caseIndex is 3 then
		-- Activate Control Center
		tell application "System Events" to tell process "ControlCenter"
			try
				click (first menu bar item of menu bar 1 whose value of attribute "AXIdentifier" is "com.apple.menuextra.controlcenter")
			end try
		end tell

		tell application "System Events" to tell process "Control Center"
			log sut's findUiContainingIdAttribute(UI elements of group 1 of front window, "controlcenter-focus-modes") is not missing value
		end tell

	else if caseIndex is 4 then
		tell application "System Events" to tell process "Control Center"
			sut's printAttributeValues(menu bar item 2 of menu bar 1)
		end tell
	end if
	logger's info("Passed.")

	spot's finish()
	logger's finish()
end spotCheck


on new()
	script UiUtilInstance
		(*
			Use this when the usual format fails. e.g. 'first static text of group 1 of splitter group 1 of front window whose value of attribute "AXIdentifier" is "notes-field"'

			@returns the UI with the matched attribute or missing value.
		*)
		on findUiWithIdAttribute(uiList, idAttribute)
			tell application "System Events"
				repeat with nextUIElement in uiList
					try
						set uiId to value of attribute "AXIdentifier" of nextUIElement
						if uiId is equal to the idAttribute then return nextUIElement
					end try
				end repeat
			end tell

			missing value
		end findUiWithIdAttribute

		(*
			Derived from findUiWithIdAttribute as a fix for Apple bug where the
			AXIdentifier value is doubled (e.g. controlcenter-focus-modes-controlcenter-focus-modes),

			@returns the UI with the matched attribute or missing value.
		*)
		on findUiContainingIdAttribute(uiList, idAttributeKeyword)
			tell application "System Events"
				repeat with nextUIElement in uiList
					try
						set uiId to value of attribute "AXIdentifier" of nextUIElement
						if uiId contains the idAttributeKeyword then return nextUIElement
					end try
				end repeat
			end tell

			missing value
		end findUiContainingIdAttribute


		on printAttributeValues(uiElement)
			tell application "System Events"

				set attrList to attributes of uiElement
				repeat with nextAttribute in attrList
					try
						log "Name: " & name of nextAttribute & ", Value: " & value of nextAttribute
					end try
				end repeat
			end tell

		end printAttributeValues


		on printUIElements(sourceElement, padding)
			if sourceElement is missing value then return

			tell application "System Events"
				repeat with nextElement in UI elements of sourceElement
					try
						set className to class of nextElement
						set uiDesc to the description of nextElement
						set uiRole to role description of nextElement
						set elementValue to ""
						if className is text field then set elementValue to ":" & value of nextElement

						log padding & className & ": " & uiDesc & ": " & uiRole & elementValue
					end try
					my printUIElements(nextElement, padding & "  ")
				end repeat
			end tell
		end printUIElements
	end script
end new
