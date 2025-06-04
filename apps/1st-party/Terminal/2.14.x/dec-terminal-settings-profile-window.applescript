(*
	@Purpose:
		Handlers for Terminal settings > Profiles > Window, with some shared handlers with Tab sub tab.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-settings-profile-window

	@Created: Mon, Jun 02, 2025 at 06:37:52 AM
	@Last Modified: Mon, Jun 02, 2025 at 06:37:52 AM
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
		Manual: Toggle Dimension Off
		Manual: Toggle Dimension On
		Manual: Toggle Active Process Name Off
		Manual: Toggle Active Process Name On

		Manual: Toggle Working Directory or Document Off
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
	
	script TerminalSettingsProfileWindowDecorator
		property parent : mainScript
		
		on toggleDimensions()
			if running of application "Terminal" is false then return
			if not isSettingsWindowPresent() then return
			
			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				try
					click checkbox "Dimensions" of tab group 1 of group 1 of settingsWindow
				end try
			end tell
		end toggleDimensions
		
		(* Need to have the settings dialog present and the Windows tab active *)
		on isDimensionsOn()
			if running of application "Terminal" is false then return false
			if not isSettingsWindowPresent() then return false
			
			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				try
					return (value of checkbox "Dimensions" of tab group 1 of group 1 of settingsWindow) is 1
				end try
			end tell
			
			false
		end isDimensionsOn
		
		on setDimensionsOn()
			if not isDimensionsOn() then toggleDimensions()
		end setDimensionsOn
		
		on setDimensionsOff()
			if isDimensionsOn() then toggleDimensions()
		end setDimensionsOff
		
		
		on toggleActiveProcessName()
			if running of application "Terminal" is false then return
			if not isSettingsWindowPresent() then return
			
			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				try
					click checkbox "Active process name" of tab group 1 of group 1 of settingsWindow
				end try
			end tell
		end toggleActiveProcessName
		
		(* Need to have the settings dialog present and the Windows tab active *)
		on isActiveProcessNameOn()
			if running of application "Terminal" is false then return false
			if not isSettingsWindowPresent() then return false
			
			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				try
					return (value of checkbox "Active process name" of tab group 1 of group 1 of settingsWindow) is 1
				end try
			end tell
			
			false
		end isActiveProcessNameOn
		
		on setActiveProcessNameOn()
			if not isActiveProcessNameOn() then toggleActiveProcessName()
		end setActiveProcessNameOn
		
		on setActiveProcessNameOff()
			if isActiveProcessNameOn() then toggleActiveProcessName()
		end setActiveProcessNameOff
		
		
		on toggleWorkingDirectoryOrDocument()
			if running of application "Terminal" is false then return
			if not isSettingsWindowPresent() then return
			
			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				try
					click checkbox "Working directory or document" of tab group 1 of group 1 of settingsWindow
				end try
			end tell
		end toggleWorkingDirectoryOrDocument
		
		(* Need to have the settings dialog present and the Windows tab active *)
		on isWorkingDirectoryOrDocumentOn()
			if running of application "Terminal" is false then return false
			if not isSettingsWindowPresent() then return false
			
			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				try
					return (value of checkbox "Working directory or document" of tab group 1 of group 1 of settingsWindow) is 1
				end try
			end tell
			
			false
		end isWorkingDirectoryOrDocumentOn
		
		on setWorkingDirectoryOrDocumentOn()
			if not isWorkingDirectoryOrDocumentOn() then toggleWorkingDirectoryOrDocument()
		end setWorkingDirectoryOrDocumentOn
		
		on setWorkingDirectoryOrDocumentOff()
			if isWorkingDirectoryOrDocumentOn() then toggleWorkingDirectoryOrDocument()
		end setWorkingDirectoryOrDocumentOff
	end script
end decorate
