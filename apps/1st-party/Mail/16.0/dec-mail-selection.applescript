(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Mail/16.0/dec-mail-selection

	@Created: Sun, Feb 15, 2026 at 06:21:28 PM
	@Last Modified: 2026-02-15 19:55:22
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
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

	logger's infof("Selected account name: {}", sut's getSelectedAccountName())
	logger's infof("Selected mailbox name: {}", sut's getSelectedMailboxName())
	logger's infof("Selected message ID: {}", sut's getSelectedMessageId())

	if caseIndex is 1 then

	else if caseIndex is 2 then

	else if caseIndex is 3 then

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script MailSelectionDecorator
		property parent : mainScript

		on selectMessage(accountName, mailboxName, messageId)
			tell application "Mail"

				first mailbox of account accountName whose name contains mailboxName
				set targetMessage to the first message of result whose id is messageId

				set selected messages of front message viewer to {targetMessage}
			end tell
		end selectMessage


		on getSelectedAccountName()
			set mainWindow to getMainWindow()
			if mainWindow is missing value then return missing value

			tell application "Mail"
				try
					set selectedItem to selection
					item 1 of selectedItem
					account of mailbox of result -- ok
					return name of result
				end try
			end tell

			missing value
		end getSelectedAccountName


		on getSelectedMailboxName()
			set mainWindow to getMainWindow()
			if mainWindow is missing value then return missing value

			tell application "Mail"
				try
					set selectedItem to selection
					item 1 of selectedItem
					return the name of the mailbox of result
				end try
			end tell

			missing value
		end getSelectedMailboxName


		on getSelectedMessageId()
			tell application "Mail"
				try
					set selectedItem to selection
					item 1 of selectedItem
					-- mailbox of result -- ok
					-- account of mailbox of result -- ok
					-- name of result
					return id of result
				end try
			end tell

			missing value
		end getSelectedMessageId
	end script
end decorate
