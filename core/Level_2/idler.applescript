(*
	This library is used to detect if the user is idle for a given time.  Idle means the mouse pointer isn't moved and no keystrokes detected.

	@Project:
		applescript-core
		
	@Build:
		./scripts/build-lib.sh core/Level_2/idler
*)

use scripting additions

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP:
		Manual: Idle for seconds
		Manual: Is Idle
		Manual: Idle in seconds
		Manual: Activate when Idle
	")
	
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sutThreshold to 2
	logger's infof("sutThreshold: {}", sutThreshold)
	
	set sut to new(sutThreshold)
	if caseIndex is 2 then
		logger's infof("Handler result: {}", sut's isIdleFor(1))
		delay 2
		logger's infof("Handler result after 2 seconds sleep: {}", sut's isIdleFor(1))
		
	else if caseIndex is 3 then
		logger's infof("Handler result: {}", sut's isIdle())
		delay 1
		logger's infof("Handler result after 1 second: {}", sut's isIdle())
		delay 1.5
		logger's infof("Handler result after another 1 second: {}", sut's isIdle())
		
	else if caseIndex is 4 then
		logger's infof("Handler result: {}", sut's idleInSeconds())
		delay 1.5
		logger's infof("Handler result: {}", sut's idleInSeconds())
		
	else if caseIndex is 5 then
		script SpotIdleBy
			"target executed"
		end script
		set sut to new(3)
		execOnIdle of sut on SpotIdleBy by 1 for 100
		logger's infof("Handler result: {}", result)
		
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
		
		-- on execOnIdle on scriptObj by idleBy : 2 for ntimes : 1000
		on execOnIdle on scriptObj by sleep : 1 for ntimes : 1000
			-- set idler to idlerLib's new(idleBy)
			
			set iteration to 0
			set warned to false
			repeat ntimes times
				set iteration to iteration + 1
				
				-- if not idler's isIdleFor(idleBy) then
				if not isIdle() then
					-- logger's debug("not idle, sleeping...")
					if iteration mod 5 is 0 then
						set warned to true
						say "Waiting for you to idle" without waiting until completion
					end if
					delay sleep
					
				else
					try
						if warned then say "Running user interrupting task" without waiting until completion
						return run of scriptObj
					end try
				end if
			end repeat
			
			error "Unable to get you to idle"
		end execOnIdle
	end script
end new
