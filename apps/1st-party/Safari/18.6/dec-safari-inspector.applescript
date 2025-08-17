(*
	@Purpose:
		Web inspector handlers. Decorates SafariInstance.

	NOTE:
		Re-activate the Develop in the menu by going to the Settings > Advanced > check the "Show features for web developers"

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/18.6/dec-safari-inspector

	@Created: Thu, Feb 27, 2025 at 11:42:33 AM
	@Last Modified: 2025-08-12 15:27:34
	@Change Logs:

	@References:
		https://support.apple.com/en-ph/guide/safari/sfri20948/mac

	@TODO:
		Update the Set Up AppleScript to configure the Develop menu to show.
*)
use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"
use retryLib : script "core/retry"

property logger : missing value
property kb : missing value
property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Manual: Info only
		Manual: Show Web Inspector
		Manual: Close Web Inspector
		Manual: Dock (left, bottom, right, float)
		Manual: Clear Console

		Manual: Switch Tab
		Manual: Run JavaScript via Inspector
		Manual: Select First Storage Row (Cookie)
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	activate application "Safari"
	set sutLib to script "core/safari"
	set sut to sutLib's new()
	set sut to decorate(sut)


	tell application "System Events" to tell process "Safari"
		if not (exists menu bar item "Develop" of menu bar 1) then
			error "You must enable the Develop menu from the Safari Settings"
		end if
	end tell

	logger's infof("Is inspector active: {}", sut's isInspectorPanelActive())
	logger's infof("Is inspector floating: {}", sut's isInspectorFloating())
	set currentInspectorTabName to sut's getInspectorTabName()
	logger's infof("Inspector tab name: {}", currentInspectorTabName)
	if currentInspectorTabName is "Storage" then
		logger's infof("Cookie name: {}", sut's getFirstCookieName())
		logger's infof("Cookie value: {}", sut's getFirstCookieValue())
	end if


	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's openWebInspector()

	else if caseIndex is 3 then
		sut's closeWebInspector()

	else if caseIndex is 4 then
		set region to "left"
		set region to "right"
		set region to "bottom"
		-- set region to "float"
		logger's debugf("region: {}", region)
		sut's dockWebInspector(region)

	else if caseIndex is 5 then
		sut's clearConsole()

	else if caseIndex is 6 then
		set tabName to "unicorn"
		-- set tabName to "Sources"
		set tabName to "Console"
		set tabName to "Storage"
		set tabName to "Elements"

		logger's debugf("tabName: {}", tabName)
		sut's switchInspectorTab(tabName)

	else if caseIndex is 7 then
		sut's runJavaScriptViaInspector("console.log(1)")

	else if caseIndex is 8 then
		sut's selectFirstStorageRow()
	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set kb to kbLib's new()
	set retry to retryLib's new()

	script SafariInspectorDecorator
		property parent : mainScript
		property waitSecondsAfterRunViaJavaScriptViaInspector : 0

		on runJavaScriptViaInspector(javaScriptCode)
			if running of application "Safari" is false then return

			if not isInspectorPanelActive() then
				openWebInspector()
			end if
			focusInspectorPrompt()

			-- kb's typeText(javaScriptCode)  -- Couldn't type the ';' with #runJavaScriptViaInspector
			kb's insertTextByPasting(javaScriptCode)
			kb's pressKey(return)
			delay waitSecondsAfterRunViaJavaScriptViaInspector
		end runJavaScriptViaInspector


		on focusInspectorPrompt()
			if running of application "Safari" is false then return

			tell application "System Events" to tell process "Safari"
				set frontmost to true
			end tell

			kb's pressCommandOptionKey("c")
		end focusInspectorPrompt


		(*
			Cases: Floating panel
		*)
		on isInspectorPanelActive()
			if running of application "Safari" is false then return false

			tell application "System Events" to tell process "Safari"
				exists menu item "Close Web Inspector" of menu 1 of menu bar item "Develop" of menu bar 1
			end tell
		end isInspectorPanelActive

		on openWebInspector()
			if running of application "Safari" is false then return

			script InspectorWaiter
				tell application "System Events" to tell process "Safari"
					set frontmost to true
					try
						click menu item "Show Web Inspector" of menu 1 of menu bar item "Develop" of menu bar 1
					end try
				end tell
				if isInspectorPanelActive() then return true
			end script
			exec of retry on result for 3
		end openWebInspector


		on closeWebInspector()
			if running of application "Safari" is false then return

			script CloseWaiter
				tell application "System Events" to tell process "Safari"
					set frontmost to true
					click menu item "Close Web Inspector" of menu 1 of menu bar item "Develop" of menu bar 1
				end tell
				if not isInspectorPanelActive() then return true
			end script
			exec of retry on result for 3
		end closeWebInspector

		on isInspectorFloating()
			if running of application "Safari" is false then return false

			tell application "System Events" to tell process "Safari"
				exists (first window whose title starts with "Web Inspector")
			end tell
		end isInspectorFloating

		(*
			@location - left, bottom, right, float
		*)
		on dockWebInspector(region)
			(*
				Note: UI Elements position varies when inspector is floating or not, thus the checks.
			*)
			set targetWindow to missing value
			set isFloating to isInspectorFloating()
			if isFloating and {"float", "detach"} contains region then return

			tell application "System Events" to tell process "Safari"
				if isFloating then
					set targetWindow to first window whose title starts with "Web Inspector"

				else
					try
						set targetWindow to first window whose title is not ""
					end try
				end if
			end tell
			if targetWindow is missing value then return

			tell application "System Events" to tell process "Safari"
				if isFloating then
					set targetUIElement to UI element 1 of scroll area 1 of group 1 of group 1 of targetWindow
				else
					set targetUIElement to UI element 1 of scroll area 1 of group 1 of group 1 of tab group 1 of splitter group 1 of targetWindow
				end if

				try
					if region is "left" then
						click (first button of targetUIElement whose description starts with "Dock to left")
					else if region is "right" then
						click (first button of targetUIElement whose description starts with "Dock to right")
					else if region is "bottom" then
						click (first button of targetUIElement whose description starts with "Dock to bottom")
					else if {"float", "detach"} contains region then
						click (first button of targetUIElement whose description contains "detach")
					end if
				end try
			end tell
		end dockWebInspector


		on getInspectorTabName()
			if running of application "Safari" is false then return missing value
			if not isInspectorPanelActive() then return missing value

			tell application "System Events" to tell process "Safari"
				title of first radio button of tab group 1 of UI element 1 of scroll area 1 of group 1 of group 1 of tab group 1 of splitter group 1 of front window whose value is true
			end tell
		end getInspectorTabName


		on switchInspectorTab(tabName)
			if running of application "Safari" is false then return

			set inspectorContainer to _getInspectorContainer()
			if inspectorContainer is missing value then return

			tell application "System Events" to tell process "Safari"
				try
					click radio button tabName of tab group 1 of inspectorContainer
				end try -- Ignore invalid tabName
			end tell
		end switchInspectorTab


		on selectFirstStorageRow()
			if running of application "Safari" is false then return

			tell application "System Events" to tell process "Safari"
				try
					-- set selected of row 1 of outline 1 of group "Storage" of group "Navigation" of group "Storage" of UI element 1 of scroll area 1 of group 1 of group 1 of tab group 1 of splitter group 1 of front window to true   -- Didn't work.
					click row 1 of outline 1 of group "Storage" of group "Navigation" of group "Storage" of UI element 1 of scroll area 1 of group 1 of group 1 of tab group 1 of splitter group 1 of front window
				end try
			end tell
		end selectFirstStorageRow


		on getFirstCookieName()
			if running of application "Safari" is false then return missing value
			if getInspectorTabName() is not "Storage" then return missing value

			tell application "System Events" to tell process "Safari"
				try
					return value of static text 1 of group 1 of group 3 of group 3 of group "Storage" of UI element 1 of scroll area 1 of group 1 of group 1 of tab group 1 of splitter group 1 of front window
				end try
			end tell
			missing value
		end getFirstCookieName


		on getFirstCookieValue()
			if running of application "Safari" is false then return missing value
			if getInspectorTabName() is not "Storage" then return missing value

			tell application "System Events" to tell process "Safari"
				try
					return value of static text 2 of group 1 of group 3 of group 3 of group "Storage" of UI element 1 of scroll area 1 of group 1 of group 1 of tab group 1 of splitter group 1 of front window
				end try
			end tell
			missing value
		end getFirstCookieValue


		on clearConsole()
			if running of application "Safari" is false then return

			switchInspectorTab("Console")

			set inspectorContainer to _getInspectorContainer()
			if inspectorContainer is missing value then
				logger's debug("Inspector container was not found, exiting...")
				return
			end if

			tell application "System Events" to tell process "Safari"
				try
					set consoleGroup to the first group of inspectorContainer whose description is "Console"
				on error
					logger's debug("Console group was not found, exiting...")
					return missing value
				end try
			end tell

			tell application "System Events" to tell process "Safari"
				try
					click (first button of consoleGroup whose description starts with "Clear log")
				end try
			end tell
		end clearConsole


		(* Computes the inspector container which varies when the inspector window is floating or not. *)
		on _getInspectorContainer()
			set isFloating to isInspectorFloating()
			tell application "System Events" to tell process "Safari"
				if isFloating then
					set targetWindow to first window whose title starts with "Web Inspector"
				else
					try
						set targetWindow to first window whose title is not ""
					on error
						return missing value
					end try
				end if
			end tell

			tell application "System Events" to tell process "Safari"
				if isFloating then return UI element 1 of scroll area 1 of group 1 of group 1 of targetWindow

				UI element 1 of scroll area 1 of group 1 of group 1 of tab group 1 of splitter group 1 of targetWindow
			end tell
		end _getInspectorContainer
	end script
end decorate
