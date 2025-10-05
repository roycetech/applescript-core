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
		Manual: Move cursor to marker

		Manual: Move cursor lines below
		Manual: Move cursor lines above
		Manual: Move cursor to line
		Manual: Get cursor start of line
		Manual: Insertion point at first marker

		Manual: Insertion point at line
		Manual: Line number of marker text
		Manual: Adjust cursor position
		Dummy
		Dummy
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
	logger's infof("Is cursor at the start of a line: {}", sut's isCursorAtStartOfLine())
	logger's infof("Is cursor at the end of a line: {}", sut's isCursorAtEndOfLine())
	logger's infof("Has selection? {}", sut's hasSelection())
	logger's infof("Current line contents: [{}]", sut's getCurrentLineContents())
	logger's infof("Current line above contents: [{}]", sut's getLineContentsAboveCursor())
	
	
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
		
	else if caseIndex is 5 then
		set sutMarkerText to "use loggerFactory"
		logger's debugf("sutMarkerText: {}", sutMarkerText)
		
		sut's moveCursorToFirstMarker(sutMarkerText)
		
	else if caseIndex is 6 then
		set sutLinesBelowTimes to 2
		logger's debugf("sutLinesBelowTimes: {}", sutLinesBelowTimes)
		
		sut's moveCursorDownwards(sutLinesBelowTimes)
		-- sut's moveCursorLineTextStart() -- slow
		
	else if caseIndex is 7 then
		set sutLinesAboveTimes to 3
		logger's debugf("sutLinesAboveTimes: {}", sutLinesAboveTimes)
		
		sut's moveCursorUpwards(sutLinesAboveTimes)
		-- sut's moveCursorLineTextStart() -- slow
		
	else if caseIndex is 8 then
		set sutLine to -1
		set sutLine to 1
		set sutLine to 2
		set sutLine to 10
		logger's debugf("sutLine: {}", sutLine)
		
		sut's moveCursorToLine(sutLine)
		
	else if caseIndex is 9 then
		set sutLineNumber to -1
		set sutLineNumber to 1
		-- set sutLineNumber to 999
		set sutLineNumber to 2
		set sutLineNumber to 3
		logger's debugf("sutLineNumber: {}", sutLineNumber)
		
		logger's infof("Cursor at line: [{}]", sut's getCursorStartOfLine(sutLineNumber))
		
	else if caseIndex is 10 then
		set sutMarker to "Uni" & "corn"
		set sutMarker to "(*"
		logger's debugf("sutMarker: {}", sutMarker)
		
		logger's infof("Insertion point at first marker: [{}]", sut's getInsertionPointAtFirstMarker(sutMarker))
		
	else if caseIndex is 11 then
		set sutLineNumber to 0
		set sutLineNumber to 1
		-- set sutLineNumber to 2
		set sutLineNumber to 999
		logger's debugf("sutLineNumber: {}", sutLineNumber)
		
		logger's infof("Insertion point at line {}: {}", {sutLineNumber, sut's getInsertionPointAtLine(sutLineNumber)})
		
	else if caseIndex is 12 then
		set sutMarker to "Uni" & "corn"
		set sutMarker to "@Build"
		-- set sutMarker to "@"
		logger's debugf("sutMarker: {}", sutMarker)
		
		logger's infof("Line number of '{}': {}", {sutMarker, sut's getLineNumberOfMarker(sutMarker)})
		
	else if caseIndex is 13 then
		set sutCursorPositionOffset to 0
		set sutCursorPositionOffset to 1 -- ok
		-- set sutCursorPositionOffset to 2
		set sutCursorPositionOffset to -1 -- ok
		-- set sutCursorPositionOffset to -99999 -- ok
		-- set sutCursorPositionOffset to 99999  -- ok
		logger's debugf("sutCursorPositionOffset: {}", sutCursorPositionOffset)
		
		sut's adjustCursorPositionByOffset(sutCursorPositionOffset)		
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
		
		on getCursorStartOfLine(lineNumber)
			if lineNumber is less than 2 then return 0
			
			tell application "Script Editor" to tell document 1
				set textLines to paragraphs of contents
			end tell
			-- logger's debugf("Number of lines: {}", count of textLines)
			
			if lineNumber is greater than the number of textLines then return missing value
			
			(* Copied from #moveCursorToLine *)
			set charCount to 0
			repeat with i from 1 to (lineNumber - 1)
				set nextLine to item i of textLines
				-- log nextLine
				set charCount to charCount + (length of nextLine)
			end repeat
			
			charCount
		end getCursorStartOfLine
		
		
		(*
			ChatGPT.
		*)
		on moveCursorToLine(lineNumber)
			if lineNumber is less than 1 then return
			
			tell application "Script Editor" to tell document 1
				set textLines to paragraphs of contents
				if lineNumber is greater than (count of textLines) then return
				
				set charCount to 0
				repeat with i from 1 to (lineNumber - 1)
					set charCount to charCount + (length of (item i of textLines)) + 1 -- +1 for line break
				end repeat
				
				set selection to insertion point (charCount + 1)
			end tell
		end moveCursorToLine
		
		
		on moveCursorToFirstMarker(markerText)
			if running of application "Script Editor" is false then return
			
			tell application "Script Editor" to tell document 1
				set markerOffset to textUtil's indexOf(contents, markerText)
				set selection to insertion point markerOffset
			end tell
			
		end moveCursorToFirstMarker
		
		
		on getInsertionPointAtFirstMarker(markerText)
			if running of application "Script Editor" is false then return
			
			tell application "Script Editor" to tell document 1
				textUtil's indexOf(contents, markerText)
			end tell
		end getInsertionPointAtFirstMarker
		
		
		on getLineNumberOfMarker(markerText)
			tell application "Script Editor" to tell document 1
				set editorContents to contents
			end tell
			if editorContents does not contain markerText then return 0
			
			set textLines to paragraphs of editorContents
			set lineCounter to 0
			
			repeat with nextLine in textLines
				set lineCounter to lineCounter + 1
				if nextLine contains markerText then return lineCounter
				
			end repeat
			
			0
		end getLineNumberOfMarker
		
		
		on getInsertionPointAtLine(lineNumber)
			if lineNumber is less than 1 then return missing value
			if lineNumber is 1 then return 0
			
			getCursorStartOfLine(lineNumber)
		end getInsertionPointAtLine
		
		
		on moveCursorDownwards(linesBelow)
			if running of application "Script Editor" is false then return
			if linesBelow is less than 1 then return
			
			tell application "Script Editor" to tell document 1
				set editorContents to contents
			end tell
			
			set totalContentsSize to the number of characters in editorContents
			set cursorIndex to getCursorStartIndex()
			repeat linesBelow times
				set cursorIndex to cursorIndex + 1
				try
					repeat until character cursorIndex of editorContents is equal to CR
						set cursorIndex to cursorIndex + 1
					end repeat
				end try
			end repeat
			tell application "Script Editor" to tell document 1
				if cursorIndex is greater than or equal to the totalContentsSize then
					set selection to insertion point (totalContentsSize + 1)
				else
					set selection to insertion point (cursorIndex + 1)
				end if
			end tell
		end moveCursorDownwards
		
		
		on moveCursorUpwards(linesAbove)
			if running of application "Script Editor" is false then return
			if linesAbove is less than 1 then return
			
			tell application "Script Editor" to tell document 1
				set editorContents to contents
			end tell
			
			set totalContentsSize to the number of characters in editorContents
			set cursorIndex to getCursorStartIndex()
			logger's debugf("cursorIndex: {}", cursorIndex)
			
			repeat linesAbove times
				try
					repeat until (character cursorIndex of editorContents) is equal to return or (character cursorIndex of editorContents) is equal to linefeed or cursorIndex is 0
						set cursorIndex to cursorIndex - 1
					end repeat
				end try
				if cursorIndex is less than 1 then exit repeat
				
				set cursorIndex to cursorIndex - 1
			end repeat
			
			tell application "Script Editor" to tell document 1
				if cursorIndex is less than 0 then
					set selection to insertion point 0
				else
					set selection to insertion point (cursorIndex + 1)
				end if
			end tell
		end moveCursorUpwards
		
		
		on rememberCursorPosition()
			set my rememberedCursorPositionStart to getCursorStartIndex()
		end rememberCursorPosition
		
		
		on restoreCursorPosition()
			if running of application "Script Editor" is false then return
			
			tell application "Script Editor" to tell document 1
				set selection to insertion point (my rememberedCursorPositionStart)
			end tell
		end restoreCursorPosition
		
		
		(*
			Cases:
				1. Less than 0, move to beginning of file
				2. Greater than or equal to size of script, move to the end of script
				3. Positive offset
				4. Negative offset
		*)
		on adjustCursorPositionByOffset(cursorPositionOffset)
			if running of application "Script Editor" is false then return
			
			set currentCursorPosition to getCursorStartIndex()
			set newCursorPosition to currentCursorPosition + cursorPositionOffset + 1
			logger's debugf("newCursorPosition: {}", newCursorPosition)
			
			set case1or2 to false
			if newCursorPosition is less than 0 then
				set case1or2 to true
				logger's debug("Case 1")
				set newCursorPosition to 0
			end if
			
			tell application "Script Editor" to tell document 1
				set editorContents to contents
			end tell
			if newCursorPosition is greater than the (count of characters in editorContents) then
				set case1or2 to true
				logger's debug("Case 2")
				set newCursorPosition to -1
			end if
			if not case1or2 then
				if cursorPositionOffset is less than 0 then
					logger's debug("Case 4")
				else
					logger's debug("Case 3")
				end if
			end if
			
			tell application "Script Editor" to tell document 1
				set selection to insertion point newCursorPosition
			end tell
		end adjustCursorPositionByOffset
		
		
		on moveCursorToEndOfFile()
			if running of application "Script Editor" is false then return
			tell application "Script Editor" to tell document 1
				set selection to insertion point -1
				
				if contents of selection is "" then
					set contents of selection to ""
				end if
			end tell
		end moveCursorToEndOfFile
		
		
		(*
			Moves the cursor at the start of a text in the current line.
		*)
		on moveCursorLineTextStart()
			if running of application "Script Editor" is false then return
			
			(* Implementation 3: Programmatically. *)
			set currentLineContents to getCurrentLineContents()
			-- log currentLineContents
			set cursorIndexAtCurrentLine to getCursorStartOfLine(getCursorLineNumber())
			set cleanedParagraph to textUtil's ltrim(currentLineContents)
			if cleanedParagraph is "" then
				tell application "Script Editor" to tell first document
					set selection to insertion point (cursorIndexAtCurrentLine + 1)
				end tell
				return
			end if
			
			set cleanedLength to the number of characters in cleanedParagraph
			set indentSize to (count of currentLineContents) - cleanedLength
			tell application "Script Editor" to tell first document
				set selection to insertion point (cursorIndexAtCurrentLine + indentSize + 1)
			end tell
			return
			
			
			(* Implementation 2: Programmatically. Initial replacement to keystrokes. BUGGED. *)
			tell application "Script Editor" to tell document 1
				set editorContents to contents as text
				character range of selection
				item 1 of result
				set cursorStart to result as text
				set charactersCounter to 0
				
				set contentParagraphs to paragraphs of editorContents
				set idx to 0
				repeat (number of items in contentParagraphs) times
					set idx to idx + 1
					set nextParagraph to item idx of contentParagraphs
					-- log nextParagraph
					
					-- set cachedContents to contents
					-- repeat with nextParagraph in paragraphs of cachedContents -- breaks.
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
			return
			
			
			(* Implementation 1: Using keystrokes. *)
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
		
		
		on isCursorAtStartOfLine()
			set cursorStartIndex to getCursorStartIndex()
			if cursorStartIndex is 0 then return true
			
			tell application "Script Editor"
				set previousCharacter to character cursorStartIndex of contents of front document
			end tell
			previousCharacter is linefeed or previousCharacter is return
		end isCursorAtStartOfLine
		
		
		on isCursorAtEndOfLine()
			set cursorStartIndex to getCursorStartIndex()
			tell application "Script Editor" to if cursorStartIndex is equal to the number of characters in contents of front document then return true
			
			tell application "Script Editor"
				set previousCharacter to character (cursorStartIndex + 1) of contents of front document
			end tell
			previousCharacter is linefeed or previousCharacter is return
		end isCursorAtEndOfLine
		
	end script
end decorate
