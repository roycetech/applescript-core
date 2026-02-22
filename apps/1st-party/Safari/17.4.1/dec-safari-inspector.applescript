(*
	@Purpose:
		Web inspector handlers

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/17.4.1/dec-safari-inspector

	@Created: Friday, April 19, 2024 at 4:35:51 PM
	@Last Modified: 2026-02-20 13:20:23
	@Change Logs:

*)
use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"

property logger : missing value
property kb : missing value

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

	logger's infof("Is active: {}", sut's isInspectorPanelActive())
	logger's infof("Is floating: {}", sut's isInspectorFloating())
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

		logger's debugf("tabName: {}", tabName)
		sut's switchTab(tabName)
	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script SafariInspectorDecorator
		property parent : mainScript

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

			tell application "System Events" to tell process "Safari"
				set frontmost to true
				try
					click menu item "Show Web Inspector" of menu 1 of menu bar item "Develop" of menu bar 1
				end try
			end tell
		end openWebInspector

		on closeWebInspector()
			if running of application "Safari" is false then return

			tell application "System Events" to tell process "Safari"
				set frontmost to true
				try
					click menu item "Close Web Inspector" of menu 1 of menu bar item "Develop" of menu bar 1
				end try
			end tell
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

		on switchTab(tabName)
			if running of application "Safari" is false then return

			set inspectorContainer to _getInspectorContainer()
			if inspectorContainer is missing value then return

			tell application "System Events" to tell process "Safari"
				try
					click radio button tabName of tab group 1 of inspectorContainer
				end try -- Ignore invalid tabName
			end tell
		end switchTab

		on clearConsole()
			if running of application "Safari" is false then return

			switchTab("Console")

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
