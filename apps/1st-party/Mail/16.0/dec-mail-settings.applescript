(*
	@Purpose:
		Mail extension to provide the settings-related handlers.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Mail/16.0/dec-mail-settings

	@Created: Sun, Feb 15, 2026 at 05:20:18 PM
	@Last Modified: 2026-02-15 17:28:42
	@Change Logs:
*)
use listUtil : script "core/list" -- reviewed.

use loggerFactory : script "core/logger-factory"

property logger : missing value

property SETTINGS_TITLES : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Show Settings Window
		Manual: Close Settings Window
		Manual: Focus Settings Window
		Manual: Switch Settings Tab

		Manual: Settings: General: Trigger New Message Notifications
		Manual: Multi: Settings: General: Pick New Message Notifications
		Dummy
		Dummy
		Dummy
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
	set sutLib to script "core/mail"
	set sut to sutLib's new()
	set sut to decorate(sut)

	logger's infof("Settings window present?: {}", sut's isSettingsWindowPresent())
	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's showSettingsWindow()

	else if caseIndex is 3 then
		sut's closeSettingsWindow()

	else if caseIndex is 4 then
		sut's focusSettingsWindow()

	else if caseIndex is 5 then
		set sutTabName to "unicorn"
		set sutTabName to "General"
		set sutTabName to "Signatures"
		logger's debugf("sutTabName: {}", sutTabName)

		sut's switchSettingsTab(sutTabName)

	else if caseIndex is 6 then
		-- Must already be showing the General settings.
		sut's triggerNewMessageNotificationsPopup()

	else if caseIndex is 7 then
		set sutOption to "unicorn"
		set sutOption to "Notifications"
		logger's debugf("sutOption: {}", sutOption)

		sut's triggerNewMessageNotificationsPopup()
		sut's pickNewMessageNotificationPopupOption(sutOption)
	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	set SETTINGS_TITLES to listUtil's splitByLine("
		General
		Accounts
		Junk Mail
		Fonts & Colors
		Viewing

		Composing
		Signatures
		Rules
		Extensions
		Privacy
	")

	script MailSettingsDecorator
		property parent : mainScript

		on isSettingsWindowPresent()
			if running of application "Mail" is false then return false

			getSettingsWindow() is not missing value
		end isSettingsWindowPresent


		(* @returns System Event window *)
		on getSettingsWindow()
			if running of application "Mail" is false then return missing value

			tell application "System Events" to tell process "Mail"
				set standardWindows to windows whose role is not "Dialog"
				if (count of standardWindows) is 0 then return missing value

				repeat with nextWindow in standardWindows
					if SETTINGS_TITLES contains the title of the nextWindow then return nextWindow
				end repeat

			end tell

			missing value
		end getSettingsWindow


		on showSettingsWindow()
			if running of application "Mail" is false then return
			if isSettingsWindowPresent() then return

			tell application "System Events" to tell process "Mail"

				try
					click (first menu item of menu 1 of menu bar item "Mail" of menu bar 1 whose title starts with "Settings")
					delay 0.1
				end try
			end tell
		end showSettingsWindow


		on closeSettingsWindow()
			if not isSettingsWindowPresent() then return

			tell application "System Events" to tell process "Mail"
				click (first button of my getSettingsWindow() whose description is "close button")
			end tell
		end closeSettingsWindow


		on focusSettingsWindow()
			if not isSettingsWindowPresent() then return
			set settingsWindow to getSettingsWindow()

			tell application "System Events" to tell process "Mail"
				set frontmost to true
				set currentSettingsWindowTitle to the title of settingsWindow
				logger's debugf("currentSettingsWindowTitle: {}", currentSettingsWindowTitle)

				try
					click (first menu item of menu 1 of menu bar item "Window" of menu bar 1 whose title is currentSettingsWindowTitle)
				on error the errorMessage number the errorNumber
					log errorMessage

				end try
			end tell

		end focusSettingsWindow


		on switchSettingsTab(tabTitle)
			if not isSettingsWindowPresent() then return
			tell application "System Events" to tell process "Mail"
				if the tabTitle is not in SETTINGS_TITLES then return

				try
					click button tabTitle of toolbar 1 of my getSettingsWindow()
				end try
			end tell
		end switchSettingsTab


		(*
			General Settings
		*)
		on triggerNewMessageNotificationsPopup()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return

			tell application "System Events" to tell process "Mail"
				try
					-- click pop up button "New message notifications:" of group 1 of settingsWindow
					click pop up button 5 of group 1 of settingsWindow
					delay 0.1
				end try
			end tell
		end triggerNewMessageNotificationsPopup


		(* This handler must be invoked right after invoking the #triggerNewMessageNotificationsPopup in the right conditions (Settings window present, correct settings tab). *)
		on pickNewMessageNotificationPopupOption(optionTitle)
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return

			tell application "System Events" to tell process "Mail"
				-- set newMassegNotificationPopup to pop up button "New message notifications:" of group 1 of settingsWindow
				set newMassegNotificationPopup to pop up button 5 of group 1 of settingsWindow
				try
					click (last menu item of menu 1 of newMassegNotificationPopup whose title is optionTitle)
					delay 0.1
				on error the errorMessage number the errorNumber
					logger's warn(errorMessage)

				end try -- When the passed optionTitle doesn't exist.
			end tell
		end pickNewMessageNotificationPopupOption
	end script
end decorate
