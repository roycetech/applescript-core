(*
	@Created: Tuesday, December 19, 2023 at 3:35:33 PM
	@Last Modified: 2023-12-19 15:45:02
*)

use scripting additions

use listUtil : script "core/list"
use emoji : script "core/emoji"

use loggerFactory : script "core/logger-factory"

use speechLib : script "core/speech"

property logger : missing value
property speech : missing value

use spotScript : script "core/spot-test"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Synchronous
	")

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
	set speech to speechLib's new(missing value)

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
