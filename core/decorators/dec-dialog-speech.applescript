(*
	@Purpose:
		Speak out the dialog message and the subsequent user response.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/decorators/dec-dialog-speech

	@Created: Sun, Dec 07, 2025 at 04:08:25 PM
	@Last Modified: 2025-12-08 09:54:53
	@Change Logs:
*)
use scripting additions

use loggerFactory : script "core/logger-factory"

use speechLib : script "core/speech"

property logger : missing value

property speech : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Show OK Dialog
		Manual: Show Warning
		Manual: Show Warning with Timeout
		Manual: Show Warning Dialog

		Manual: Show Choices
		Manual: Show Choices with Default
		Manual: Show Choices with Default and Timeout
		Manual: NO SPEECH
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
	set sutLib to script "core/dialog"
	set sut to sutLib's new()
	set sut to decorate(sut)

	if caseIndex is 1 then

	else if caseIndex is 2 then
		set speechOn of sut to true
		sut's showOkDialog("Title", "Message")

	else if caseIndex is 3 then
		set speechOn of sut to true
		sut's confirmWarning("Title", "Confirm Message")
		logger's infof("Result: {}", result)

	else if caseIndex is 4 then
		set speechOn of sut to true
		sut's showWarningWithTimeout("Title", "Warning Message", 8)

	else if caseIndex is 5 then
		set speechOn of sut to true
		sut's showWarningDialog("Title", "Warning Dialog Message")

	else if caseIndex is 6 then
		set speechOn of sut to true
		sut's showChoices("Title", "Message Choices", {"one", "two", "three"})
		logger's infof("Result: {}", result)

	else if caseIndex is 7 then
		set speechOn of sut to true
		sut's showChoicesWithDefault("Title", "Message Choices with Default", {"one", "two", "three"}, "three")
		logger's infof("Result: {}", result)

	else if caseIndex is 8 then
		set speechOn of sut to true
		sut's showChoicesWithTimeout("Title", "Message Choices with Default and Timeout", {"one", "two", "three"}, "three", 8)
		logger's infof("Result: {}", result)

	else if caseIndex is 9 then
		sut's showChoicesWithTimeout("Title", "Speech flag unset", {"one", "two", "three"}, "three", 8)
		logger's infof("Result: {}", result)
	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set speech to speechLib's new()

	script DialogSpeechDecorator
		property parent : mainScript
		property speechOn : false

		on showOkDialog(theTitle, message)
			if speechOn then
				set synchronous of speech to false
				tell speech to speak(message)
				logger's info(message)
			end if

			continue showOkDialog(theTitle, message)
		end showOkDialog

		on showWarningWithTimeout(theTitle, message, timeoutSeconds)
			if speechOn then
				set synchronous of speech to false
				tell speech to speak(message)
			end if

			continue showWarningWithTimeout(theTitle, message, timeoutSeconds)
		end showWarningWithTimeout


		(* @return boolean *)
		on confirmWarning(theTitle, message)
			if speechOn then
				set synchronous of speech to false
				tell speech to speak(message)
			end if

			set booleanResult to continue confirmWarning(theTitle, message)
			if booleanResult then
				set userResponse to "Yes"
			else
				set userResponse to "No"
			end if

			if speechOn then
				set synchronous of speech to true
				tell speech to speak(userResponse)
			end if

			booleanResult
		end confirmWarning


		(* @choices up to 3 choices to be shown as buttons for quick response. *)
		on showChoices(theTitle, message, choices as list)
			if (count of choices) is greater than 3 then tell me to error "You can only have up to 3 choices"

			if speechOn then
				set synchronous of speech to false
				tell speech to speak(message)
			end if

			set userChoice to continue showChoices(theTitle, message, choices)
			if speechOn then
				set synchronous of speech to true
				tell speech to speak(userChoice)
			end if
			userChoice
		end showChoices


		(* @choices up to 3 choices to be shown as buttons for quick response. *)
		on showChoicesWithDefault(theTitle, message, choices as list, defaultButton)
			if (count of choices) is greater than 3 then tell me to error "You can only have up to 3 choices"

			if speechOn then
				set synchronous of speech to false
				tell speech to speak(message)
				-- logger's info(message)
			end if

			set userChoice to continue showChoicesWithDefault(theTitle, message, choices, defaultButton)

			if speechOn then
				set synchronous of speech to true
				tell speech to speak(userChoice)
			end if

			userChoice
		end showChoicesWithDefault

		(* @choices up to 3 choices to be shown as buttons for quick response. *)
		on showChoicesWithTimeout(theTitle, message, choices as list, defaultChoice, timeoutSeconds)
			if (count of choices) is greater than 3 then tell me to error "You can only have up to 3 choices"

			if speechOn then
				set synchronous of speech to false
				tell speech to speak(message)
			end if

			set response to continue showChoicesWithTimeout(theTitle, message, choices, defaultChoice, timeoutSeconds)

			if speechOn then
				set synchronous of speech to true
				tell speech to speak(response)
			end if

			response
		end showChoicesWithTimeout

		on showWarningDialog(theTitle, message)
			if speechOn then
				set synchronous of speech to false
				tell speech to speak(message)
			end if

			continue showWarningDialog(theTitle, message)
		end showWarningDialog

	end script
end decorate
