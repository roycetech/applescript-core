(*
	TOFIX: Circular dependency to logger resulting to missing value for this script's logger.
		Appears to be fixed by doing the import inside the handler, observe if there's performance degradation.

	Update the "text-to-speech_default.plist" to add customization. This is also required for the integration testing.

	Use Samantha as the speaker for the best experience.

	@Usage:
		use speechLib : script "core/speech"
		set speech to speechLib's new(missing value)  for the default customization config.
		speech's speak("some text")

	@Known Issues:
		Do not implement a logger inside any of the non-test handlers as that would result in a circular dependency with the logging library.

	@Plists:
		text-to-speech_default

	@Testing:
		Difficult to unit test. Better to test this manually.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/speech

	@References:
		https://www.macscripter.net/t/talkin-the-talk-with-apples-speech-tools/49630
*)


use script "core/Text Utilities"
use scripting additions

use std : script "core/std"

use textUtil : script "core/string"
use regexLib : script "core/regex-pattern"
use decoratorLib : script "core/decorator"

use loggerFactory : script "core/logger-factory"

use userLib : script "core/user"
use plutilLib : script "core/plutil"
use plistBuddyLib : script "core/plist-buddy"
use mapLib : script "core/map"
use usrLib : script "core/user"

use spotScript : script "core/spot-test"

-- PROPERTIES =================================================================
property logger : missing value
property usr : missing value
property plutil : missing value

property isSpot : false

property DEFAULT_CONFIG : "text-to-speech_default"

if {"Script Editor", "Script Debugger"} contains the name of current application then
	set isSpot to true
	spotCheck()
end if

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
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

		set sut to new(missing value)
		set decoratorLib to script "core/decorator"
		set decorator to decoratorLib's new(sut)
		decorator's printHierarchy()


		sut's speak("2904")
		sut's speak("hello")

	else if caseIndex is 2 then
		set sut to new("text-to-speech_ama")
		sut's _loadTranslations()

	else if caseIndex is 3 then
		set sut to new("text-to-speech_ama")
		sut's _loadTranslations()
		logger's infof("Handler result: {}", sut's _localizeMessage("Is xlarge smaller than std?"))

	end if

	spot's finish()
	logger's finish()
end spotCheck

-- HANDLERS =================================================================

on newDefault()
	new(DEFAULT_CONFIG)
end newDefault

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

		-- This is too specific. TODO: Convert it to a passed script instead to determine silence state.
		property _userInMeetingStub : missing value

		(*
			Speak text without checking the custom pronunciations.
		*)
		on speakFreely(rawText)
			if my waitNextWords then
				say rawText
				set my waitNextWords to false

			else if my synchronous then
				say rawText

			else
				say rawText without waiting until completion
			end if
		end speakFreely


		(* @returns the translated text if present, otherwise the original text to passed. *)
		on speak(rawText)
			if not _translationsLoaded then _loadTranslations()

			(*
				User library has multiple dependencies that may conflict during spot checking so let's skip this during spot checks.
			*)
			if not isSpot then
				try
					if std's nvl(_userInMeetingStub, false) or usr's isInMeeting() then
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
				-- log "synchronous"
				say textToSpeak

			else
				-- log "asynchronous"
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
				if nextKey starts with "_" then set nextKey to text 2 thru -1 of nextKey
				-- log "nextKey: " & nextKey
				set nextValue to plistBuddy's getValue(nextKey)
				-- logger's debugf("nextValue: {}", nextValue)
				-- log "nextValue: " & nextValue
				_translationsDictionary's putValue(nextKey, nextValue)
			end repeat
		end _loadTranslations


		on _localizeMessage(message)
			-- log "localize: " & message
			set localizedMessage to message as text
			repeat with nextTranslatable in _translationKeys
				set isRegex to nextTranslatable starts with "/" and nextTranslatable ends with "/"
				-- log "isRegex: " & isRegex
				if nextTranslatable starts with "_" then set nextTranslatable to text 2 thru -1 of nextTranslatable
				-- log "nextTranslatable: " & nextTranslatable
				-- log "class: " & class of nextTranslatable

				if isRegex then
					-- log 1
					set nextTranslation to _translationsDictionary's getValue(nextTranslatable)
					set pattern to text 2 thru ((count of nextTranslatable) - 1) of nextTranslatable

					set regex to regexLib's new(pattern)
					if regex's matchesInString(localizedMessage) then
						-- logger's debugf("Translating pattern: '{}' to '{}'", {nextTranslatable, nextTranslation})
						set localizedMessage to regex's replace(localizedMessage, pattern, nextTranslation)
					end if

				else if localizedMessage contains nextTranslatable then
					-- log 2
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
	end script


	tell SpeechInstance
		set its _localizationConfigName to pLocalizationConfigName
		if pLocalizationConfigName is missing value then set its _localizationConfigName to DEFAULT_CONFIG
		-- logger's debugf("localizationConfigName: {}", its _localizationConfigName)
	end tell

	set decorator to decoratorLib's new(SpeechInstance)
	decorator's decorate()
end new
