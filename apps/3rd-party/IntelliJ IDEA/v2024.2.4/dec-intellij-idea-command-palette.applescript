(*
	@Purpose:


	@Requirements:
		Disable the default hotkey on macOS to open manual in Terminal.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/IntelliJ IDEA/v2024.2.4/dec-intellij-idea-command-palette'

	@Created: Thu, Jul 10, 2025 at 06:56:46 AM
	@Last Modified: Thu, Jul 10, 2025 at 06:56:46 AM
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"
use kbLib : script "core/keyboard"

property logger : missing value

property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Trigger Search Action
		Manual: Run Command: Mute Breakpoints
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
	set sutLib to script "core/intellij-idea"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's triggerSearchAction()
		
	else if caseIndex is 3 then
		(*
		sut's triggerSearchAction()
		kb's typeText("Mute Breakpoints")
		kb's pressKey(return)
		delay 1
		kb's pressKey("esc")
*)
		sut's runCommand("Mute Breakpoints")
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set kb to kbLib's new()
	
	script IntellijIdeaCommandPaletteDecorator
		property parent : mainScript
		
		(*
			Acquires window focus.
		*)
		on triggerSearchAction()
			if running of application (parent's intellijAppName) is false then return
			
			tell application "System Events" to tell process (my _getProcessName())
				set frontmost to true
			end tell
			kb's pressShiftCommandKey("a")
			delay 1
		end triggerSearchAction
		
		
		on runCommand(commandKeywords)
			if running of application (parent's intellijAppName) is false then return
			
			triggerSearchAction()
			
			enterCommand(commandKeywords)
			delay 1
			kb's pressKey("esc")
		end runCommand
		
		
		on enterCommand(commandKeywords)
			kb's typeText(commandKeywords)
			kb's pressKey(return)
		end enterCommand
	end script
end decorate
