(*
	@Purpose:
		For manipulating the state of a macro or macro group.
		
	@Project:
		applescript-core
		
	@Build:
		make build-keyboard-maestro
*)

use std : script "core/std"

use loggerFactory : script "core/logger-factory"
use listUtil : script "core/list"

use spotScript : script "core/spot-test"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: New Instance (Missing, Present)
		Manual: Enable Macro, get state
		Manual: Disable Macro, get state
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sutMacroName to "POC"	
	set sut to new(sutMacroName)
	
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
on new(pMacroName)
	loggerFactory's inject(me)
	
	set matchedMacro to missing value
	tell application "Keyboard Maestro"
		try
			set matchedMacro to first macro whose name is equal to pMacroName
		end try
	end tell
	
	if matchedMacro is missing value then error "The macro with the name: " & pMacroName & " was not found"
	
	script KeyboardMaestroMacroInstance
		property macroName : pMacroName
		property _macro : matchedMacro
		
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
		
	end script
end new
