(*
	@Plists:
		config-lib-factory - Add an override "LoggerInstance => dec-logger-speech-and-tracking" to use this as override.

	Compile:
		make compile-lib SOURCE=core/decorators/dec-logger-speech-and-tracking
*)

use speechLib : script "core/speech"
use overriderLib : script "core/overrider"

property speech : speechLib's new(missing value)
property overrider : overriderLib's new()

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	set sut to decorate(newSpotBase())
	sut's fatal("hello")
end spotCheck


on newSpotBase()
	script SpotBaseInstance
		on fatal(logMessage)
			log "spot fatal: " & logMessage
		end fatal
	end script
end newSpotBase

(* *)
on decorate(baseScript)
	script LoggerSpeechAndTrackingInstance
		property parent : baseScript

		on fatal(logMessage)
			continue fatal(logMessage)

			if logMessage does not contain "User canceled" then
				if (count of characters of logMessage) is less than 141 then speech's speak(logMessage)
			end if
		end fatal
	end script

	overrider's applyMappedOverride(result)
end decorate
