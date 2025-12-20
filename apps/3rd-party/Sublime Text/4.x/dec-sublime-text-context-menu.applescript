(*
	@Purpose:
		Wanted to programmatically trigger some context menu item but the 
		context menu CANNOT be referenced in AppleScript as of Thu, Nov 20, 2025, at 10:51:22 AM.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Sublime Text/4.x/dec-sublime-text-context-menu'

	@Created: Thu, Nov 20, 2025 at 10:12:44 AM
	@Last Modified: Thu, Nov 20, 2025 at 10:12:44 AM
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Context Menu presence
	")
	
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	-- activate application ""
	set sutLib to script "core/sublime-text"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		delay 2
		logger's infof("Context menu present: {}", sut's isContextMenuPresent())
		activate
		
	else if caseIndex is 3 then
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script SublimeTextContextMenuDecorator
		property parent : mainScript
		
		on isContextMenuPresent()
			if running of application "Sublime Text" is false then return false
			
			-- tell application "System Events" to tell application process "Sublime Text"
			tell application "System Events" to tell application process "sublime_text"
				try
					return exists (menu 1 of window 1)
				end try
			end tell
			
			false
		end isContextMenuPresent
	end script
end decorate
