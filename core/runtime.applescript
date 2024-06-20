(*
	Provide runtime information.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/runtime

	@Created: Wednesday, June 12, 2024 at 10:51:51 AM
	@Last Modified: 2024-06-12 11:02:52
*)

use AppleScript version "2.8"
use scripting additions
use framework "Foundation"

use loggerFactory : script "core/logger-factory"

property processInfo : class "NSProcessInfo"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set sut to new()
	logger's infof("Handler result: {}", sut's getName())

	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	set processInfo to current application's NSProcessInfo's processInfo()

	script RuntimeInstance
		(*
			@returns:
				Script Menu - osascript
				Script Editor
		*)
		on getName()
			processInfo's processName() as string
		end getName
	end script
end new
