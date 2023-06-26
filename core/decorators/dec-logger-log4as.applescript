(*
	@Plists:
		config-lib-factory - Add an override "LoggerSpeechAndTrackingInstance => dec-logger-speech-and-tracking" to use this as override.
*)

use log4asLib : script "log4as"

use overriderLib : script "overrider"

property log4as : log4asLib's new()

property overrider : overriderLib's new()

on decorate(baseScript)	
	script LoggerLog4ASInstance
		property parent : baseScript
		property level : {OFF:0, info:1, debug:2, warn:3, ERR:4} -- WET 2/2 copy in log4as.applescript
		
		on debug(logMessage)
			if log4as's isPrintable(parent's objectName, debug of level) is false then return
			
			continue debug(logMessage)
		end debug
		
		on info(logMessage)
			if log4as's isPrintable(parent's objectName, info of level) is false then return
			
			continue info(logMessage)
		end info
		
		on warn(logMessage)
			if log4as's isPrintable(parent's objectName, warn of level) is false then return
			
			continue info(logMessage)
		end warn
	end script
	
	overrider's applyMappedOverride(result)
end decorate
