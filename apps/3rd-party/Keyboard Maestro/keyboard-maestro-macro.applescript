(*
	@Purpose:
		For manipulating the state of a macro or macro group.
		
	@Usage:
		use keyboardMaestroMacroLib : script "core/keyboard-maestro-macro"
		set keyboardMaestroMacro to keyboardMaestroMacroLib's new(<macro-name>)
		keyboardMaestroMacro's disable()

	@Project:
		applescript-core
		
	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Keyboard Maestro/keyboard-maestro-macro'
		
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
		Manual: Enable Macro, get state
		Manual: Disable Macro, get state
		Manual: Find By Name Containing		
		Manual: Disable Macro

		Manual: Enable Macro
	")
	
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sutMacroName to "POC: _AppleScript Core Test Macro"
	set sut to new(sutMacroName)
	logger's infof("sutMacroName: {}", sutMacroName)
	logger's infof("Macro UUID: {}", sut's getUUID())
	
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
		
	else if caseIndex is 4 then
		-- log findMacroWithTitleContaining("Unicorn")
		set spotInstance to findMacroWithTitleContaining("dia's showChoicesWithTimeout(")
		if spotInstance is not missing value then
			logger's info("A macro was found")
		else
			logger's info("No macro was found")
		end if
		
	else if caseIndex is 5 then
		sut's disable()

	else if caseIndex is 6 then
		sut's enable()
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on findMacroWithTitleContaining(macroKeyword)
	log macroKeyword
	tell application "Keyboard Maestro"
		try
			return my new(name of first macro whose name contains macroKeyword)
		on error the errorMessage number the errorNumber
			log errorMessage
		end try
	end tell
	
	missing value
end findMacroWithTitleContaining


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
		
		
		on getUUID()
			tell application "Keyboard Maestro"
				id of _macro
			end tell
		end getUUID
		
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
