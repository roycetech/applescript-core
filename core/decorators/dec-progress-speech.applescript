(*
	@Purpose:
		Speak the progress description.

	@Project:
		applescript-core

		@Build:
		./scripts/build-lib.sh core/decorators/dec-progress-speech

	@Created: Mon, Dec 08, 2025 at 01:56:00 PM
	@Last Modified: 2025-12-08 15:09:30
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

use speechLib : script "core/speech"
use switchLib : script "core/switch"

property logger : missing value

property speech : missing value

property SWITCH_SPEAK_PROGRESS : "app-core: Speak Progress"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Step
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
	set sutLib to script "core/progress"
	set sut to sutLib's new()
	set sut to decorate(sut)

	if caseIndex is 1 then

	else if caseIndex is 2 then
		set switchSpeech to switchLib's new(SWITCH_SPEAK_PROGRESS)
		switchSpeech's turnOn()

		sut's initMainActionsFromString("
			step one
			step two
		")
		sut's step()

	else if caseIndex is 3 then

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set speech to speechLib's new()
	set switchSpeech to switchLib's new(SWITCH_SPEAK_PROGRESS)
	set localSpeakStep to switchSpeech's isActive()

	script ProgressSpeechDecorator
		property parent : mainScript
		property speakStep : localSpeakStep

		on step given token:theToken : ""
			set currentAction to continue step()

			if speakStep is true then tell speech to speakWithVolume(currentAction, 0.3)
			-- if logging is true then logger's info("(" & currentStep & "/" & (count of mainActions) & ") " & currentAction)
		end step
	end script
end decorate
