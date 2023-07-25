(*
	This library is used to detect if the user is idle for a given time.

	@Build:
		make compile-lb SOURCE=core/idler
*)

use scripting additions

use loggerFactory : script "logger-factory"

use listUtil : script "list"
use spotScript : script "spot-test"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)

	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Idle for seconds
		Manual: Is Idle
		Manual: Idle in seconds
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sutThreshold to 2
	set sut to new(sutThreshold)
	if caseIndex is 1 then
		logger's infof("Handler result: {}", sut's isIdleFor(1))
		delay 2
		logger's infof("Handler result after 2 seconds sleep: {}", sut's isIdleFor(1))

	else if caseIndex is 2 then
		logger's infof("Handler result: {}", sut's isIdle())
		delay 1
		logger's infof("Handler result after 1 second: {}", sut's isIdle())
		delay 1.5
		logger's infof("Handler result after another 1 second: {}", sut's isIdle())

	else if caseIndex is 3 then
		logger's infof("Handler result: {}", sut's idleInSeconds())
		delay 1.5
		logger's infof("Handler result: {}", sut's idleInSeconds())

	end if

	spot's finish()
	logger's finish()
end spotCheck


on new(pAwayThresholdSeconds)
	script IdlerInstance
		property awayThresholdSeconds : pAwayThresholdSeconds

		on isIdleFor(threshold)
			idleInSeconds() is greater than threshold
		end isIdleFor

		on isIdle()
			isIdleFor(awayThresholdSeconds)
		end isIdle

		(* Very lightweight operation, you may invoke as frequently as you like. *)
		on idleInSeconds()
			do shell script "ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print $NF/1000000000; exit}'"
			result as real
		end idleInSeconds
	end script
end new
