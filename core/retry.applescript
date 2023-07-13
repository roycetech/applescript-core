(*
	@Usage:
		use retryLib : script "retry"
		property retry : retryLib's new()
			
	@Build:
		make compile-lib SOURCE=core/retry
*)

use scripting additions

use loggerFactory : script "logger-factory"
use listUtil : script "list"
use spotScript : script "spot-test"
use idlerLib : script "idler"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me, "retry")
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: Activate when Idle
		Manual: Exhaust retry
		Manual: Success on retry
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	if caseIndex is 1 then
		script SpotIdleBy
			"target executed"
		end script
		set sut to new()
		log (execOnIdle of sut on SpotIdleBy by 3 for 100)
		
	else if caseIndex is 2 then
		script SpotExhaust
			property counter : 0
			
			set counter to counter + 1
			if counter < 5 then error "failed"
			"won't get printed"
		end script
		set sut to new()
		log (exec of sut on SpotExhaust by 1 for 3) -- expected missing value
		
	else if caseIndex is 3 then
		script SpotSuccess
			property counter : 0
			
			set counter to counter + 1
			if counter < 3 then error "failed"
			"success"
		end script
		set sut to new()
		log (exec of sut on SpotSuccess by 1 for 3) -- expected "success"
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's injectBasic(me, "retry")
	script RetryInstance
		on execOnIdle on scriptObj by idleBy : 2 for ntimes : 1000
			set idler to idlerLib's new(idleBy)
			
			set iteration to 0
			set warned to false
			repeat ntimes times
				set iteration to iteration + 1
				
				if not idler's isIdleFor(idleBy) then
					logger's debug("not idle, sleeping...")
					if iteration mod 5 is 0 then
						set warned to true
						say "Waiting for you to idle" without waiting until completion
					end if
					delay 1
				else
					try
						if warned then say "Running user interrupting task" without waiting until completion
						return run of scriptObj
					end try
				end if
			end repeat
			
			error "Unable to get you to idle"
		end execOnIdle
		
		
		(* 
			@scriptObj a simple script object (run handler only). 
			@sleep optional delay in seconds per iteration.
			@ntimes optional maximum times to retry.
	
			@return a value from the execute handler. missing value or No result will 
		trigger a delay and a retry.
		*)
		on exec on scriptObj by sleep : 1 for ntimes : 1000
			repeat ntimes times
				try
					set handlerResult to run of scriptObj
					if handlerResult is not missing value then return handlerResult
				on error the errorMessage number the errorNumber
					if errorMessage contains "is not allowed assistive access" or errorMessage is "abort" then
						error errorMessage
						exit repeat
					end if
				end try
				delay sleep
			end repeat
			return missing value
		end exec
	end script
end new


property targetUis : {}
property targetUiNames : {}

(* To test if working *)
on wait on theUi for nseconds
	repeat nseconds times
		if theUi exists then return true
		delay 1
	end repeat
	
	return false
end wait
