global std, textUtil

(*
	Usage:
		set listUtil to std's import("list")
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then  spotCheck() -- IMPORTANT: Comment out on deploy

to spotCheck()
	init()
	set thisCaseId to "list-spotCheck"
	logger's start()
	
	set cases to splitByLine("
		Unit Test		
		Split By Line
		Trailing emty line
		Split with trim
		Split Map
		
		Split By Line with Illegal Character
		Split using /
		Split Web Domain
		Split Shell Command Result By Line
		Split By Line / Index Of 		
		
		Split By Line - With Dollar Sign
	")
	
	
	set spotLib to std's import("spot")
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	if caseIndex is 1 then
		unitTest()
		
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
		
	end if
	
	spot's finish()
	my logger's finish()
end spotCheck


to splitString(theString as text)
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


(* Handle special cases like tilde, or when there's single quote in the text. *)
on splitByLine(theString as text)
	if theString contains (ASCII character 13) then return _split(theString, ASCII character 13) -- assuming this is shell command result, we have to split by CR.
	
	-- Only printable ASCII characters below 127 works. tab character don't work.
	set SEP to "@" -- #%+= are probably worth considering.
	
	if theString contains SEP or theString contains "\"" then error "Sorry but you can't have " & SEP & " or double quote in the text :("
	if theString contains "$" and theString contains "'" then error "Sorry, but you can't have a dollar sign and a single quote in your string"
	
	set theQuote to "\""
	if theString contains "$" then set theQuote to "'"
	set command to "echo " & theQuote & theString & theQuote & " | awk 'NF {$1=$1;print $0}' | paste -s -d" & SEP & " - | sed 's/" & SEP & "[[:space:]]*/" & SEP & "/g' | sed 's/[[:space:]]*" & SEP & "/" & SEP & "/g' | sed 's/^" & SEP & "//' | sed 's/" & SEP & SEP & "//g' | sed 's/" & SEP & "$//'" -- failed when using escaped/non escaped plus instead of asterisk.
	set csv to do shell script command
	
	_split(csv, SEP)
end splitByLine


(* Too Slow! *)
to splitByLineX(theString as text)
	set command to "echo \"" & theString & "\" | awk -vORS=, '{$1=$1};1' | sed 's/,,/,/g' | sed 's/^,//' | sed 's/,$//'"
	set csv to do shell script command
	if csv ends with "," then set csv to text 1 thru -2 of csv
	
	_split(csv, ",")
end splitByLineX


on remove(aList, targetElement)
	set newList to {}
	repeat with i from 1 to (number of items in aList)
		set nextItem to item i of aList as text
		if nextItem is not targetElement then
			set end of newList to nextItem
		end if
	end repeat
	
	newList
end remove


to indexOf(aList, targetElement)
	repeat with i from 1 to count of aList
		set nextElement to item i of aList
		if nextElement as text is equal to targetElement then return i
	end repeat
	
	return 0
end indexOf


on simpleSort(myList)
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


(* Vanilla contains operation does not work when shell command is used somewhere. *)
on listContains(theList, target)
	repeat with nextElement in theList
		set nextElementText to nextElement as text
		if nextElementText is equal to the target then return true
	end repeat
	false
end listContains


on listEquals(list1, list2)
	if list1 is missing value then return list2 is missing value
	if list2 is missing value then return list1 is missing value
	
	if (count of list1) is not equal to the (count of list2) then return false
	
	repeat with i from 1 to number of items in list1
		if item i of list1 is not equal to item i of list2 then return false
	end repeat
	
	true
end listEquals

(* What's the benefit of this over _split? *)
on split(theString, theDelimiter)
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
end split


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


to _replaceAll(sourceText, substring, replacement)
	set theList to split(sourceText, substring)
	join(theList, replacement)
end _replaceAll


to unitTest()
	set utLib to std's import("unit-test")
	set ut to utLib's new()
	tell ut
		newMethod("remove")
		assertEqual({"one", "two"}, my remove({"one", "two", "three"}, "three"), "Happy Case")
		assertEqual({"one", "two", "three"}, my remove({"one", "two", "three"}, "nine"), "Not Found")
		assertEqual({"two", "three"}, my remove({"one", "two", "three"}, "one"), "Found First")
		
		newMethod("indexOf")
		assertEqual(2, my indexOf({"three", "one", "plus", "one one", "two"}, "one"), "Happy Case-Found")
		assertEqual(0, my indexOf({"a", "b", "c"}, "z"), "Happy Case-Not Found")
		assertEqual(3, my indexOf({"a", "b", "c"}, "c"), "Happy Case-Not Found")
		
		newMethod("splitByLine")
		assertEqual(4, count of my splitByLine("
			1a
			2x
			me, myself, and Irene
			fxve
		"), "Basic Lines Count")
		assertEqual(2, count of my splitByLine("
			First
			$Second
		"), "With Dollar Sign")
		assertEqual(1, count of my splitByLine("
			$One
		"), "With Dollar Sign - Single Line")
		assertEqual(2, count of my splitByLine("
			You're Nice
			I know!
		"), "With Single Quote")
		assertEqual(2, count of my splitByLine("
			With tilde~hi
			I know!
		"), "Tilde allowed")
		
		newMethod("listEquals")
		assertTrue(my listEquals(missing value, missing value), "Both missing value")
		assertFalse(my listEquals(missing value, {1}), "First list is missing value")
		assertFalse(my listEquals({1}, missing value), "Second list is missing value")
		assertFalse(my listEquals({1}, {1, 2}), "Unequal size")
		assertTrue(my listEquals({1, 2}, {1, 2}), "Happy")
		assertFalse(my listEquals({1, 2}, {"1", 2}), "Mistype")
		
		newMethod("simpleSort")
		assertEqual({"a", "b", "c"}, my simpleSort({"b", "c", "a"}), "Happy Case")
		
		done()
	end tell
end unitTest


to init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("list")
	set textUtil to std's import("string")
end init