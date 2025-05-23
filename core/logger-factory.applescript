(*
	This script provides a convenient way to inject an appropriate logging instance to a library.

	@Project:
		applescript-core

	@Build:
		make build-lib SOURCE=core/logger-factory

	@Last Modified: 2025-05-22 13:55:29
*)

use loggerLib : script "core/logger"

(*
	Injects a logging instance to a script target.
	If a logger instance is already defined, then it does nothing.

	@target - this is a script object that can have a property called useBasicLogging. If this is found and set to true, it will inject a logging instance without any overrides.

	@returns boolean result of the operation.
*)
on inject(target)
	set objectName to the name of the target

	try
		if logger of target is not missing value then return
	end try

	try
		(*
		if useBasicLogging of target is true then
			set logger of target to loggerLib's newBase(objectName)
			return true

			end if
		*)
	end try
	set logger of target to loggerLib's new(objectName)
end inject


on newBasic(objectName)
	loggerLib's newBase(objectName)
end newBasic


(*
	Injects a basic logger to the target's logger property.

	@returns true if the injection is successful.
*)
on injectBasic(target)
	set objectName to the name of the target
	try
		set logger of target to loggerLib's newBase(objectName)
	end try
end injectBasic


(*
	Shares logger property from one object to another.

	@returns true if the sharing is successful.
*)
on share(source, target)
	try
		set logger of target to the logger of source
		return true
	end try

	false
end share