(*
	@Purpose:
		For manipulating the state of a macro group.
		
	@Project:
		applescript-core
		
	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Keyboard Maestro/keyboard-maestro-macro-group'
*)

use std : script "core/std"

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Manual: New Instance (Missing, Present)
		Manual: Enable Macro Group, get state
		Manual: Disable Macro Group, get state
	")
	
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sutGroupName to "@POC"
	set sut to new(sutGroupName)
	if caseIndex is 1 then
		try
			set sut to new("POCx")
		on error
			logger's info("Passed")
		end try
		
	else if caseIndex is 2 then
		sut's enable()
		logger's infof("Enabled: {}", sut's isEnabled())
		assertThat of std given condition:sut's isEnabled() is true, messageOnFail:"Failed spot check"
		logger's info("Passed")
		
	else if caseIndex is 3 then
		sut's disable()
		logger's infof("Enabled: {}", sut's isEnabled())
		assertThat of std given condition:sut's isEnabled() is false, messageOnFail:"Failed spot check"
		logger's info("Passed")
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new(pMacroGroupName)
	loggerFactory's inject(me)
	
	set matchedMacroGroup to missing value
	tell application "Keyboard Maestro"
		try
			set matchedMacroGroup to first macro group whose name is equal to pMacroGroupName
		end try
	end tell
	
	if matchedMacroGroup is missing value then error "The macro with the name: " & pMacroGroupName & " was not found"
	
	script KeyboardMaestroMacroInstance
		property macroGroupName : pMacroGroupName
		property _macro : matchedMacroGroup
		
		on disable()
			tell application "Keyboard Maestro"
				set enabled of _macro to false
			end tell
			
		end disable
		
		on enable()
			tell application "Keyboard Maestro"
				set enabled of _macro to true
			end tell
		end enable
		
		on isEnabled()
			tell application "Keyboard Maestro"
				enabled of _macro
			end tell
		end isEnabled
		
		on isDisabled()
			not isEnabled()
		end isDisabled
		
	end script
end new
