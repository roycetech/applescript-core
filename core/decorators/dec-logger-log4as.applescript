(*
	@Plists:
		config-lib-factory - Add an override "LoggerSpeechAndTrackingInstance => dec-logger-speech-and-tracking" to use this as override.

	@Build:
		make compile-lib SOURCE=core/decorators/dec-logger-log4as
*)

use log4asLib : script "log4as"
use overriderLib : script "core/overrider"

property log4as : missing value

on decorate(baseScript)
	set log4as to log4asLib's new()

	script LoggerLog4ASInstance
		property parent : baseScript

		on debug(logMessage)
			if log4as's isPrintable(parent's objectName, debug of log4asLib's level) is false then return

			continue debug(logMessage)
		end debug

		on info(logMessage)
			if log4as's isPrintable(parent's objectName, info of log4asLib's level) is false then return

			continue info(logMessage)
		end info

		on warn(logMessage)
			if log4as's isPrintable(parent's objectName, warn of log4asLib's level) is false then return

			continue warn(logMessage)
		end warn

		on fatal(logMessage)
			if log4as's isPrintable(parent's objectName, ERR of log4asLib's level) is false then return

			continue fatal(logMessage)
		end warn
	end script

	set overrider to overriderLib's new()
	overrider's applyMappedOverride(LoggerLog4ASInstance)
end decorate
