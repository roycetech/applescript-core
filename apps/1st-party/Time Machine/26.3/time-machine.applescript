(*
	@Requirements
		Time machine must be visible in the menu bar.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/1st-party/Time Machine/26.3/time-machine'

	@Created: Thu, Feb 26, 2026 at 10:44:10 AM
	@Last Modified: July 24, 2023 10:56 AM
*)

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Trigger Menu Bar
		Manual: Run backup now
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
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's triggerMenuBar()
		
	else if caseIndex is 3 then
		sut's runBackupNow()
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	
	script TimeMachineInstance
		(*
			Fails when menu is hidden by a 3rd party menu bar manager.
		*)
		on triggerMenuBar()
			tell application "System Events" to tell process "SystemUIServer"
				perform action "AXPress" of menu bar item 2 of menu bar 1
				delay 0.5
			end tell
			
		end triggerMenuBar
		
		
		on runBackupNow()
			triggerMenuBar()
			tell application "System Events" to tell process "SystemUIServer"
				click menu item "Back Up Now" of menu 1 of menu bar item 2 of menu bar 1
			end tell
			
			-- uiutil's printAttributeValues(result)  -- Found nothing.
		end runBackupNow
	end script
end new
