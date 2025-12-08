(*
	@Usage:
		use textUtil : script "core/string"

	Logger depends on this script so we cannot use logger here because it will result in a circular dependency.

	Online Tool:
		https://www.urlencoder.io

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/Level_1/string

	@Last Modified: 2025-12-06 15:08:23
	
	@Change Logs:
		Mon, Dec 08, 2025, at 03:14:06 PM
*)
use scripting additions

property logger : missing value

if {"Script Debugger", "Script Editor"} contains the name of current application then spotCheck()


on spotCheck()
	set loggerFactory to script "core/logger-factory"
	loggerFactory's injectBasic(me)
	logger's start()
	
	set spotScript to script "core/spot-test"
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Wing It!
		Encode Multi Line Command
		Manual: Improve format to be allow more tokens than placeholders
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	if caseIndex is 1 then
		set sut to "1
		2"
		log encodeUrl(sut)
		-- log format("What's missing? {}", missing value)
		log format("Body: {}", "She said: \"hello?\"")
		log format("Body: \"{}\"", "She")
		
	else if caseIndex is 2 then
		log encodeUrl("
			docker container run \\
			--name mysql_local \\
			--rm \\
			-it \\
			-v ~/docker/mysql-data:/var/lib/mysql \\
			-v \"`pwd`/init\":/docker-entrypoint-initdb.d \\
			-e MYSQL_ROOT_PASSWORD=dev \\
			-p 4306:3306 \\
			mysql:5
		")
		
	else if caseIndex is 3 then
		log format("Body: {}, {}", 1)
		
	else
		-- log encodeUrl("hello kansas")
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on splitAndTrimParagraphs(theText)
	if theText is missing value then return {}
	
	set listResult to {}
	set textLines to paragraphs of theText
	repeat with nextLine in textLines
		set trimmedLine to do shell script "echo " & quoted form of nextLine & " | sed 's/[[:space:]]*$//' | sed 's/^[[:space:]]*//'"
		if trimmedLine is not "" then set end of listResult to trimmedLine
	end repeat
	listResult
end splitAndTrimParagraphs



(*
	Converts AppleScript multi-line string into to ASCII character 13 separated lines.
	Useful when comparing muli-line results from a shell command to a multi-line
	strings in AppleScript code.
*)
on multiline(sourceText)
	replace(sourceText, "
", ASCII character 13)
end multiline


on substringAfter(sourceText, substring)
	stringAfter(sourceText, substring)
end substringAfter


on stringAfter(sourceText, substring)
	if sourceText does not contain substring then return missing value
	if sourceText ends with substring then return missing value
	
	text ((offset of substring in sourceText) + (count of substring)) thru -1 of sourceText
end stringAfter


on lastStringAfter(sourceText, substring)
	if sourceText does not contain substring then return missing value
	if sourceText ends with substring then return missing value
	
	last item of split(sourceText, substring)
end lastStringAfter


on stringBefore(sourceText, substring)
	if sourceText does not contain substring then return missing value
	if sourceText starts with substring then return missing value
	
	text 1 thru ((offset of substring in sourceText) - 1) of sourceText
end stringBefore


on stringBetween(sourceText, substringStart, substringEnd)
	if sourceText does not contain substringStart then return missing value
	if sourceText does not contain substringEnd then return missing value
	
	text ((offset of substringStart in sourceText) + (count of substringStart)) thru ((offset of substringEnd in sourceText) - 1) of sourceText
end stringBetween


on shortestStringBetween(sourceText, substringStart, substringEnd)
	if sourceText does not contain substringStart then return missing value
	if sourceText does not contain substringEnd then return missing value
	
	text (lastIndexOf(sourceText, substringStart) + (count of substringStart)) thru ((offset of substringEnd in sourceText) - 1) of sourceText
end shortestStringBetween


on replaceFirst(sourceText, substring, replacement)
	if sourceText is missing value then return missing value
	if sourceText does not contain substring then return sourceText
	
	set substringOffset to offset of substring in sourceText
	if substringOffset is 0 then return sourceText
	if replacement is missing value then set replacement to ""
	
	if sourceText starts with substring then return replacement & text ((length of substring) + 1) thru (length of sourceText) of sourceText
	
	-- ends with match.
	if substringOffset + (length of (substring)) is equal to the (length of sourceText) + 1 then
		set endIdx to (offset of substring in sourceText) - 1 + (length of substring)
		return (text 1 thru (substringOffset - 1) of sourceText) & replacement
	end if
	
	if length of substring is greater than length of sourceText then return sourceText
	
	if substringOffset is greater than 1 then
		set startText to text 1 thru (substringOffset - 1) of sourceText
		set replaceEndOffset to length of sourceText
		
		if length of sourceText is greater than substringOffset + (length of substring) - 1 then set replaceEndOffset to substringOffset + (length of substring)
		set endText to text replaceEndOffset thru (length of sourceText) of sourceText
		
		return startText & replacement & endText
	end if
end replaceFirst

on replaceLast(sourceText, substring, replacement)
	set substringOffset to lastIndexOf(sourceText, substring)
	if substringOffset is 0 then return sourceText
	if replacement is missing value then set replacement to ""
	
	if sourceText starts with substring then return replacement & text ((length of substring) + 1) thru (length of sourceText) of sourceText
	
	
	if substringOffset + (length of (substring)) is equal to the (length of sourceText) + 1 then
		set endIdx to (offset of substring in sourceText) - 1 + (length of substring)
		return (text 1 thru (substringOffset - 1) of sourceText) & replacement
	end if
	
	if length of substring is greater than length of sourceText then return sourceText
	
	if substringOffset is greater than 1 then
		set startText to text 1 thru (substringOffset - 1) of sourceText
		set replaceEndOffset to length of sourceText
		
		if length of sourceText is greater than substringOffset + (length of substring) - 1 then set replaceEndOffset to substringOffset + (length of substring)
		set endText to text replaceEndOffset thru (length of sourceText) of sourceText
		
		return startText & replacement & endText
	end if
end replaceLast


on removeUnicode(textWithUnicodeChar)
	do shell script "echo " & quoted form of textWithUnicodeChar & " | iconv -c -f utf-8 -t ascii || true"
end removeUnicode


(*
	@Prefer to use urlEncode, unless encoding a shell command that can result in a conflict.
	Visit https://www.urlencoder.org for an online tool.
*)
on encodeUrl(theString as text)
	-- printAsciiNumber(theString)
	
	-- do shell script "urlencode_grouped_case \"" & theString & "\""
	set replacedText to replace(theString, ASCII character 10, "%0A")
	set replacedText to replace(replacedText, " ", "%20")
	set replacedText to replace(replacedText, "[", "%5B")
	set replacedText to replace(replacedText, "]", "%5D")
	set replacedText to replace(replacedText, "=", "%3D")
	set replacedText to replace(replacedText, "|", "%7C")
	set replacedText to replace(replacedText, "<", "%3C")
	set replacedText to replace(replacedText, ">", "%3E")
	set replacedText to replace(replacedText, "/", "%2F")
	set replacedText to replace(replacedText, ":", "%3A")
	set replacedText to replace(replacedText, "@", "%40")
	set replacedText to replace(replacedText, "&", "%26")
	set replacedText to replace(replacedText, "+", "%2b")
	set replacedText to replace(replacedText, "'", "%27")
	set replacedText to replace(replacedText, "\"", "%22")
	set replacedText to replace(replacedText, "(", "%28")
	set replacedText to replace(replacedText, ")", "%29")
	set replacedText to replace(replacedText, "\\", "%5C")
	set replacedText to replace(replacedText, ",", "%2C")
	replacedText
end encodeUrl


on decodeUrl(theString as text)
	-- does not work with %7c
	-- return do shell script "echo '" & theString & "' | printf \"%b\\n\" \"$(sed 's/+/ /g; s/%\\([0-9a-f][0-9a-f]\\)/\\\\x\\1/g;')\";"
	
	set newString to replace(theString, "%0A", "
")
	set newString to replace(theString, "%20", " ")
	set newString to replace(newString, "%5B", "[")
	set newString to replace(newString, "%5D", "]")
	set newString to replace(newString, "%3D", "=")
	set newString to replace(newString, "%7C", "|")
	set newString to replace(newString, "%3C", "<")
	set newString to replace(newString, "%3E", ">")
	set newString to replace(newString, "%2F", "/")
	set newString to replace(newString, "%3A", ":")
	set newString to replace(newString, "%40", "@")
	set newString to replace(newString, "%26", "&")
	set newString to replace(newString, "%2b", "+")
	set newString to replace(newString, "%27", "'")
	set newString to replace(newString, "%22", "\"")
	set newString to replace(newString, "%28", "(")
	set newString to replace(newString, "%29", ")")
	set newString to replace(newString, "%5C", "\\")
	set newString to replace(newString, "%2C", ",")
	newString
end decodeUrl


(* To prevent clash with scptd. *)
on formatNext(theString as text, theTokens as list)
	format(theString, theTokens)
end formatNext


(* Safer handler to use because it uses pure AppleScript and it does not shell out, so it does not conflict with the actual text. *)
on formatClassic(theString as text, theTokens as list)
	if class of theTokens is text then set theTokens to {theTokens}
	set builtString to theString
	repeat with nextToken in theTokens
		set builtString to replaceFirst(builtString, "{}", nextToken as text)
	end repeat
	return builtString
end formatClassic


(*
	NOTE: Passing in "!" as part of the parameters will use the slow implementation

	@sourceText - the string with placeholders for interpolation.
	@theTokens - list of the token replacements
*)
on format(sourceText, theTokens)
	if sourceText is missing value then return missing value
	
	if class of theTokens is not list then set theTokens to {theTokens}
	if theTokens is {} then set theTokens to {{}}
	
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to "{}"
	set theArray to every text item of sourceText
	set AppleScript's text item delimiters to theTokens
	set theListAsText to first item of theArray
	
	repeat with i from 2 to number of items in theArray
		set placeholderIndex to i - 1
		set isNoMoreToken to placeholderIndex is greater than the number of items in theTokens
		if isNoMoreToken then
			set nextToken to the last item of the theTokens
		else
			set nextToken to item (i - 1) of theTokens
		end if
		set theListAsText to theListAsText & nextToken & item i of theArray
	end repeat
	
	set AppleScript's text item delimiters to oldDelimiters
	return theListAsText
end format


on title(theWord)
	if theWord is missing value then return missing value
	
	set AppleScript's text item delimiters to ""
	ucase(first character of theWord) & rest of characters of theWord
end title


on lower(theText)
	do shell script "echo " & quoted form of theText & " | tr '[:upper:]' '[:lower:]'"
end lower


on upper(theText)
	do shell script "echo " & quoted form of theText & " | tr '[:lower:]' '[:upper:]'"
end upper

on ucase(theText)
	upper(theText)
end ucase


(* TODO: Unit test. *)
on lcase(theText)
	lower(theText)
end lcase


on repeatText(theText, ntimes)
	if ntimes is less than or equal to 0 then return missing value
	
	set theResult to ""
	repeat ntimes times
		set theResult to theResult & theText
	end repeat
end repeatText


(* @returns list *)
on split(theString, theDelimiter)
	-- save delimiters to restore old settings
	set oldDelimiters to AppleScript's text item delimiters
	-- set delimiters to delimiter to be used
	set AppleScript's text item delimiters to theDelimiter
	-- create the array
	set theArray to every text item of theString
	-- restore the old setting
	set AppleScript's text item delimiters to oldDelimiters
	-- return the result
	theArray
end split


on splitWithTrim(theString as text, theDelimiter)
	set theList to split(theString, theDelimiter)
	set sanitized to {}
	repeat with next in theList
		set nextTrimmed to trim(next)
		if nextTrimmed is not equal to "" then set end of sanitized to nextTrimmed
	end repeat
	sanitized
end splitWithTrim


on join(aList, delimiter)
	if aList is missing value then return missing value
	set calcDelimiter to delimiter
	if delimiter is missing value then set calcDelimiter to ""
	
	set retval to ""
	repeat with i from 1 to (count of aList)
		set retval to retval & item i of aList
		if i is not equal to (count of aList) then set retval to retval & calcDelimiter
	end repeat
	return retval
end join


on indexOf(sourceText, substring)
	if substring is missing value then return 0
	if sourceText is missing value then return 0
	if (offset of substring in sourceText) is 0 then return 0
	
	offset of substring in sourceText
end indexOf


on lastIndexOf(sourceText, substring)
	if substring is missing value then return 0
	if sourceText is missing value then return 0
	-- if (offset of substring in sourceText) is 0 then return 0
	if sourceText does not contain substring then return 0
	
	set theList to split(sourceText, substring)
	return (length of sourceText) - (length of last item of theList) - (length of substring) + 1
end lastIndexOf


on replaceAll(sourceText, substring, replacement)
	replace(sourceText, substring, replacement)
end replaceAll


on replace(sourceText, substring, replacement)
	if replacement is missing value then set replacement to ""
	if sourceText is missing value then return missing value
	if sourceText does not contain substring then return sourceText
	if substring is "
" then
		set ugly to ""
		repeat with nextChar in characters of sourceText
			if (ASCII number nextChar) is 10 then
				set ugly to ugly & replacement
			else
				set ugly to ugly & nextChar
			end if
		end repeat
		return ugly
	end if
	
	if sourceText is equal to substring then return replacement as text
	
	if sourceText starts with substring then
		set startIdx to the (length of substring) + 1
		return replacement & replace(text startIdx thru length of sourceText, substring, replacement)
	end if
	
	if sourceText is missing value then return sourceText
	if (offset of substring in sourceText) is equal to 0 then return sourceText
	
	set retval to text 1 thru ((offset of substring in sourceText) - 1) of sourceText
	set nextIdx to offset of substring in sourceText
	
	repeat
		if nextIdx - 1 is greater than ((length of sourceText) - (length of substring)) then exit repeat
		
		if text nextIdx thru (nextIdx + (length of substring) - 1) of sourceText is equal to substring then
			if length of replacement is greater than 0 then
				set retval to retval & replacement
				set nextIdx to nextIdx + (length of substring)
			else
				set retval to retval & replacement
				set nextIdx to nextIdx + (length of substring)
			end if
		else
			set retval to retval & item nextIdx of sourceText
			set nextIdx to nextIdx + 1
		end if
	end repeat
	
	if nextIdx is less than or equal to length of sourceText then set retval to retval & text nextIdx thru -1 of sourceText
	
	retval
end replace


on substring(thisText, startIdx, endIdx)
	if endIdx is less than the startIdx then return missing value
	
	text startIdx thru endIdx of thisText
end substring


on substringFrom(thisText, startIdx)
	if startIdx is greater than the (count of thisText) then return thisText
	
	text startIdx thru -1 of thisText
end substringFrom


on rtrim(theText)
	if theText is missing value then return missing value
	if theText is "" then return theText
	
	set counter to 0
	repeat with nextCharacter in reverse of characters of theText
		if {tab, "
", " "} does not contain the nextCharacter then exit repeat
		set counter to counter + 1
	end repeat
	
	if counter is equal to the length of theText then return ""
	
	text 1 thru ((the length of theText) - counter) of theText
end rtrim


on ltrim(theText)
	if theText is missing value then return missing value
	if theText is "" then return ""
	
	set trimOffset to 1
	repeat until (character trimOffset of theText) is not in {" ", "
", tab}
		set trimOffset to trimOffset + 1
		if trimOffset is greater than or equal to (count of theText) then
			return ""
		end if
	end repeat
	
	text trimOffset thru (count of theText) of theText
end ltrim


(* NOTE: For Review! *)
on trim(theText)
	-- do shell script "ruby -e \"p '" & theText & "'.strip\" | sed 's/\"//g'"
	-- do shell script "echo '" & ltrim(theText) & "' |  sed 's/ *$//g'  |  sed 's/^[[:space:]]*//g'"
	do shell script "echo " & quoted form of theText & " | sed 's/[[:space:]]*$//' | sed 's/^[[:space:]]*//g'"
end trim


(* Used for debugging to determine the ASCII number of each character of the string provided. *)
on printAsciiNumber(theString)
	repeat with nextChar in characters of theString
		log nextChar & " " & (ASCII number nextChar)
	end repeat
end printAsciiNumber


on isUnicode(theString)
	set inspected to ""
	repeat with nextChar in characters of theString
		set inspected to inspected & (ASCII character (ASCII number nextChar))
	end repeat
	theString is not equal to inspected
end isUnicode


on hasUnicode(theString)
	isUnicode(theString)
end hasUnicode


(* @Deprecated.  Use #replaceLast. *)
on removeEnding(sourceText, ending)
	-- return replaceLast(sourceText, ending, "")
	
	if sourceText is missing value then return missing value
	
	try
		text 1 thru -((length of ending) + 1) of sourceText
	on error
		sourceText
	end try
end removeEnding


on unitTest()
	set test to testLib's new()
	set ut to test's new()
	tell ut
		newMethod("removeEnding")
		assertEqual("Hell", my removeEnding("Hello", "o"), "Basic")
		assertEqual("Hello", my removeEnding("Hello", "not found"), "Not found")
		
		done()
	end tell
end unitTest
