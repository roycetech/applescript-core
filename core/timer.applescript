(*
	@Usage:
		use timerLib : script "core/timer"
		set timer to timerLib's new()
		timer's start()
		repeat until timer's hasExceededTimeoutSeconds(3)
			...
			delay 2
		end

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/timer

	@Created: Thu, Apr 17, 2025 at 09:33:38 PM
	@Last Modified: 2025-04-17 21:51:44
*)

use scripting additions
use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		NOOP
		Manual: After 1 seconds, timeout of 2 seconds
		Manual: After 2 seconds, timeout of 2 seconds
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)

	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()
	set sutTimeoutSeconds to 2
	if caseIndex is 1 then
		sut's start()

	else if caseIndex is 2 then
		sut's start()
		delay 1

	else if caseIndex is 3 then
		sut's start()
		delay 2
	end if

	logger's infof("sutTimeoutSeconds: {}", sutTimeoutSeconds)
	logger's infof("Has exceeded: {}", sut's hasExceededTimeoutSeconds(sutTimeoutSeconds))
	logger's infof("Elapsed time seconds: {}", sut's getElapsedTimeSeconds())

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)

	script TimerInstance
		property name : "default-timer"
		property startTime : missing value

		on start()
			set my startTime to (current date)
		end start


		on hasExceededTimeoutSeconds(timeoutSeconds)
			getElapsedTimeSeconds() is greater than or equal to timeoutSeconds
		end hasExceededTimeoutSeconds


		on getElapsedTimeSeconds()
			((current date) - startTime)
		end getElapsedTimeSeconds
	end script
end new
