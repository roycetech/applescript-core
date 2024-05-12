(*
	Wrapper library for the macOS Mail app.

	The 3rd party library cliclick is required by this library.

	@Project:
		applescript-core

	@Build:
		make build-mail

	@Created: Pre-2023
*)

use unic : script "core/unicodes"

use loggerFactory : script "core/logger-factory"

use cliclickLib : script "core/cliclick"

use spotScript : script "core/spot-test"

property logger : missing value


if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"

	set cases to listUtil's splitByLine("
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
	if isMessageWindow then
		logger's infof("Sender: {}", sut's getMessageSender())

	end if

	if caseIndex is 1 and not isMessageWindow then
		sut's gotoFolder("04 Updates")

	else if caseIndex is 2 then

	end if

	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's inject(me)
	set cliclick to cliclickLib's new()

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

			tell application "System Events" to tell process "Mail"
				set frontmost to true
				try
					set subjectContainer to text area 1 of group 1 of group 1 of scroll area 1 of front window
				on error the errorMessage number the errorNumber
					logger's warn(errorMessage)
					return missing value
				end try

				(* Native click doesn't work so we rely on 3rd party cliclick. *)
				lclick of cliclick at static text 1 of subjectContainer given relativex:-10
				set email to the name of menu item 1 of menu 1 of subjectContainer
				lclick of cliclick at static text 1 of subjectContainer
			end tell
			email
		end getMessageSender


		(*  *)
		on gotoFolder(folderName)

			tell application "System Events" to tell process "Mail"
				repeat with nextRow in rows of outline 1 of scroll area 1 of splitter group 1 of (first window whose title contains "messages" or title contains "drafts")
					if get description of UI element 1 of nextRow contains folderName then
						set selected of nextRow to true
						exit repeat
					end if
				end repeat
			end tell
		end gotoFolder
	end script
end new