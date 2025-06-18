(*
	@Purpose:
		The original safari script is quite big and we want to improve its manageability by breaking it down into smaller pieces.
		This decorator will contain the handlers relating to tab groups.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/18.5/dec-safari-settings

	@Created: Fri, Jul 12, 2024 at 2:58:38 PM
	@Last Modified: 2025-06-14 13:36:50
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"


property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		INFO
		Manual: Show Settings Window
		Manual: Close Settings Window
		Manual: Switch Settings Tab
		Manual: Enable extension

		Manual: Disable extension
		Manual: Close on Target Status
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	-- activate application ""
	set sutLib to script "core/safari"
	set sut to sutLib's new()
	set sut to decorate(sut)

	logger's infof("Is Settings window active: {}", sut's isSettingsWindowPresent())
	logger's infof("Active Settings tab: {}", sut's getSettingsTabName())

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's showSettings()

	else if caseIndex is 3 then
		sut's closeSettings()

	else if caseIndex is 4 then
		set sutTabName to "Unicorn"
		set sutTabName to "General"
		-- set sutTabName to "Feature Flags"

		logger's debugf("sutTabName: {}", sutTabName)
		sut's switchSettingsTab(sutTabName)

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script SafariSettingsDecorator
		property parent : mainScript

		on showSettings()
			if isSettingsWindowPresent() then return

			tell application "System Events" to tell process "Safari"
				try
					click (first menu item of menu 1 of menu bar item "Safari" of menu bar 1 whose title starts with "Settings")
				end try
			end tell
		end showSettings


		on closeSettings()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return

			tell application "System Events" to tell process "Safari"
				click (first button of settingsWindow whose description is "close button")
			end tell
		end closeSettings


		on isSettingsWindowPresent()
			getSettingsWindow() is not missing value
		end isSettingsWindowPresent


		on switchSettingsTab(tabName)
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return

			tell application "System Events" to tell process "Safari"
				try
					click (first button of toolbar 1 of settingsWindow whose title contains tabName)
				end try
			end tell
		end switchSettingsTab


		on getSettingsTabName()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value

			tell application "System Events"
				title of settingsWindow
			end tell
		end getSettingsTabName


		on getSettingsWindow()
			if running of application "Safari" is false then return missing value

			tell application "System Events" to tell process "Safari"
				try
					return first window whose (enabled of second button is false and description of second button is "zoom button")
				end try
			end tell
			missing value
		end getSettingsWindow
	end script
end decorate
