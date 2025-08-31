(*
	@Purpose:
		To help simplify manipulation of the contents of the script editor.
	
	@TODO:
		Move to tab (document-level).
	
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

use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"

property logger : missing value
property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Main
		Manual: Line number at index
		Manual: Move cursor to the beginning of line (not space)
		Manual: Move cursor to the EOF
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
	logger's infof("Current line above contents: [{}]", sut's getLineAboveContents())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		set sutLineNumber to -1
		set sutLineNumber to 2
		logger's infof("sutLineNumber: {}", sutLineNumber)
		
		logger's infof("Line at line number: [{}]", sut's getContentsAtLineNumber(sutLineNumber))
		
	else if caseIndex is 3 then
		sut's moveCursorLineTextStart()
		
	else if caseIndex is 4 then
		sut's moveCursorToEndOfFile()
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set kb to kbLib's new()
	
	script ScriptEditorCursorDecorator
		property parent : mainScript
		property rememberedCursorPositionStart : missing value
		
		on rememberCursorPosition()
			set my rememberedCursorPositionStart to getCursorStartIndex()
		end rememberCursorPosition
		
		
		on restoreCursorPosition()
			if running of application "Script Editor" is false then return
			
			tell application "Script Editor" to tell document 1
				set selection to insertion point (my rememberedCursorPositionStart)
			end tell
		end restoreCursorPosition
		
		
		on moveCursorToEndOfFile()
			tell application "Script Editor"
				tell document 1
					set selection to insertion point -1
					
					if contents of selection is "" then
						set contents of selection to ""
					end if
				end tell
			end tell
		end moveCursorToEndOfFile
		
		on moveCursorLineTextStart()
			(* Programmatically, newer code than keystrokes. *)
			tell application "Script Editor"
				tell document 1
					character range of selection
					item 1 of result
					set cursorStart to result as text
					set charactersCounter to 0
					repeat with nextParagraph in paragraphs of contents
						set nextParagraphLen to the (count of characters in nextParagraph)
						if charactersCounter + nextParagraphLen is greater than cursorStart then
							set cleanedParagraph to textUtil's ltrim(nextParagraph as text)
							set cleanedLength to the number of characters in cleanedParagraph
							set indentSize to nextParagraphLen - cleanedLength
							set selection to insertion point (charactersCounter + indentSize + 1)
							exit repeat
						end if
						set charactersCounter to charactersCounter + nextParagraphLen
					end repeat
				end tell
			end tell
			return
			
			
			(* Using keystrokes. *)
			set currentLine to getCurrentLineContents()
			set cleanLine to textUtil's trim(currentLine)
			set spaces to textUtil's stringBefore(currentLine, cleanLine)
			if spaces is missing value then set spaces to ""
			set delayAfterKeySeconds of kb to 0
			kb's pressCommandKey("left")
			repeat the number of characters in spaces times
				kb's pressKey("right")
			end repeat
			
			
			
		end moveCursorLineTextStart
		
		
		on getCurrentLineContents()
			getContentsAtLineNumber(getCursorLineNumber())
		end getCurrentLineContents
		
		on getLineAboveContents()
			set cursorLine to getCursorLineNumber()
			set previousLine to cursorLine - 1
			if previousLine is less than 1 then return missing value
			
			getContentsAtLineNumber(previousLine)
		end getLineAboveContents
		
		
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
					last item of result
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
