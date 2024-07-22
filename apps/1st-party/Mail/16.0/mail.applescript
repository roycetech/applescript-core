(*
	Wrapper library for the macOS Mail app.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Mail/16.0/mail

	@Created: Pre-2023

	@Change Logs:
		Wed, Jul 17, 2024 at 10:33:53 AM - Removed dependency with cliclick.
*)

use unic : script "core/unicodes"

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set spotScript to script "core/spot-test"
	set listUtil to script "core/list"

	set cases to listUtil's splitByLine("
		Manual: NOOP
		Manual: Goto Favorite Folder

	")

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

	if caseIndex is 1 and not isMessageWindow then

	else if caseIndex is 2 then
		sut's gotoFolder("04 Updates")

	end if

	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's inject(me)

	script MailInstance

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
		on gotoFolder(folderName)
			set mainMailWindow to getMainWindow()
			if mainMailWindow is missing value then return

			tell application "System Events" to tell process "Mail"
				if title of mainMailWindow starts with folderName then return

				set mailFolderRows to rows of outline 1 of scroll area 1 of splitter group 1 of mainMailWindow
				repeat with nextRow in mailFolderRows
					if get description of UI element 1 of nextRow contains folderName then
						set selected of nextRow to true
						exit repeat
					end if
				end repeat
			end tell
		end gotoFolder


		(*
			@returns the main mail window, not a message window.
		*)
		on getMainWindow()
			if running of application "Mail" is false then return missing value

			tell application "System Events" to tell process "Mail"
				try
					return first window whose title contains "messages" or title contains "drafts"
				end try
			end tell
			missing value
		end getMainWindow
	end script
end new
