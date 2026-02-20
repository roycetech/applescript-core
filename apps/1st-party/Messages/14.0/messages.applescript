(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Messages/14.0/messages

	@Created: Mon, Jul 07, 2025 at 08:17:22 AM
	@Last Modified: 2026-02-09 10:14:17
*)

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()
	if caseIndex is 1 then

	else if caseIndex is 2 then

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)

	script MessagesInstance


		on newMessage()
			if running of application "Messages" is false then return

			tell application "System Events" to tell process "Messages"
				click (first button of toolbar 1 of front window whose description is "Compose")
			end tell
		end newMessage


		on sendMessageToContact(contactEmail, message)
			tell application "Messages"
				set targetService to 1st account whose service type = iMessage
				set targetBuddy to participant contactEmail of targetService

				send message to targetBuddy
			end tell
		end sendMessageToContact

	end script
end new
