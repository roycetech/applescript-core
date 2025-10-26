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
		Manual: Delete line
		Manual: Has annocation
		Manual: Insert text at cursor
		Dummy
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
	
	logger's infof("Contents above cursor: [{}]", sut's getLineContentsAboveCursor())
	logger's infof("Contents at cursor: [{}]", sut's getCurrentLineContents())
	logger's infof("Contents below cursor: [{}]", sut's getLineContentsBelowCursor())
	logger's infof("Indentation size: [{}]", sut's getCurrentLineIndentationSize())
	
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
		tell application "Script Editor" to tell sutDoc to check syntax
		
	else if caseIndex is 7 then
		set sutLineNumber to 0
		set sutLineNumber to 999
		set sutLineNumber to 1
		set sutLineNumber to 2
		-- set sutLineNumber to 3
		logger's debugf("sutLineNumber: {}", sutLineNumber)
		
		(*
			Cases:
				1.  Blank line
				2.  Non-blank line
				3.  Whitespace only
		*)
		
		sut's deleteLine(sutLineNumber)
		
	else if caseIndex is 8 then
		set sutAnnotation to "unicorn"
		set sutAnnotation to "Build"
		set sutAnnotation to "Project"
		set sutAnnotation to "Script Menu"
		logger's debugf("sutAnnotation: {}", sutAnnotation)
		
		logger's infof("Has annotation: {}", sut's hasAnnotation(sutAnnotation))
		
	else if caseIndex is 9 then
		sut's insertTextAtCursor("spot text")
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script ScriptEditorContentDecorator
		(* Reference to ScriptEditorInstance *)
		property parent : mainScript
		property textView : missing value
		property windowTitle : "Temp Document"
		
		on insertTextAtCursor(textToInsert)
			if textToInsert is missing value then return
			
			tell application "Script Editor" to tell document 1
				set contents of selection to textToInsert
			end tell
		end insertTextAtCursor
		
		
		on hasAnnotation(annotation)
			if running of application "Script Editor" is false then return false
			
			getFrontContents() contains "@" & annotation
		end hasAnnotation
		
		
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
		
		
		on getCurrentLineContents()
			getContentsAtLineNumber(getCursorLineNumber())
		end getCurrentLineContents
		
		
		on getCurrentLineIndentationSize()
			set lineContents to getCurrentLineContents()
			set unindentedLine to textUtil's ltrim(lineContents)
			(the number of characters in lineContents) - (the number of characters in unindentedLine)
		end getCurrentLineIndentationSize
		
		
		on getLineContentsAboveCursor()
			set cursorLine to getCursorLineNumber()
			set previousLine to cursorLine - 1
			if previousLine is less than 1 then return missing value
			
			getContentsAtLineNumber(previousLine)
		end getLineContentsAboveCursor
		
		
		on deleteLine(lineNumber)
			if lineNumber is less than 1 then return
			if lineNumber is greater than getTotalLines() then return
			
			set deleteStart to getInsertionPointAtLine(lineNumber) + 1
			logger's debugf("deleteStart: {}", deleteStart)
			
			set lineContents to getContentsAtLineNumber(lineNumber)
			logger's debugf("lineContents: '{}'", lineContents)
			
			-- set deleteEnd to 1 + the (count of characters in lineContents) -- 1 + to include the newline character
			set deleteEnd to getInsertionPointAtLine(lineNumber + 1)
			if deleteEnd is missing value then set deleteEnd to -1
			logger's debugf("deleteEnd: {}", deleteEnd)
			
			tell application "Script Editor" to tell front document
				set selection to characters deleteStart thru deleteEnd
				set contents of selection to ""
			end tell
		end deleteLine
		
		
		on getLineContentsBelowCursor()
			set cursorLine to getCursorLineNumber()
			set nextLine to cursorLine + 1
			if nextLine is greater than getTotalLines() then return missing value
			
			getContentsAtLineNumber(nextLine)
		end getLineContentsBelowCursor
		
		
		on getContentsAtLineNumber(lineNumber)
			if lineNumber is less than 1 or lineNumber is greater than getTotalLines() then return missing value
			
			set cursorStartIndex to getCursorStartIndex()
			tell application "Script Editor"
				tell front document
					set docText to contents -- Get the full document text at once
					paragraph lineNumber of docText -- Split into lines					
				end tell
			end tell
		end getContentsAtLineNumber
		
		on hasSelection()
			tell application "Script Editor"
				tell document 1
					contents of selection is not ""
				end tell
			end tell
		end hasSelection
		
		
		on getSelectedText()
			if not hasSelection() then return missing value
			
			tell application "Script Editor"
				tell document 1
					contents of selection as text
				end tell
			end tell
		end getSelectedText
		
		
		on getTotalLines()
			tell application "Script Editor"
				tell document 1
					set totalLines to count paragraphs of contents
					if contents ends with return then set totalLines to totalLines + 1
				end tell
			end tell
			
			totalLines
		end getTotalLines
	end script
end decorate
