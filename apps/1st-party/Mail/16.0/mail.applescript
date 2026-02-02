(*
	Wrapper library for the macOS Mail app.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Mail/16.0/mail

	@Created: Pre-2023

	@Change Logs:
		Fri, Jan 23, 2026, at 11:16:56 AM - Added #clearSearch handler.
		Wed, Jul 17, 2024 at 10:33:53 AM - Removed dependency with cliclick.
*)

use unic : script "core/unicodes"
use listUtil : script "core/list"  -- reviewed.

use loggerFactory : script "core/logger-factory"

property logger : missing value

property SETTINGS_TITLES : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		NOOP
		Manual: Goto Favorite Folder
		Manual: Show Settings Window
		Manual: Close Settings Window
		Manual: Focus Settings Window

		Manual: Switch Settings Tab
		Manual: Settings: General: Trigger New Message Notifications
		Manual: Multi: Settings: General: Pick New Message Notifications
	")

	set spotScript to script "core/spot-test"
	set spotLib to spotScript's new()
	set spot to spotLib's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()
	set isMessageWindow to sut's isMessageWindowActive()
	logger's infof("Message window at front?: {}", isMessageWindow)
	logger's infof("Settings window present?: {}", sut's isSettingsWindowPresent())
	logger's infof("Sender: {}", sut's getMessageSender())

	if caseIndex is 1 and not isMessageWindow then

	else if caseIndex is 2 then
		set sutFolderName to "04 Updates"
		set sutFolderName to "Inbox"
		logger's debugf("sutFolderName: {}", sutFolderName)

		sut's gotoFolder(sutFolderName)

	else if caseIndex is 3 then
		sut's showSettingsWindow()

	else if caseIndex is 4 then
		sut's closeSettingsWindow()

	else if caseIndex is 5 then
		sut's focusSettingsWindow()

	else if caseIndex is 6 then
		set sutTabName to "unicorn"
		set sutTabName to "General"
		logger's debugf("sutTabName: {}", sutTabName)

		sut's switchSettingsTab(sutTabName)

	else if caseIndex is 7 then
		sut's triggerNewMessageNotificationsPopup()

	else if caseIndex is 8 then
		set sutOption to "unicorn"
		set sutOption to "Notifications"
		logger's debugf("sutOption: {}", sutOption)

		sut's triggerNewMessageNotificationsPopup()
		sut's pickNewMessageNotificationPopupOption(sutOption)
	end if

	spot's finish()
	logger's finish()
end spotCheck


on new()
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

	script MailInstance

		on clearSearch()
			set mainWindow to getMainWindow()
			if mainWindow is missing value then return

			tell application "System Events" to tell process "Mail"
				click (first button of text field 1 of last group of toolbar 1 of front window whose description is "cancel")
			end tell
		end clearSearch


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


		(*
			The front window of the Mail application is either a message window or the standard email list window.

			@returns true when the front window is a message window.
		*)
		on isMessageWindowActive()
			if running of application "Mail" is false then return false

			tell application "System Events" to tell process "Mail"
				set windowTitle to the name of front window
			end tell

			windowTitle does not contain unic's MAIL_SUBDASH
		end isMessageWindowActive


		(*
			@requires: App Focus.

			@returns the email address from the message window.
		*)
		on getMessageSender()
			if running of application "Mail" is false then return missing value

			tell application "Mail"
				try
					set selectedMessage to item 1 of (get selection)
					set senderEmail to sender of selectedMessage
				on error the errorMessage number the errorNumber
					logger's warn(errorMessage)
					return missing value
				end try

				if senderEmail is not missing value then
					return extract address from senderEmail
				end if
			end tell
		end getMessageSender


		(*  *)
		on gotoFolder(folderNameKeyword)
			set mainMailWindow to getMainWindow()
			if mainMailWindow is missing value then return

			tell application "System Events" to tell process "Mail"
				if title of mainMailWindow starts with folderNameKeyword then return

				-- set mailFolderRows to rows of outline 1 of scroll area 1 of splitter group 1 of mainMailWindow
				-- repeat with nextRow in mailFolderRows
				-- 	if get description of UI element 1 of nextRow contains folderName then
				-- 		set selected of nextRow to true
				-- 		exit repeat
				-- 	end if
				-- end repeat

				set frontmost to true
				if folderNameKeyword is "Inbox" then
					try
						set selected of (2nd row of outline 1 of scroll area 1 of splitter group 1 of front window whose value of UI element 1 of UI element 1 contains folderNameKeyword) to true
					end try
					return
				end if

				try
					set selected of (first row of outline 1 of scroll area 1 of splitter group 1 of front window whose value of UI element 1 of UI element 1 contains folderNameKeyword) to true
					(*
					on error the errorMessage number the errorNumber
					row 12 of outline 1 of scroll area 1 of splitter group 1 of front window
					*)

				end try
			end tell
		end gotoFolder


		(*
			@returns the main mail window, not a message window.
		*)
		on getMainWindow()
			if running of application "Mail" is false then return missing value

			tell application "System Events" to tell process "Mail"
				try
					return first window whose title contains "messages" or title contains "drafts" or title contains "Searching"
				end try
			end tell
			missing value
		end getMainWindow
	end script
end new
