(*
	@Plists:
		config-lib-factory - Add an override "LoggerInstance => dec-logger-speech-and-tracking" to use this as override.

	@Project:
		applescript-core

	Build:
		make build-lib SOURCE=core/decorators/dec-logger-speech-and-tracking
*)

use speechLib : script "core/speech"
use decoratorLib : script "core/decorator"

property speech : missing value

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
	set speech to speechLib's new()

	script LoggerSpeechAndTrackingInstance
		property parent : baseScript

		on fatal(logMessage)
			continue fatal(logMessage)

			if logMessage does not contain "User canceled" then
				if (count of characters of logMessage) is less than 141 then speech's speak(logMessage)
			end if
		end fatal
	end script

	set decorator to decoratorLib's new(result)
	decorator's decorate()
end decorate
