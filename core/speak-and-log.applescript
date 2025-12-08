(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/speak-and-log

	@Created: Tuesday, December 19, 2023 at 3:35:33 PM
	@Last Modified: 2025-12-07 14:28:03
*)

use scripting additions

use emoji : script "core/emoji"

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
		Manual: Synchronous
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
		sut's emitSynchronously("Hello")

	else if caseIndex is 2 then

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	set speech to speechLib's new()

	script SpeakAndLogInstance

		on emitSynchronously(rawText)
			logger's info(emoji's HORN & "+ " & rawText)
			speech's speakSynchronously(rawText)
		end emitSynchronously


		on emit(rawText)
			speak(rawText)
			if synchronous then
				set prefix to "+ "
			else
				set prefix to "* "
			end if

			logger's info(emojis's HORN & prefix & rawText)
		end emit

	end script
end new
