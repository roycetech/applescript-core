(*
	@Project:
		applescript-core
		
	@Build:
		make install-intellij
		
	@Created: September 9, 2023 3:06 PM
	@Last Modified: July 24, 2023 10:56 AM
*)

use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"

use spotScript : script "core/spot-test"

property logger : missing value
property kb : missing value


if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Manual: Toggle Scheme
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	if caseIndex is 1 then
		sut's toggleScheme()
		
	else if caseIndex is 2 then
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	set kb to kbLib's new()
	
	script IntelliJIDEAInstance
		(* Change to the next scheme (called theme on most other editors) *)
		on toggleScheme()
			activate application "IntelliJ IDEA CE"
			delay 0.1
			kb's pressControlKey("`")
			kb's pressKey("enter") -- Choose the "Edit Color Scheme"
			kb's pressKey("enter") -- Choose the pre-selected next theme.
			delay 0.1 -- Fails without this
			tell application "System Events" to tell process "idea"
				click (first button of window "Change IntelliJ IDEA Theme" whose description is "Yes")
			end tell
		end toggleScheme
	end script
end new
