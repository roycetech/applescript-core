global std, textUtil, regex
global TRANS_CONFIG

(*
	TODO: Refactor, simplify.
	TOFIX: Circular dependency to logger resulting to missing value for this script's logger.
		Appears to be fixed by doing the import inside the handler, observe if there's performance degradation.

	Update the "custom text-to-speech.plist" to add customization.

	Use Samantha as the speaker for the best experience.

TODO: 
	- Add optional parameter
*)

-- PROPERTIES =================================================================
property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	logger's start()
	
	
	set sut to new()
	-- unitTest()
	
	sut's speak("Deploying...")
	-- speak("hello")
	
	
	
	logger's finish()
end spotCheck


-- HANDLERS =================================================================

on new()
	script SpeechInstance
		
		property quiet : false
		property synchronous : false
		property waitNextWords : false -- Same purpose as speakSynchronously()
		property logging : true
		
		on speak(rawText as text)
			try
				set usr to std's import("user")'s new()
				if usr's isInMeeting() then
					logger's info("SILENCED: " & rawText)
					return
				end if
			on error the errorMessage number the errorNumber -- ignore if user script is not installed.
				logger's warn(errorMessage)
				return
			end try
			
			set textToSpeak to rawText
			
			try
				if TRANS_CONFIG is missing value then
					logger's warn("Text to Speech configuration is missing.")
				else
					set translatables to TRANS_CONFIG's getValue("raw")
					set translations to TRANS_CONFIG's getValue("translated")
				end if
			on error -- undefined during system error catching
				set TRANS_CONFIG to missing value
				set translatables to {}
			end try
			
			
			if TRANS_CONFIG is missing value or translatables is missing value then set translatables to {}
			
			repeat with idx from 1 to count of translatables
				set nextTranslatable to item idx of translatables
				set nextTranslation to item idx of translations
				set isRegex to nextTranslatable starts with "/" and nextTranslatable ends with "/"
				if isRegex then
					set pattern to text 2 thru ((count of nextTranslatable) - 1) of nextTranslatable
					
					if regex's matchesInString(pattern, textToSpeak) then
						-- if regex's matched(textToSpeak, pattern) then
						set textToSpeak to regex's replace(textToSpeak, pattern, nextTranslation)
					end if
				else if textToSpeak contains nextTranslatable then
					set textToSpeak to textUtil's replace(textToSpeak, nextTranslatable, nextTranslation)
				end if
			end repeat
			
			if my quiet then return textToSpeak
			
			if my waitNextWords then
				say textToSpeak
				set my waitNextWords to false
			else if my synchronous then
				say textToSpeak
			else
				say textToSpeak without waiting until completion
			end if
			
			return textToSpeak
		end speak
		
		
		on speakAndLog(rawText as text)
			speak(rawText)
			if synchronous then
				set prefix to "S+ "
			else
				set prefix to "S* "
			end if

			if logger is missing value then set logger to std's import("logger")'s new("speech") -- weird error.

			logger's info(prefix & rawText)
		end speakAndLog
		
		
		on speakSynchronously(rawText as text)
			if logging then 
				set logger to std's import("logger")'s new("speech") -- bandaid
				logger's info("S+ " & rawText)
			end if

			set origState to synchronous
			set synchronous to true
			speak(rawText)
			set synchronous to origState
		end speakSynchronously
		
		
		on speakSynchronouslyWithLogging(rawText as text)
			logger's info(rawText)
			speakSynchronously(rawText)
		end speakSynchronouslyWithLogging
	end script
end new




-- Private Codes below =======================================================

on unitTest()
	set my quiet to true
	
	set actual101 to speak("2904")
	set case101 to "Case 101: Happy scenario"
	std's assert("2-9 0-4", actual101, case101)
	
	set actual102 to speak("2906")
	set case102 to "Case 102: Unrecognized text"
	std's assert("2906", actual102, case102)
	
	set actual103 to speak(2904)
	set case103 to "Case 103: Numbers"
	std's assert("2-9 0-4", actual103, case103)
	
	set actual104 to speak("QA")
	set case104 to "Case 104: Exact text match"
	std's assert("Q-A", actual104, case104)
	
	set actual105 to speak("The variable se is not defined")
	set case105 to "Case 105: Inline text"
	std's assert("The variable s-e is not defined", actual105, case105)
	
	set actual105b to speak("The selenium is not defined")
	set case105b to "Case 105b: Whole word selenium match"
	std's assert("The selenium is not defined", actual105b, case105b)
	
	
	logger's info("All unit test cases passed.")
	
	set my quiet to false
end unitTest


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	
	set my quiet to false
	set logger to std's import("logger")'s new("speech")
	set textUtil to std's import("string")
	set regex to std's import("regex")
	set switch to std's import("switch")
	set plutil to std's import("plutil")'s new()
	set usr to std's import("user")'s new()
	
	try
		set TRANS_CONFIG to plutil's new("custom text-to-speech")
	on error
		set TRANS_CONFIG to missing value
	end try
end init