(*

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Keyboard Maestro/dec-keyboard-maestro-variables'

	@Created: Saturday, August 17, 2024 at 11:48:21 AM
	@Last Modified: Saturday, August 17, 2024 at 11:48:21 AM
	@Change Logs:
*)

use scripting additions

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Main
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	-- activate application ""
	set sutLib to script "core/keyboard-maestro"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		
	else if caseIndex is 3 then
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on newSpotBase()
	script SpotBaseInstance
		property template : missing value
	end script
end newSpotBase


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script KeyboardMaestroVariablesDecorator
		property parent : mainScript
		
		on getVariable(variableName)
			script RetrieveRetry
				tell application "Keyboard Maestro Engine" to getvariable variableName
			end script
			exec of retry on result for variable_update_retry_count
		end getVariable
		
		
		on getLocalVariable(variableName)
			script RetrieveRetry
				set kmInst to system attribute "KMINSTANCE"
				tell application "Keyboard Maestro Engine"
					return getvariable variableName instance kmInst
				end tell
			end script
			exec of retry on result for variable_update_retry_count
		end getLocalVariable
		
		
		on setLocalVariable(localVariableName, textValue)
			script RetrieveRetry
				set kmInst to system attribute "KMINSTANCE"
				tell application "Keyboard Maestro Engine"
					setvariable variableName to textValue instance kmInst
				end tell
			end script
			exec of retry on result for variable_update_retry_count
		end setLocalVariable
		
		
		(* This works only for KM global variables. *)
		on setVariable(variableName, newValue)
			script SetRetry
				tell application "Keyboard Maestro Engine" to setvariable variableName to newValue
				true
			end script
			exec of retry on result for variable_update_retry_count
		end setVariable
		
		
		on deleteVariable(variableName)
			script SetRetry
				tell application "Keyboard Maestro Engine" to setvariable variableName to KM_DELETE_LITERAL
				true
			end script
			exec of retry on result for variable_update_retry_count
			
		end deleteVariable
	end script
end decorate
