global std

(*
	@Plists:
		config-lib-factory - Add an override "LoggerSpeechAndTrackingInstance => dec-logger-speech-and-tracking" to use this as override.
*)

property initialized : false

(* *)

on decorate(baseScript)
	init()
	
	set localLog4as to std's import("log4as")'s new()
	script LoggerLog4ASInstance
		property parent : baseScript
		prop log4as : localLog4as
		property Level : {OFF:0, IGNORE:1, DEBUG:2, INFO:3, WARN:4, ERR:5} -- WET 2/2 copy in log4as.applescript
		
		on debug(logMessage)
			if localLog4as's isPrintable(parent's objectName, DEBUG of Level) is false then return
			
			continue debug(logMessage)
		end debug

		on info(logMessage)
			if localLog4as's isPrintable(parent's objectName, INFO of Level) is false then return
			
			continue info(logMessage)
		end debug

		on warn(logMessage)
			if localLog4as's isPrintable(parent's objectName, WARN of Level) is false then return
			
			continue info(logMessage)
		end debug
	end script
	
	std's applyMappedOverride(result)
end decorate


on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
end init