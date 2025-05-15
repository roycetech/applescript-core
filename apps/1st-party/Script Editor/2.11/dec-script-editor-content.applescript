(*
	Used for automating insertion of variables into different sections in the code. Follows a specific user code style.

	TODO: Unit Test

	@Project:
		applescript-core
		
	@Build:
		./scripts/build-lib.sh 'apps/1st-party/Script Editor/2.11/dec-script-editor-content'

	@Created: Wednesday, July 26, 2023 at 6:33:55 PM
	@Last Modified: July 26, 2023 9:49 PM
*)
use scripting additions

use textUtil : script "core/string"
use loggerFactory : script "core/logger-factory"

property logger : missing value

property CR : ASCII character 13

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: New Document
		Manual: Write Script Library Code to Temp Document
		Manual: Insert text after line with text
		Manual: Write User Script Code to Temp Document

		Manual: Insert text after last line with text
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
		sut's createTempDocument("Spot Check")
		
	else if caseIndex is 3 then
		set sutDoc to sut's createTempDocument("Spot Check")
		sut's writeDataToTempDocument("(* Test Data *)
			
property logger : missing value
property session : missing value
		
on spotCheck()
	loggerFactory's inject(me)
	
	log 1
end spotCheck
				
on new()
	loggerFactory's inject(me)
	set retry to retryLib's new()
			
	script Test
	end script
end new
		")
		tell application "Script Editor"
			tell sutDoc to check syntax
		end tell
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script ScriptEditorContentDecorator
		property parent : mainScript
		property textView : missing value
		property windowTitle : "Temp Document"
		
		on createTempDocument(documentName)
			local loggerPath
			set my windowTitle to documentName
			set loggerPath to ((path to temporary items from user domain) as text) & documentName
			try -- to reuse an existing window
				tell application id "com.apple.ScriptEditor2"
					set my textView to get document (my windowTitle)
					set my textView's window's index to 1 -- bring to front
				end tell
			on error -- create a new document
				tell application id "com.apple.ScriptEditor2"
					save (make new document) in file loggerPath as "text"
					set my textView to document (my windowTitle)
				end tell
			end try
			my textView
		end createTempDocument
		
		on writeDataToTempDocument(textContent)
			using terms from application "Script Editor"
				tell my textView
					set selection to insertion point -1
					set contents of selection to textContent
				end tell
			end using terms from
		end writeDataToTempDocument
	end script
end decorate
