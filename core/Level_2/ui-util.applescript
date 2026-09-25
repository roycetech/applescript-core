(*
	@Purpose:
		Inspect a UI. It can more reliably trace the UI hierarchy than UI browser but with manual steps.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/Level_2/ui-util

	@Created: Pre-2024.
	@Last Modified: Friday, Sep 18, 2026 at 8:17 AM

	@Change Logs:
		Sat, Sep 19, 2026 - getElectronContentRoot prefers UI with role "HTML content".
		Fri, Sep 18, 2026 - Added getElectronContentRoot; finders recurse into UI elements.
		Wed, Sep 16, 2026 - Added recursive finders for text fields, static
			texts, and buttons, parameterized by process name.

	TODO: Register 2 new handlers to the Text Expander.
*)
use scripting additions

use std : script "core/std"

use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger", "osascript"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()
	
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitAndTrimParagraphs("
		Manual: Find By ID - not found
		Manual: Find By ID - found
		Manual: Find Containing ID - found
		Manual: Print Attributes
		Manual: Find element with attribute
		
		Manual: Find element with attribute list containing
		Manual: Find all text fields
		Manual: Find all static texts
		Manual: Find all buttons
		Manual: Find HTML Content
		
		Manual: Find static text by value
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
		
	else if caseIndex is 7 then
		set appName to "Cursor"
		set rootUI to sut's getElectronContentRoot(appName, missing value)
		set foundFields to sut's findAllTextFields(appName, rootUI)
		sut's logUiElements("text fields/areas", foundFields)
		
	else if caseIndex is 8 then
		set appName to "Script Editor"
		tell application "System Events" to tell process appName
			set startElement to front window
		end tell
		set foundStaticTexts to sut's findAllStaticTexts(appName, startElement, missing value)
		sut's logUiElements("static texts", foundStaticTexts)
		
	else if caseIndex is 9 then
		set appName to "Script Editor"
		tell application "System Events" to tell process appName
			set startElement to front window
		end tell
		set foundButtons to sut's findAllButtons(appName, startElement, missing value)
		sut's logUiElements("buttons", foundButtons)
		
	else if caseIndex is 10 then
		set appName to "Cursor"
		set appName to "Claude"
		set appName to "Slack"
		logger's debugf("appName: {}", appName)
		
		set rootUI to sut's getElectronContentRoot(appName, missing value)
		logger's infof("root UI found?: {}", rootUI is not missing value)
		
	else if caseIndex is 11 then
		set appName to "Cursor"
		set appName to "Script Editor"
		-- set rootUI to sut's getElectronContentRoot(appName, missing value)
		tell application "System Events" to tell process appName
			set rootUI to front window
		end tell
		(* 
		set allStaticTexts to sut's findAllStaticTexts(appName, startElement, missing value)
		assertThat of std given condition:(count of allStaticTexts) > 0, messageOnFail:"No static texts in Script Editor front window"
		tell application "System Events" to tell process appName
			set valueWanted to value of (item 1 of allStaticTexts) as text
		end tell
		*)
		set valueWanted to "Agent"
		set valueWanted to "ui-util.applescript"
		
		set foundStaticTexts to sut's findAllStaticTexts(appName, rootUI, valueWanted)
		assertThat of std given condition:(count of foundStaticTexts) > 0, messageOnFail:"Failed spot check"
		
		logger's infof("valueWanted: {}", valueWanted)
		sut's logUiElements("static texts", foundStaticTexts)
		
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
		end printUIElements
		
		
		on logUiElements(labelText, uiElements)
			log "Found " & (count of uiElements) & " " & labelText
			repeat with nextElement in uiElements
				tell application "System Events"
					try
						set elementClass to class of nextElement as text
					on error
						set elementClass to "?"
					end try
					try
						set elementDesc to description of nextElement
					on error
						set elementDesc to ""
					end try
					try
						set elementName to name of nextElement
					on error
						set elementName to ""
					end try
					try
						set elementValue to value of nextElement
					on error
						set elementValue to ""
					end try
					log elementClass & " | " & elementDesc & " | " & elementName & " | " & elementValue
				end tell
			end repeat
		end logUiElements
		
		
		(*
			Electron / Chromium apps expose the page under a UI element whose
			role description is "HTML content". Falls back to the first nested
			UI element after group 1 wrappers when that role is absent.

			@appName - System Events process name, e.g. "Cursor", "Claude", "zoom.us"
			@windowRef - optional window reference; default is front window
			@returns UI element reference, or missing value
		*)
		on getElectronContentRoot(appName, windowRef)
			tell application "System Events" to tell process appName
				if windowRef is missing value then
					if (count of windows) is 0 then return missing value
					set uicontainer to front window
				else
					set uicontainer to windowRef
				end if
			end tell
			
			set htmlRoot to my _findUiWithRoleDescription(appName, uicontainer, "HTML content")
			if htmlRoot is not missing value then return htmlRoot
			
			tell application "System Events" to tell process appName
				repeat 20 times
					try
						if (count of UI elements of uicontainer) > 0 then return UI element 1 of uicontainer
					end try
					
					try
						if (count of groups of uicontainer) is 0 then exit repeat
						set uicontainer to group 1 of uicontainer
					on error
						exit repeat
					end try
				end repeat
			end tell
			
			missing value
		end getElectronContentRoot
		
		
		on _findUiWithRoleDescription(appName, uicontainer, roleDescriptionText)
			tell application "System Events" to tell process appName
				try
					if (role description of uicontainer as text) is roleDescriptionText then return contents of uicontainer
				end try
				
				try
					repeat with nextGroup in groups of uicontainer
						set found to my _findUiWithRoleDescription(appName, contents of nextGroup, roleDescriptionText)
						if found is not missing value then return found
					end repeat
				end try
				
				try
					repeat with nextScroll in scroll areas of uicontainer
						set found to my _findUiWithRoleDescription(appName, contents of nextScroll, roleDescriptionText)
						if found is not missing value then return found
					end repeat
				end try
				
				try
					repeat with nextSplitter in splitter groups of uicontainer
						set found to my _findUiWithRoleDescription(appName, contents of nextSplitter, roleDescriptionText)
						if found is not missing value then return found
					end repeat
				end try
				
				try
					repeat with nextUIElement in UI elements of uicontainer
						set found to my _findUiWithRoleDescription(appName, contents of nextUIElement, roleDescriptionText)
						if found is not missing value then return found
					end repeat
				end try
			end tell
			
			missing value
		end _findUiWithRoleDescription
		
		
		(*
			Collects all nested text fields and text areas. Recurses into groups,
			scroll areas, splitter groups, and UI elements.

			@appName - System Events process name, e.g. "Cursor", "Claude", "zoom.us"
		*)
		on findAllTextFields(appName, uicontainer)
			set collected to {}
			
			tell application "System Events" to tell process appName
				try
					repeat with nextTextField in text fields of uicontainer
						set end of collected to contents of nextTextField
					end repeat
				end try
				
				try
					repeat with nextTextArea in text areas of uicontainer
						set end of collected to contents of nextTextArea
					end repeat
				end try
			end tell
			
			my _collectFromChildContainers(appName, uicontainer, collected, "findAllTextFields", missing value)
		end findAllTextFields
		
		
		(*
			@valueMatch - exact static text value, or missing value for all
		*)
		on findAllStaticTexts(appName, uicontainer, valueMatch)
			set collected to {}
			
			tell application "System Events" to tell process appName
				try
					repeat with nextStaticText in static texts of uicontainer
						set staticTextRef to contents of nextStaticText
						if my _staticTextMatchesValue(appName, staticTextRef, valueMatch) then set end of collected to staticTextRef
					end repeat
				end try
			end tell
			
			my _collectFromChildContainers(appName, uicontainer, collected, "findAllStaticTexts", valueMatch)
		end findAllStaticTexts
		
		
		on _staticTextMatchesValue(appName, uiElement, valueMatch)
			if valueMatch is missing value then return true
			
			tell application "System Events" to tell process appName
				try
					return (value of uiElement as text) is valueMatch
				on error
					return false
				end try
			end tell
		end _staticTextMatchesValue
		
		
		(*
			Collects nested buttons, radio buttons, and checkboxes.

			@appName - System Events process name
			@titleMatch - exact button title, or missing value for all
		*)
		on findAllButtons(appName, uicontainer, titleMatch)
			set collected to {}
			
			tell application "System Events" to tell process appName
				try
					repeat with nextButton in buttons of uicontainer
						set buttonRef to contents of nextButton
						if my _buttonMatchesTitle(appName, buttonRef, titleMatch) then set end of collected to buttonRef
					end repeat
				end try
				
				try
					repeat with nextRadio in radio buttons of uicontainer
						set radioRef to contents of nextRadio
						if my _buttonMatchesTitle(appName, radioRef, titleMatch) then set end of collected to radioRef
					end repeat
				end try
				
				try
					repeat with nextCheckbox in checkboxes of uicontainer
						set checkboxRef to contents of nextCheckbox
						if my _buttonMatchesTitle(appName, checkboxRef, titleMatch) then set end of collected to checkboxRef
					end repeat
				end try
			end tell
			
			my _collectFromChildContainers(appName, uicontainer, collected, "findAllButtons", titleMatch)
		end findAllButtons
		
		
		on _buttonMatchesTitle(appName, uiElement, titleMatch)
			if titleMatch is missing value then return true
			
			tell application "System Events" to tell process appName
				try
					return (title of uiElement as text) is titleMatch
				on error
					return false
				end try
			end tell
		end _buttonMatchesTitle
		
		
		on _collectFromChildContainers(appName, uicontainer, collected, finderName, filterMatch)
			tell application "System Events" to tell process appName
				try
					repeat with nextGroup in groups of uicontainer
						set collected to collected & my _runFinder(finderName, appName, contents of nextGroup, filterMatch)
					end repeat
				end try
				
				try
					repeat with nextScroll in scroll areas of uicontainer
						set collected to collected & my _runFinder(finderName, appName, contents of nextScroll, filterMatch)
					end repeat
				end try
				
				try
					repeat with nextSplitter in splitter groups of uicontainer
						set collected to collected & my _runFinder(finderName, appName, contents of nextSplitter, filterMatch)
					end repeat
				end try
				
				try
					repeat with nextUIElement in UI elements of uicontainer
						set collected to collected & my _runFinder(finderName, appName, contents of nextUIElement, filterMatch)
					end repeat
				end try
			end tell
			
			collected
		end _collectFromChildContainers
		
		
		on _runFinder(finderName, appName, uicontainer, filterMatch)
			if finderName is "findAllTextFields" then
				return findAllTextFields(appName, uicontainer)
			else if finderName is "findAllStaticTexts" then
				return findAllStaticTexts(appName, uicontainer, filterMatch)
			else if finderName is "findAllButtons" then
				return findAllButtons(appName, uicontainer, filterMatch)
			end if
			
			{}
		end _runFinder
		
		
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
