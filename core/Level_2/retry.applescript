(*
	@Usage:
		use retryLib : script "core/retry"
		property retry : retryLib's new()

	TODO: Move idler out and promote to a Level 2 script.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/Level_2/retry

	@Change Logs:
		Mon, Dec 08, 2025, at 01:47:43 PM - Moved out idler dependency.
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
		NOOP
		Manual: Exhaust retry
		Manual: Success on retry
	")
	
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	if caseIndex is 2 then
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
	loggerFactory's injectBasic(me)
	script RetryInstance
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
