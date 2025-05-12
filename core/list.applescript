(*
	@Usage:
		use listUtil : script "core/list"

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/list

	@Change Logs:
		Sat, Mar 29, 2025 at 09:01:37 PM - Added #splitByParagraph which uses a natural way to split lines.
*)

use scripting additions

use std : script "core/std"
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

property logger : missing value

property LF : ASCII character 10
property CR : ASCII character 13

property ERROR_LIST_COUNT_INVALID : 1000
property ERROR_OUT_OF_BOUNDS : 1001

-- #%+= are probably worth considering.
property linesDelimiter : "@"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to splitByLine("
		NOOP
		Split By Line (TODO: presence of single quote results in error)
		Trailing empty line
		Split with trim
		Split Map

		Split By Line with Illegal Character
		Split using /
		Split Web Domain
		Split Shell Command Result By Line
		Split By Line / Index Of

		Split By Line - With Dollar Sign
		Split By Paragraph
		Split By Paragraph with Trim
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	if caseIndex is 1 then

	else if caseIndex is 2 then
		log (count of splitByLine("
			1a
			2x
			me, myself, and Irene
			fxve
		"))

		log splitByLine("
			ts: TypeScript
			md: Markdown
		")

	else if caseIndex is 3 then
		log (count of splitByLine("
		1a
		2x

	"))

	else if caseIndex is 4 then
		log _split("a, o, 34, unit break", ", ")

	else if caseIndex is 5 then
		log split("a: b", ":")

	else if caseIndex is 6 then
		try
			splitByLine("
			ma ~
			wormwood
		")
			error "Should not reach this statement"
		on error
			log "Expected error was raised"
		end try

	else if caseIndex is 7 then
		log split("c:/windows/system32/iknowitsbackslash.dll", "/")

	else if caseIndex is 8 then
		log split("https://www.amazon.co.uk", ".")

	else if caseIndex is 9 then
		set shellResult to do shell script "echo 'one
two'"
		log splitByLine(shellResult)

	else if caseIndex is 10 then
		log indexOf(cases, "Split By Line / Index Of")

	else if caseIndex is 11 then
		set list11 to splitByLine("
			Hello
			$Special
		")
		log list11
		log (count of list11)

	else if caseIndex is 12 then
		set list12 to splitByParagraph("
			Hello
			$Special
		")
		repeat with nextElement in list12
			log nextElement
		end repeat

	else if caseIndex is 13 then
		set list13 to splitAndTrimParagraphs("
			Hello
			$Special
		")
		repeat with nextElement in list13
			log nextElement
		end repeat
	end if

	spot's finish()
	logger's finish()
end spotCheck


on splitString(theString as text)
	set theDelimiter to ","
	-- set theList to
	_split(theString, theDelimiter)

	(*
	set sanitized to {}
	repeat with next in theList
		set nextTrimmed to textUtil's trim(next)
		if nextTrimmed is not equal to "" then set end of sanitized to nextTrimmed
	end repeat
	sanitized
*)
end splitString


(*
	TODO: Handle special cases like tilde, or when there's single quote in the text.
	dot character breaks it as well. FOOBAR.
*)
on splitByLine(theString)
	if theString is missing value then return missing value

	-- return splitByParagraph(theString)

	if theString contains LF and (theString contains CR) then
		set theString to textUtil's replace(theString, CR, LF)
	end if
	if theString contains CR then return _split(theString, CR) -- assuming this is shell command result, we have to split by CR.

	-- Only printable ASCII characters below 127 works. tab character don't work.
	set SEP to "@" -- #%= are probably worth considering.

	if theString contains linesDelimiter or theString contains "\"" then error "Sorry but you can't have " & linesDelimiter & " or double quote in the text :("
	if theString contains "$" and theString contains "'" then
		return splitByParagraph(theString)
		error "Sorry, but you can't have a dollar sign and a single quote in your string"
	end if

	set theQuote to "\""
	if theString contains "$" then set theQuote to "'"
	set command to "echo " & theQuote & theString & theQuote & " | awk 'NF {$1=$1;print $0}' | paste -s -d" & linesDelimiter & " - | sed 's/" & linesDelimiter & "[[:space:]]*/" & linesDelimiter & "/g' | sed 's/[[:space:]]*" & linesDelimiter & "/" & linesDelimiter & "/g' | sed 's/^" & linesDelimiter & "//' | sed 's/" & linesDelimiter & linesDelimiter & "//g' | sed 's/" & linesDelimiter & "$//'" -- failed when using escaped/non escaped plus instead of asterisk.

	set csv to do shell script command

	_split(csv, linesDelimiter)
end splitByLine


(*
	TODO: Unit test
*)
on splitByParagraph(theText)
	if theText is missing value then return {}

	set listResult to {}
	set textLines to paragraphs of theText
	repeat with nextLine in textLines
		set end of listResult to nextLine
	end repeat
	listResult
end splitByParagraph

on splitAndTrimParagraphs(theText)
	if theText is missing value then return {}

	set listResult to {}
	set textLines to paragraphs of theText
	repeat with nextLine in textLines
		-- set trimmedLine to do shell script "echo '" & nextLine & "' |  sed 's/ *$//g'  |  sed 's/^[[:space:]]*//g'"
		set trimmedLine to do shell script "echo " & quoted form of nextLine & " | sed 's/[[:space:]]*$//' | sed 's/^[[:space:]]*//'"
		if trimmedLine is not "" then set end of listResult to trimmedLine
	end repeat
	listResult
end splitAndTrimParagraphs


(* Too Slow! *)
on splitByLineX(theString as text)
	set command to "echo \"" & theString & "\" | awk -vORS=, '{$1=$1};1' | sed 's/,,/,/g' | sed 's/^,//' | sed 's/,$//'"
	set csv to do shell script command
	if csv ends with "," then set csv to text 1 thru -2 of csv

	_split(csv, ",")
end splitByLineX


(*
	Removes all the references of the target element.
	@returns the resulting list.
*)
on remove(aList, targetElement)
	if aList is missing value then return missing value

	set newList to {}
	repeat with i from 1 to (number of items in aList)
		set nextItem to item i of aList
		if nextItem is not targetElement then
			set end of newList to nextItem
		end if
	end repeat

	newList
end remove


on indexOf(aList, targetElement)
	_indexOf(aList, targetElement, false)
end indexOf

on indexOfText(aList, targetElement)
	_indexOf(aList, targetElement, true)
end indexOfText

on _indexOf(aList, targetElement, asText)
	if aList is missing value then return missing value

	set targetToCompare to targetElement
	if targetElement is not missing value and asText then
		set targetToCompare to targetElement as text
	end if

	repeat with i from 1 to count of aList
		set nextElement to item i of aList

		set elementToCompare to nextElement
		if nextElement is not missing value and asText then
			set elementToCompare to nextElement as text
		end if

		if elementToCompare is equal to the targetToCompare then return i
	end repeat

	0
end _indexOf


(* It is actually a selection sort. *)
on simpleSort(myList)
	if myList is missing value then return missing value

	set the index_list to {}
	set the sorted_list to {}
	repeat (the number of items in myList) times
		set the low_item to ""
		repeat with i from 1 to (number of items in myList)
			if i is not in the index_list then
				set this_item to item i of myList as text
				if the low_item is "" then
					set the low_item to this_item
					set the low_item_index to i
				else if this_item is less than low_item then
					set the low_item to this_item
					set the low_item_index to i
				end if
			end if
		end repeat
		set the end of sorted_list to the low_item
		set the end of the index_list to the low_item_index
	end repeat
	sorted_list
end simpleSort


on join(theList, theDelimiter)
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to {theDelimiter}
	set theListAsText to theList as text
	set AppleScript's text item delimiters to oldDelimiters
	theListAsText
end join


(* 	Vanilla contains operation that does not work when shell command is used
	somewhere.
*)
on listContains(theList, target)
	if theList is missing value then return false

	-- repeat with nextElement in theList  -- This form is problematic because it converts the element into text automatically.
	repeat with i from 1 to count of theList
		set nextElement to item i of theList

		if class of target is not text and nextElement is equal to the target then return true

		set nextElementText to nextElement
		if nextElement is not missing value then set nextElementText to nextElement as text
		if nextElementText is equal to the target or nextElement is missing value and target is missing value then return true

	end repeat
	false
end listContains


on listsEqual(list1, list2)
	if list1 is missing value then return list2 is missing value
	if list2 is missing value then return list1 is missing value

	if (count of list1) is not equal to the (count of list2) then return false

	repeat with i from 1 to number of items in list1
		if item i of list1 is not equal to item i of list2 then return false
	end repeat

	true
end listsEqual


(*
	Created because list equals does not behave as expected. Will cast to text first before comparing each elements.
*)
on stringElementEquals(list1, list2)
	if list1 is missing value then return list2 is missing value
	if list2 is missing value then return list1 is missing value

	if (count of list1) is not equal to the (count of list2) then return false

	repeat with i from 1 to number of items in list1
		if item i of list1 as text is not equal to item i of list2 as text then return false
	end repeat

	true
end stringElementEquals


on clone(source)
	if source is missing value then return missing value

	set cloned to {} -- Using [] does not work.
	repeat with nextItem in source
		copy the nextItem to the end of the cloned
	end repeat
	cloned
end clone

(*
	Fills an array with elements.
*)
on newWithElements(element, elementCount)
	if elementCount is less than 1 then error "Element Count " & elementCount & " is not a valid count" number ERROR_LIST_COUNT_INVALID

	set array to {}
	repeat with i from 1 to elementCount
		set end of array to element
	end repeat

	array
end newWithElements


(*
	What's the benefit of this over _split?
		Why am I shelling the split?
*)
on split(theString, theDelimiter)
	_split(theString, theDelimiter)

(*
	if theString contains "$" and theString contains "'" then error "Sorry, but you can't have a dollar sign and a single quote in your string"

	set theQuote to "\""
	if theString contains "$" then set theQuote to "'"

	if theDelimiter contains "." then return _split(theString, theDelimiter)

	set sedDelimiter to "/"
	if theDelimiter is "/" then set sedDelimiter to ";"
	if theDelimiter is "/" and theString contains ";" then error "Sorry, I'm not sure how to split your string"

	set command to "echo " & theQuote & theString & theQuote & " | paste -s -d, - | sed 's" & sedDelimiter & theDelimiter & "[[:space:]]*" & sedDelimiter & theDelimiter & sedDelimiter & "g'"
	set csv to do shell script command
	_split(csv, theDelimiter)
*)
end split


(*
	@returns the index of the matched search string.
*)
on lastMatchingIndexOf(theList, searchString)
	if theList is missing value then
		return -1
	end if

	set lastMatchIndex to 0
	repeat with i from 1 to count of theList
		set nextItem to item i of theList
		if nextItem contains searchString or nextItem is equal to the searchString then
			set lastMatchIndex to i
		end if
	end repeat

	lastMatchIndex
end lastMatchingIndexOf


on swap(theList, index1, index2)
	if theList is missing value then return
	if index1 is greater than the (count of theList) then
		error "Out of bounds error. " & index1 & " is not a valid start index" number ERROR_OUT_OF_BOUNDS
	end if
	if index2 is greater than the (count of theList) then
		error "Out of bounds error. " & index2 & " is not a valid end index" number ERROR_OUT_OF_BOUNDS
	end if

	set tmp to item index1 of theList
	set item index1 of theList to item index2 of theList
	set item index2 of theList to tmp
end swap

(*
	@returns the updated list.
*)
on moveElement(theList, fromIndex, toIndex)
	if theList is missing value then return missing value
	if fromIndex is greater than the (count of theList) then
		error "Out of bounds error. " & fromIndex & " is not a valid from index" number ERROR_OUT_OF_BOUNDS
	end if
	-- if toIndex is greater than the (count of theList) then return missing value
	if toIndex is greater than the (count of theList) then
		error "Out of bounds error. " & toIndex & " is not a valid target index" number ERROR_OUT_OF_BOUNDS
	end if
	if toIndex is equal to fromIndex then return theList

	set moveForward to fromIndex is less than toIndex
	set cutOut to item fromIndex of theList
	set newList to {}

	(*
	if move forward
		if at source index then do nothing
		else
			insert current element
			if at target index then insert cutout
	else backward
		if at to index then insert cutout.
		if not at from index then insert current element.
	*)

	repeat with i from 1 to the number of items in theList
		if moveForward then
			if i is not equal to the fromIndex then
				set end of newList to item i of theList
				if i is equal to toIndex then
					set end of newList to the cutOut
				end if
			end if
		else
			if i is equal to the toIndex then
				set end of newList to the cutOut
			end if
			if i is not equal to the fromIndex then
				set end of newList to item i of theList
			end if
		end if
	end repeat
	newList
end moveElement


(*
	Steps:
		1. save delimiters to restore old settings
		2. set delimiters to delimiter to be used
		3. create the array
		4. restore the old setting

	@returns list
*)
on _split(theString, theDelimiter)
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to theDelimiter
	set theArray to every text item of theString
	set AppleScript's text item delimiters to oldDelimiters

	theArray
end _split


on _replaceAll(sourceText, substring, replacement)
	set theList to split(sourceText, substring)
	join(theList, replacement)
end _replaceAll


(* Tested on text types only for now. *)
on unique(inputList)
	set uniqueList to {}
	repeat with nextElement in inputList
		if class of nextElement is text and not listContains(uniqueList, nextElement as text) then
			set end of uniqueList to nextElement as text
		end if
	end repeat
	uniqueList
end unique
