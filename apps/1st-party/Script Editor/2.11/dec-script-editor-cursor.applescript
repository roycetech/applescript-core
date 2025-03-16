(*
	@Purpose:
		To help simplify manipulation of the contents of the script editor.
	
	@TODO:
		Move to tab (document)-level.
	
	@NOTE: Cursor position is 0-indexed.
	
	

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/1st-party/Script Editor/2.11/dec-script-editor-cursor'

	@Created: Thu, Mar 06, 2025 at 06:29:04 AM
	@Last Modified: Thu, Mar 06, 2025 at 06:29:04 AM
	@Change Logs:
*)
use scripting additions

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Main
		Manual: Line number at index
	")
	
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
	
	logger's infof("Cursor line number: {}", sut's getCursorLineNumber())
	logger's infof("Cursor start index: {}", sut's getCursorStartIndex())
	logger's infof("Cursor end index: {}", sut's getCursorEndIndex())
	logger's infof("Total lines: {}", sut's getTotalLines())
	logger's infof("Is cursor on final line?: {}", sut's isCursorOnFinalLine())
	logger's infof("Has selection? {}", sut's hasSelection())
	logger's infof("Current line contents: [{}]", sut's getCurrentLineContents())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		set sutLineNumber to -1
		set sutLineNumber to 2
		logger's infof("sutLineNumber: {}", sutLineNumber)
		
		logger's infof("Line at line number: [{}]", sut's getContentsAtLineNumber(sutLineNumber))
		
	else if caseIndex is 3 then
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script ScriptEditorCursorDecorator
		property parent : mainScript
		
		
		on getCurrentLineContents()
			getContentsAtLineNumber(getCursorLineNumber())
		end getCurrentLineContents
		
		
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
		
		
		on getCursorStartIndex()
			tell application "Script Editor"
				tell document 1
					character range of selection
					first item of result
				end tell
			end tell
		end getCursorStartIndex
		

		on getCursorEndIndex()
			tell application "Script Editor"
				tell document 1
					set totalLines to count paragraphs of contents
					character range of selection
					first item of result
				end tell
			end tell
		end getCursorEndIndex
		
		
		on hasSelection()
			tell application "Script Editor"
				tell document 1
					contents of selection is not ""
				end tell
			end tell
		end hasSelection
		
		
		on getTotalLines()
			tell application "Script Editor"
				tell document 1
					set totalLines to count paragraphs of contents
					if contents ends with (ASCII character 13) then set totalLines to totalLines + 1
				end tell
			end tell
			
			totalLines
		end getTotalLines
		
		
		on getCursorLineNumber()
			set cursorStartIndex to getCursorStartIndex()
			tell application "Script Editor"
				tell front document
					set docText to contents -- Get the full document text at once
					set lineList to paragraphs of docText -- Split into lines
					
					set charCounter to 0
					set lineCounter to 0
					
					repeat with nextLine in lineList
						set lineCounter to lineCounter + 1
						set charCounter to charCounter + (length of nextLine) + 1 -- Account for newline
						
						if charCounter > cursorStartIndex then return lineCounter
					end repeat
					
				end tell
			end tell
			
			getTotalLines()
		end getCursorLineNumber
		
		
		on isCursorOnFinalLine()
			getCursorLineNumber() is equal to getTotalLines()
		end isCursorOnFinalLine
		
	end script
end decorate
