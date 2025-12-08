(*
	This script provides a convenient way to inject an appropriate logging instance to a library.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/Level_1/logger-factory

	@Last Modified: 2025-05-22 13:55:29
*)

use loggerLib : script "core/logger"

(*
	Injects a logging instance to a script target.
	If a logger instance is already defined, then it does nothing.

	@target - the script instance that will receive a logger instance.

	@returns boolean result of the operation.
*)
on inject(target)
	set objectName to the name of the target

	try
		if logger of target is not missing value then return
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