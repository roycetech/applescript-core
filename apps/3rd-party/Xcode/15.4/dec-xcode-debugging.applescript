(*

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Xcode/15.4/dec-xcode-debugging

	@Created: Friday, August 2, 2024 at 5:42:38 PM
	@Last Modified: 2024-12-31 19:32:59
	@Change Logs:
*)
use listUtil : script "core/list"
use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Manual: Resume
		Manual: Step Over
		Manual: Step Into
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	-- activate application ""
	set sutLib to script "core/xcode"
	set sut to sutLib's new()
	set sut to decorate(sut)

	if caseIndex is 1 then
		sut's resume()

	else if caseIndex is 2 then
		sut's stepOver()

	else if caseIndex is 3 then
		sut's stepInto()

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script XcodeDecorator
		property parent : mainScript

		on resume()
			if running of application "Xcode" is false then return

			tell application "System Events" to tell process "Xcode"
				set frontmost to true
				try
					click menu item "Continue" of menu 1 of menu bar item "Debug" of menu bar 1
				end try
			end tell
		end resume

		on stepOver()
			if running of application "Xcode" is false then return

			tell application "System Events" to tell process "Xcode"
				set frontmost to true
				try
					click menu item "Step Over" of menu 1 of menu bar item "Debug" of menu bar 1
				end try
			end tell
		end stepOver

		on stepInto()
			if running of application "Xcode" is false then return

			tell application "System Events" to tell process "Xcode"
				set frontmost to true
				try
					click menu item "Step Into" of menu 1 of menu bar item "Debug" of menu bar 1
				end try
			end tell
		end stepInto
	end script
end decorate
