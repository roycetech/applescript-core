(*
	@Purpose:
		Inspect a UI. It can more reliably trace the UI hierarchy than UI browser but with manual steps.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/Level_3/ui-util

	@Created: Pre-2024.
	@Last Modified: 2024-12-04 07:45:30

	TODO: Register 2 new handlers to the Text Expander.
*)
use std : script "core/std"

use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Manual: Find By ID - not found
		Manual: Find By ID - found
		Manual: Find Containing ID - found
		Manual: Print Attributes
		Manual: Find element with attribute

		Manual: Find element with attribute list containing
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if


	tell application "System Events" to tell process "Safari"
		if (count of windows) is not 0 then
			set uiButtons to buttons of group 1 of toolbar 1 of front window
		end if
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

	else if caseIndex is 5 then

	else if caseIndex is 6 then
		set appName to "Google Chrome"
		tell application "System Events" to tell process appName
			sut's findUiWithAttributeContaining(groups of group 1 of group 1 of group 1 of group 1 of UI element "DevTools" of group 1 of group 1 of group 1 of group 1 of front window, "AXDOMClassList", "shadow-split-widget-sidebar")
		end tell

	end if
	logger's info("Passed.")

	spot's finish()
	logger's finish()
end spotCheck


on new()
	script UiUtilInstance
		on findUiWithAttribute(uiList, attributeName, targetAttribute)
			tell application "System Events"
				repeat with nextUIElement in uiList
					try
						set nextAttributeValue to value of attribute attributeName of nextUIElement
						if nextAttributeValue as text is equal to the targetAttribute then return nextUIElement
					end try
				end repeat
			end tell

			missing value
		end findUiWithAttribute


		on findUiWithAttributeContaining(uiList, listAttributeName, targetAttribute)
			tell application "System Events"
				repeat with nextUIElement in uiList
					try
						set nextAttributeList to value of attribute listAttributeName of nextUIElement
						if listUtil's listContains(nextAttributeList, targetAttribute) then return nextUIElement
					end try
				end repeat
			end tell

			missing value
		end findUiWithAttributeContaining

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


		on printUIElements(sourceElement)
			_printUIElements(sourceElement, "")
		end


		on _printUIElements(sourceElement, padding)
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
					my _printUIElements(nextElement, padding & "  ")
				end repeat
			end tell
		end _printUIElements
	end script
end new
