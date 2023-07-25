(*
	TOFIX: Circular dependency to logger resulting to missing value for this script's logger.
		Appears to be fixed by doing the import inside the handler, observe if there's performance degradation.

	Update the "text-to-speech-_default.plist" to add customization. This is also required for the integration testing.

	Use Samantha as the speaker for the best experience.

	@Known Issues:
		Do not implement a logger inside any of the non-test handlers as that would result in a circular dependency with the logging library.

	@Plists:
		text-to-speech_default

	@Build:
		make compile-lib SOURCE=core/speech
*)


use script "Core Text Utilities"
use scripting additions

use std : script "std"

use textUtil : script "string"
use listUtil : script "list"
use regex : script "regex"
use loggerFactory : script "logger-factory"

use userLib : script "user"
use plutilLib : script "plutil"
use plistBuddyLib : script "plist-buddy"
use mapLib : script "map"
use usrLib : script "user"

use spotScript : script "spot-test"

use testLib : script "test"

-- PROPERTIES =================================================================
property logger : missing value
property usr : missing value
property plutil : missing value

property isSpot : false

if {"Script Editor", "Script Debugger"} contains the name of current application then
	set isSpot to true
	spotCheck()
end if

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()


	set cases to listUtil's splitByLine("
		Integration Test
		Manual: Random
		Manual: Private: Load Plist
		Manual: Private: Localize Message
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	if caseIndex is 1 then
		integrationTest()

	else if caseIndex is 2 then
		set sut to new(missing value)
		sut's speak("2904")
		sut's speak("hello")

	else if caseIndex is 3 then
		set sut to new("text-to-speech_ama")
		sut's _loadTranslations()

	else if caseIndex is 4 then
		set sut to new("text-to-speech_ama")
		sut's _loadTranslations()
		logger's infof("Handler result: {}", sut's _localizeMessage("Is xlarge smaller than std?"))

	end if

	spot's finish()
	logger's finish()
end spotCheck

-- HANDLERS =================================================================

(*
	NOTE: Removed logger references inside the script.

	@Final - maybe getting too complex if we want to make this extensible.
*)
on new(pLocalizationConfigName)
	-- loggerFactory's inject(me)
	set usr to userLib's new()
	set plutil to plutilLib's new()

	script SpeechInstance
		property quiet : false
		property synchronous : false
		property waitNextWords : false -- Same purpose as speakSynchronously()

		(* Flag to indicate if the plist has been loaded into memory. *)
		property _translationsLoaded : false
		property _localizationConfigName : missing value
		property _translationKeys : {}
		property _translationsDictionary : missing value


		on _loadTranslations()
			set _translationsLoaded to true
			if not plutil's plistExists(_localizationConfigName) then
				-- logger's warnf("Localization was not found: {}", _localizationConfigName)
				log "WARN: Localization was not found: " & _localizationConfigName
				return
			end if

			-- logger's infof("Configuring localization using: {}", _localizationConfigName)
			log "Configuring localization using: " & _localizationConfigName
			try
				set localSpeecMapping to plutil's new(_localizationConfigName)
			on error the errorMessage number the errorNumber
				set localSpeecMapping to missing value
			end try


			set plistBuddy to plistBuddyLib's new(_localizationConfigName)
			set _translationKeys to plistBuddy's getKeys()
			set _translationsDictionary to mapLib's new()
			repeat with nextKey in _translationKeys
				-- logger's debugf("nextKey: {}", nextKey)
				set nextValue to plistBuddy's getValue(nextKey)
				-- logger's debugf("nextValue: {}", nextValue)
				_translationsDictionary's putValue(nextKey, nextValue)
			end repeat
		end _loadTranslations


		on _localizeMessage(message)
			set localizedMessage to message as text
			repeat with nextTranslatable in _translationKeys
				set isRegex to nextTranslatable starts with "/" and nextTranslatable ends with "/"
				if isRegex then
					set nextTranslation to _translationsDictionary's getValue(nextTranslatable)
					set pattern to text 2 thru ((count of nextTranslatable) - 1) of nextTranslatable

					if regex's matchesInString(pattern, localizedMessage) then
						-- logger's debugf("Translating pattern: '{}' to '{}'", {nextTranslatable, nextTranslation})
						set localizedMessage to regex's replace(localizedMessage, pattern, nextTranslation)
					end if

				else if localizedMessage contains nextTranslatable then
					-- warzone, values from the plist needs to be coerced into text to make it work.
					set nextTranslation to _translationsDictionary's getValue(nextTranslatable)
					-- logger's debugf("Translating: '{}' to '{}'", {nextTranslatable, nextTranslation})

					-- logger's debugf("localizedMessage before: {}", localizedMessage)
					set localizedMessage to textUtil's replace(localizedMessage, nextTranslatable as text, nextTranslation as text)
					-- logger's debugf("localizedMessage after: {}", localizedMessage)

				end if
			end repeat
			-- logger's debugf("localizedMessage: {}", localizedMessage)

			localizedMessage
		end _localizeMessage


		(* @returns the translated text if present, otherwise the original text to passed. *)
		on speak(rawText)
			if not _translationsLoaded then _loadTranslations()

			(*
				User library has multiple dependencies that may conflict during spot checking so let's skip this during spot checks.
			*)
			if not isSpot then
				try
					if usr's isInMeeting() then
						-- logger's info("SILENCED: " & rawText) -- Dangerous to have access logger instance here.
						log "SILENCED: " & rawText
						return rawText
					end if
				on error the errorMessage number the errorNumber -- ignore if user script is not installed.
					-- logger's warn(errorMessage)
					log "WARN: " & errorMessage
					return rawText
				end try
			end if

			set textToSpeak to _localizeMessage(rawText)
			if my quiet then return textToSpeak

			if my waitNextWords then
				say textToSpeak
				set my waitNextWords to false

			else if my synchronous then
				say textToSpeak

			else
				say textToSpeak without waiting until completion
			end if

			textToSpeak
		end speak


		on speakSynchronously(rawText)
			set origState to synchronous
			set synchronous to true
			speak(rawText)
			set synchronous to origState
		end speakSynchronously

	end script


	tell SpeechInstance
		set its _localizationConfigName to pLocalizationConfigName
		if pLocalizationConfigName is missing value then set its _localizationConfigName to "text-to-speech_default"
		-- logger's debugf("localizationConfigName: {}", its _localizationConfigName)
	end tell

	SpeechInstance
end new


(*
	@requires the "custom text-to-speech.plist"
*)
on integrationTest()
	set sut to new(missing value)
	set quiet of sut to true

	set test to testLib's new()
	set ut to test's new()
	tell ut
		newMethod("speak")
		assertEqual("2-9 0-4", sut's speak("2904"), "Happy scenario")
		assertEqual("2906", sut's speak("2906"), "Unregistered text")
		assertEqual("2-9 0-4", sut's speak(2904), "Numbers")
		assertEqual("Q-A", sut's speak("QA"), "Exact text match")
		assertEqual("The variable s-e is not defined", sut's speak("The variable se is not defined"), "Inline text")
		assertEqual("The selenium is not defined", sut's speak("The selenium is not defined"), "Whole word selenium match")
		done()
	end tell
end integrationTest
