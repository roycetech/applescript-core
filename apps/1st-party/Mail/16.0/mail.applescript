(*
	Wrapper library for the macOS Mail app.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Mail/16.0/mail

	@Created: Pre-2023

	@Change Logs:
		Fri, Feb 27, 2026, at 07:31:55 PM - Added #moveMainWindowToFront
		Fri, Jan 23, 2026, at 11:16:56 AM - Added #clearSearch handler.
		Wed, Jul 17, 2024 at 10:33:53 AM - Removed dependency with cliclick.
*)

use unic : script "core/unicodes"
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use dockLib : script "core/dock"
use decMailSettings : script "core/dec-mail-settings"
use decMailSelection : script "core/dec-mail-selection"

property logger : missing value

property dock : missing value


if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Goto Favorite Folder
		Manual: Focus message
		Manual: Move main window to front
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
	logger's infof("Sender: {}", sut's getMessageSender())
	logger's infof("Integration: Settings window present?: {}", sut's isSettingsWindowPresent())

	if caseIndex is 1 and not isMessageWindow then

	else if caseIndex is 2 then
		set sutFolderName to "04 Updates"
		set sutFolderName to "Inbox"
		set sutFolderName to "Junk"
		logger's debugf("sutFolderName: {}", sutFolderName)

		sut's gotoFolder(sutFolderName)

	else if caseIndex is 3 then
		set sutMessageId to -1
		set sutMessageId to 42794
		set sutMessageId to 41705
		logger's debugf("sutMessageId: {}", sutMessageId)

		set sutMailboxName to "04 Updates"
		set sutMailboxName to "2026 Apartment"
		logger's debugf("sutMailboxName: {}", sutMailboxName)

		set sutAccountName to "Exchange"
		logger's debugf("sutAccountName: {}", sutAccountName)

		sut's focusMessage(sutAccountName, sutMailboxName, sutMessageId)


	else if caseIndex is 4 then
		sut's moveMainWindowToFront()

	end if

	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's inject(me)
	set dock to dockLib's new()

	script MailInstance
		on focusMessage(accountName, mailboxName, messageId)
			if running of application "Mail" is false then
				activate application "Mail"
			end if

			gotoFolder(mailboxName)
			selectMessage(accountName, mailboxName, messageId)

			tell application "Mail"
				try
					first mailbox of account accountName whose name contains mailboxName
					open (the first message of result whose id is messageId as integer)
				on error the errorMessage number the errorNumber
					log errorMessage
				end try
			end tell
		end focusMessage


		on clearSearch()
			set mainWindow to getMainWindow()
			if mainWindow is missing value then return

			tell application "System Events" to tell process "Mail"
				click (first button of text field 1 of last group of toolbar 1 of front window whose description is "cancel")
			end tell
		end clearSearch


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
			if mainMailWindow is missing value then
				logger's info("Main window was not found")
				dock's clickApp("Mail")
			set mainMailWindow to getMainWindow()
			else
				moveMainWindowToFront()
			end if

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
						set selected of (2nd row of outline 1 of scroll area 1 of splitter group 1 of mainMailWindow whose value of UI element 1 of UI element 1 contains folderNameKeyword) to true
					end try
					return
				end if

				try
					set selected of (first row of outline 1 of scroll area 1 of splitter group 1 of mainMailWindow whose value of UI element 1 of UI element 1 contains folderNameKeyword) to true
					(*
					on error the errorMessage number the errorNumber
					row 12 of outline 1 of scroll area 1 of splitter group 1 of front window
					*)
				on error the errorMessage number the errorNumber
					log errorMessage


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


		on moveMainWindowToFront()
			tell application "System Events" to tell process "Mail"
				try
					first window whose title contains "messages" or title contains "drafts" or title contains "Searching"
				on error the errorMessage number the errorNumber -- When there is no main window
					return

				end try
				name of result as text
			end tell
			textUtil's stringBefore(result, space & unic's MAIL_SUBDASH)

			tell application "Mail"
				set index of window result to 1

			end tell
		end moveMainWindowToFront
	end script

	decMailSettings's decorate(result)
	decMailSelection's decorate(result)
end new
