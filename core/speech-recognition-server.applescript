(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/speech-recognition-server

	@Created: Friday, December 1, 2023 at 10:28:21 AM
	@Last Modified: 2024-07-10 18:27:39
*)

use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"
use spotScript : script "core/spot-test"

property logger : missing value


if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Basic Listen For
		Manual: Listen For with Timeout
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
		set recognizedPhrase to sut's listenFor({"Yes", "no"})
		logger's infof("recognizedPhrase: {}", recognizedPhrase)

	else if caseIndex is 2 then
		set recognizedPhrase to sut's listenForWithTimeout("You've got 10 seconds. Yes, or no?", {"Yes", "no"}, 10)
		if recognizedPhrase is false then
			logger's info("Timed out")
		else
			logger's infof("recognizedPhrase: {}", recognizedPhrase)
		end if
	end if

	spot's finish()

	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)

	script SpeechRecognitionServerInstance

		on listenFor(prompt, listOfWordsOrPhrases)
			tell application "SpeechRecognitionServer"
				try
					if prompt is not missing value then
						return listen for listOfWordsOrPhrases with prompt prompt
					else
						return listen for listOfWordsOrPhrases
					end if
				end try
			end tell

			missing value
		end listenFor

		(*
			@returns the phrase or word uttered, false if timed out.
		*)
		on listenForWithTimeout(prompt, listOfWordsOrPhrases, timeoutSeconds)
			tell application "SpeechRecognitionServer"
				try
					return listen for listOfWordsOrPhrases giving up after timeoutSeconds with prompt prompt
				end try
			end tell
			false
		end listenForWithTimeout
	end script
end new
