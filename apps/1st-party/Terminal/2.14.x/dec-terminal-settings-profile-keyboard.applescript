(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-settings-profile-keyboard

	@Created: Mon, Jun 02, 2025 at 06:30:46 AM
	@Last Modified: Mon, Jun 02, 2025 at 06:30:46 AM
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
	set sutLib to script "core/terminal"
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


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script TerminalSettingsProfileKeyboardDecorator
		property parent : mainScript
		
		(* Under Profiles > Keyboard Subtab *)
		on isUseOptionAsMetaKeyOn()
			if running of application "Terminal" is false then return false
			if not isSettingsWindowPresent() then return false
			
			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				try
					return (value of checkbox "Use Option as Meta key" of tab group 1 of group 1 of settingsWindow) is 1
				end try
			end tell
			
			false
		end isUseOptionAsMetaKeyOn
		
		on toggleUseOptionAsMetaKey()
			if running of application "Terminal" is false then return
			if not isSettingsWindowPresent() then return
			
			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				try
					click checkbox "Use Option as Meta key" of tab group 1 of group 1 of settingsWindow
				end try
			end tell
		end toggleUseOptionAsMetaKey
		
		on setUseOptionAsMetaKeyOn()
			if not isUseOptionAsMetaKeyOn() then toggleUseOptionAsMetaKey()
		end setUseOptionAsMetaKeyOn
		
		on setUseOptionAsMetaKeyOff()
			if isUseOptionAsMetaKeyOn() then toggleUseOptionAsMetaKey()
		end setUseOptionAsMetaKeyOff
			end script
end decorate
