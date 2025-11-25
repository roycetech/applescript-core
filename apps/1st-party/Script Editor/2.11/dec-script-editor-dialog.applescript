(*
	@Purpose:
		Handlers for responding to dialog windows.

	Used Script Debugger to interact and test against Script Editor app.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/1st-party/Script Editor/2.11/dec-script-editor-dialog'

	@Created: Thu, Oct 09, 2025 at 08:00:31 AM
	@Last Modified: Thu, Oct 09, 2025 at 08:00:31 AM
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
	set sutLib to script "core/script-editor"
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


(*  
	@mainScript ScriptEditorInstance
*)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script ScriptEditorDialogDecorator
		property parent : mainScript
		
		on respondReviewChanges()
			tell application "System Events" to tell process "Script Editor"
				click (first button of window "" whose title starts with "Review Changes")
			end tell
		end respondReviewChanges
		
		
		on respondDelete()
			tell application "System Events" to tell process "Script Editor"
				click button "Delete" of splitter group 1 of sheet 1 of front window
			end tell
		end respondDelete
	end script
end decorate
