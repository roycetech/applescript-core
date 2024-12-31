(*

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/zoom.us/6.0.x/dec-zoom-authentication

	@Created: Wed, Aug 14, 2024 at 10:20:40 AM
	@Last Modified: 2024-12-31 19:33:18
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
		NOOP: Info
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	-- activate application ""
	set sutLib to script "core/zoom"
	set sut to sutLib's new()
	set sut to decorate(sut)

	logger's infof("Logged in?: {}", sut's isLoggedIn())
	logger's infof("Login form present: {}", sut's isLoginFormPresent())
	if caseIndex is 1 then

	else if caseIndex is 2 then

	else if caseIndex is 3 then

	else if caseIndex is 4 then

	else if caseIndex is 5 then

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script ZoomMeetingDecorator
		property parent : mainScript

		on isLoggedIn()
			if running of application "zoom.us" is false then return false

			tell application "System Events" to tell process "zoom.us"
				not (exists window "Login")
			end tell
		end isLoggedIn

		on isLoginFormPresent()
			if running of application "zoom.us" is false then return false

			tell application "System Events" to tell process "zoom.us"
				first text field of group 1 of windows whose description is "Email"
				first item of result is not missing value
			end tell
		end isLoginFormPresent
	end script
end decorate
