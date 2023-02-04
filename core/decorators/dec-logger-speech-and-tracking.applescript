global std, speech

(*
	@Plists:
		config-lib-factory - Add an override "LoggerInstance => dec-logger-speech-and-tracking" to use this as override.

	Compile:
		make compile-lib SOURCE=core/decorators/dec-logger-speech-and-tracking
*)

property initialized : false

(* *)

on decorate(baseScript)
	init()
	
	script LoggerSpeechAndTrackingInstance
		property parent : baseScript
		
		on fatal(logMessage)
			continue fatal(logMessage)
			
			if logMessage does not contain "User canceled" then
				if (count of characters of logMessage) is less than 141 then speech's speak(logMessage)
			end if
		end fatal
	end script
	
	std's applyMappedOverride(result)
end decorate


on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set speech to std's import("speech")'s new()
end init