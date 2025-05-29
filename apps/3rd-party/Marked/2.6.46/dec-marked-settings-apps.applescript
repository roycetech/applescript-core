(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Marked/2.6.46/dec-marked-settings-apps

	@Created: Wed, May 28, 2025 at 03:54:10 PM
	@Last Modified: Wed, May 28, 2025 at 03:54:10 PM
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
		Manual: Trigger Text editor Choose Application button
		Manual: End-to-end Set Pulsar as Text Editor.
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
	set sutLib to script "core/marked"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's triggerTextEditorChooseApplication()
		
	else if caseIndex is 3 then
		activate application "Marked 2"
		sut's showSettings()
		sut's triggerTextEditorChooseApplication()
		
		set finderMiniLib to script "core/finder-mini"
		set finderMini to finderMiniLib's new("Marked 2")
		finderMini's triggerGoToFolder()
		finderMini's enterPath("/Applications/Pulsar") -- Must of course exists, untested if not.
		finderMini's acceptFoundPath()
		finderMini's chooseSelection()
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script MarkedSettingsAppsDecorator
		property parent : mainScript
		
		on triggerTextEditorChooseApplication()
			_triggerSettingsButton("Apps", "Choose Application", 1)
		end triggerTextEditorChooseApplication
	end script
end decorate
