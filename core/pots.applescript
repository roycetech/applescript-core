global std, config, textUtil, regex, switch
global TRANS_CONFIG

(*
	personal ordinary text speaker.
	Update the "custom text-to-speech.plist" to add customization.

	Use Samantha as the speaker for the bes experience.

TODO: 
	- Add optional parameter
*)

-- PROPERTIES =================================================================
property initialized : false
property logger : missing value
property quiet : false
property synchronous : false
property waitNextWords : false -- Same purpose as speakSynchronously()
property logging : true

if name of current application is "Script Editor" then spotCheck() 

to spotCheck()
	init()
	logger's start()
	
	-- unitTest()
	
	speak("Deploying...")
	-- speak("hello")
	
	
	
	logger's finish()
end spotCheck


-- HANDLERS =================================================================

to speak(rawText as text)
	if switch's active("Meeting in Progress") then
		logger's info("SILENCED: " & rawText)
		return
	end if
	
	set textToSpeak to rawText
	
	if TRANS_CONFIG is missing value then
		logger's warn("Text to Speech configuration is missing.")
	else
		set translatables to TRANS_CONFIG's getValue("raw")
		set translations to TRANS_CONFIG's getValue("translated")
	end if
	
	
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


to speakAndLog(rawText as text)
	speak(rawText)
	if synchronous then
		set prefix to "S+ "
	else
		set prefix to "S* "
	end if
	logger's info(prefix & rawText)
end speakAndLog


to speakSynchronously(rawText as text)
	if logging then logger's info("S+ " & rawText)
	
	set origState to synchronous
	set synchronous to true
	speak(rawText)
	set synchronous to origState
end speakSynchronously


to speakSynchronouslyWithLogging(rawText as text)
	logger's info(rawText)
	speakSynchronously(rawText)
end speakSynchronouslyWithLogging


-- Private Codes below =======================================================

to unitTest()
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
	if initialized of me then
		set category of config to "work"
		return
	end if
	
	set initialized of me to true
	
	set std to script "std"
	
	set my quiet to false
	set logger to std's import("logger")'s new("pots")
	set config to std's import("config")
	set textUtil to std's import("string")
	set regex to std's import("regex")
	set switch to std's import("switch")
	set plutil to std's import("plutil")'s new()
	
	try
		set TRANS_CONFIG to plutil's new("custom text-to-speech")
	on error
		set TRANS_CONFIG to missing value
	end try
end init