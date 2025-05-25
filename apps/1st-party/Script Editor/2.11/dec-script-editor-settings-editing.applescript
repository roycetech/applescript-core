(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/1st-party/Script Editor/2.11/dec-script-editor-settings-editing'

	@Created: Sat, May 24, 2025 at 08:22:35 AM
	@Last Modified: Sat, May 24, 2025 at 08:22:35 AM
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
		Manual: Suggest completions while typing ON
		Manual: Suggest completions while typing OFF
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
	set sutLib to script "core/script-editor"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	logger's infof("Suggest completions while typing: {}", sut's isSuggestCompletionsWhileTyping())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's setSuggestCompletionsWhileTypingOn()
		
	else if caseIndex is 3 then
		sut's setSuggestCompletionsWhileTypingOff()
		
	else if caseIndex is 4 then
		
	else if caseIndex is 5 then
				
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script ScriptEditorSettingsEditingDecorator
		property parent : mainScript
		
		on isSuggestCompletionsWhileTyping()
			if running of application "Script Editor" is false then return
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			
			switchSettingsTab("Editing")
			tell application "System Events" to tell process "Script Editor"
				try
					return value of checkbox "Suggest completions while typing" of settingsWindow is 1
				end try
			end tell
			
			false
		end isSuggestCompletionsWhileTyping
		
		
		on setSuggestCompletionsWhileTypingOn()
			if isSuggestCompletionsWhileTyping() then return
			
			_toggleSettingsCheckbox("Editing", "Suggest completions while typing")
		end setSuggestCompletionsWhileTypingOn
		
		on setSuggestCompletionsWhileTypingOff()
			if not isSuggestCompletionsWhileTyping() then return
			
			_toggleSettingsCheckbox("Editing", "Suggest completions while typing")
		end setSuggestCompletionsWhileTypingOff
	end script
end decorate
