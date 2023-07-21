(*
	@Usage:
		use textUtil : script "string"

	Logger depends on this script so we cannot use logger here because it will result in a circular dependency.

	Online Tool:
		https://www.urlencoder.io
		
	@Build:
		make compile-lib SOURCE=core/string

	@Last Modified: 2023-07-21 19:07:22
*)
use scripting additions

use listUtil : script "list"
use loggerFactory : script "logger-factory"

use spotScript : script "spot-test"

use testLib : script "test"

property logger : missing value

if {"Script Debugger", "Script Editor"} contains the name of current application then spotCheck()


on spotCheck()
	loggerFactory's injectBasic(me, "string")
	logger's start()
	
	set cases to listUtil's splitByLine("
		Unit Test
		Wing It!
		Encode Multi Line Command
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	if caseIndex is 1 then
		unitTest()
		
	else if caseIndex is 2 then
		set sut to "1
		2"
		log urlEncode(sut)
		-- log format("What's missing? {}", missing value)
		log format("Body: {}", "She said: \"hello?\"")
		log format("Body: \"{}\"", "She")
		
	else if caseIndex is 3 then
		log encodeUrl("docker container run 
    --name mysql_local 
    --rm 
    -it 
    -v ~/docker/mysql-data:/var/lib/mysql 
    -v \"`pwd`/init\":/docker-entrypoint-initdb.d 
    -e MYSQL_ROOT_PASSWORD=dev 
    -p 4306:3306 
    mysql:5")
		
	else
		-- log encodeUrl("hello kansas")
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


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


on replaceFirst(sourceText, substring, replacement)
	set substringOffset to offset of substring in sourceText
	if substringOffset is 0 then return sourceText
	
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
	Passing in "!" as part of the parameters will use the slow implementation 
	@theString the string with place holders for interpolation.
	@theTokens list of the token replacements
*)
on format(theString, theTokens)
	if class of theTokens is not list then set theTokens to {theTokens}
	if theTokens is {} then set theTokens to {{}}
	
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to "{}"
	set theArray to every text item of theString
	set AppleScript's text item delimiters to theTokens
	set theListAsText to first item of theArray
	repeat with i from 2 to number of items in theArray
		set nextToken to item (i - 1) of theTokens
		set theListAsText to theListAsText & nextToken & item i of theArray
	end repeat
	
	set AppleScript's text item delimiters to oldDelimiters
	return theListAsText
end format


on title(theWord)
	set AppleScript's text item delimiters to ""
	ucase(first character of theWord) & rest of characters of theWord
end title


on lower(theText)
	do shell script "echo '" & theText & "' | tr '[:upper:]' '[:lower:]'"
end lower


on upper(theText)
	do shell script "echo '" & theText & "' | tr '[:lower:]' '[:upper:]'"
end upper

to ucase(theText)
	upper(theText)
end ucase


on lcase(theText)
	lower(theText)
end lcase


to repeatText(theText, ntimes)
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
	set retval to ""
	repeat with i from 1 to (count of aList)
		set retval to retval & item i of aList
		if i is not equal to (count of aList) then set retval to retval & delimiter
	end repeat
	return retval
end join


on lastIndexOf(sourceText, substring)
	if substring is missing value then return 0
	if sourceText is missing value then return 0
	if (offset of substring in sourceText) is 0 then return 0
	
	set theList to split(sourceText, substring)
	return (length of sourceText) - (length of last item of theList) - (length of substring) + 1
end lastIndexOf


on replaceAll(sourceText, substring, replacement)
	replace(sourceText, substring, replacement)
end replaceAll


on replace(sourceText, substring, replacement)
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
	
	if sourceText is equal to substring then return replacement
	
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
	set trimOffset to count of theText
	repeat until (character trimOffset of theText) is not in {" ", "
"}
		set trimOffset to trimOffset - 1
		if trimOffset is 0 then
			return ""
		end if
	end repeat
	
	text 1 thru trimOffset of theText
end rtrim


on ltrim(theText as text)
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
	
	-- return do shell script "echo '" & theText & "' | sed 's/^[[:space:]]*//' | tr "  -- does not support newlines
end ltrim


(* NOTE: For Review! *)
on trim(theText)
	-- do shell script "ruby -e \"p '" & theText & "'.strip\" | sed 's/\"//g'"
	do shell script "echo '" & theText & "' |  sed 's/ *$//g'  |  sed 's/^ *//g'"
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


on removeEnding(theText as text, ending as text)
	try
		text 1 thru -((length of ending) + 1) of theText
	on error
		theText
	end try
end removeEnding


on unitTest()
	set test to testLib's new()
	set ut to test's new()
	tell ut
		newMethod("ltrim")
		assertEqual("SELECT", my ltrim("

	   SELECT"), "Multiline")
		assertEqual("SELECT", my ltrim("SELECT"), "no leading whitespace")
		assertEqual("", my ltrim(" "), "spaces only")
		assertEqual("", my ltrim(""), "empty string")
		
		newMethod("replaceFirst")
		assertEqual("three two plus one", my replaceFirst("three one plus one", "one", "two"), "Happy Case")
		assertEqual("one", my replaceFirst("one", "{}", "found"), "Not Found")
		assertEqual("one", my replaceFirst("one", "three", "dummy"), "Substring is longer")
		
		newMethod("format")
		assertEqual("one-two", my format("{}-{}", {"one", "two"}), "Bugged")
		assertEqual("Ends: yo", my format("Ends: {}", "yo"), "Ends with")
		assertEqual("Cat's daily stand up", my format("{} daily stand up", "Cat's"), "With single quote")
		assertEqual("With Bang!", my format("With {}", "Bang!"), "With bang")
		assertEqual("{\"attr-name\": 1}", my format("{\"{}\": 1}", "attr-name"), "Double Quoted")
		
		set expected to "javascript;
$('a') = 'hello';"
		set actual to my format("javascript;
$('{}') = '{}';", {"a", "hello"})
		assertEqual(expected, actual, "Multiline")
		
		newMethod("replace")
		assertEqual("abc", my replace("zbc", "z", "a"), "Starts with")
		assertEqual("abxyzfg", my replace("abcdefg", "cde", "xyz"), "Between")
		assertEqual("abcdxyz", my replace("abcdefg", "efg", "xyz"), "Ending")
		assertEqual("document.querySelector('a[href*=xyz]').click()", my replace("document.querySelector('a[href*={}]').click()", "{}", "xyz"), "With single quotes")
		assertEqual("Meeting Free Midday. Starts on September 10, 2020 at 10:00:00 AM and ends at 12:00:00 PM.", my replace("Meeting Free Midday. Starts on September 10, 2020 at 10:00:00 AM Philippine Standard Time and ends at 12:00:00 PM Philippine Standard Time.", " Philippine Standard Time", ""), "Multiple")
		assertEqual("yo(nes", my replace("yo(no", "no", "nes"), "With Parens")
		assertEqual("yo\\(no", my replace("yo(no", "(", "\\("), "The Parens")
		assertEqual("yo\\(no\\)", my replace(my replace("yo(no)", "(", "\\("), ")", "\\)"), "Two Parens")
		assertEqual("https:\\/\\/localhost:8080\\/yo", my replace("https://localhost:8080/yo", "/", "\\/"), "Escaping Slashes")
		assertEqual("https:\\/\\/localhost:8080\\/yo\\/", my replace("https://localhost:8080/yo/", "/", "\\/"), "Escaping Slashes ending with one")
		assertEqual("=Applications=Setapp", my replace("/Applications/Setapp", "/", "="), "Bugged")
		assertEqual("\\[Square] Bracket", my replace("[Square] Bracket", "[", "\\["), "Escaping")
		
		newMethod("decodeUrl")
		assertEqual("hello world", my decodeUrl("hello%20world"), "Basic")
		
		newMethod("stringAfter")
		assertEqual(missing value, my stringAfter("an apple a day", "orange "), "Not Found")
		assertEqual("a day", my stringAfter("an apple a day", "apple "), "Found")
		assertEqual(missing value, my stringAfter("an apple a day", "a day"), "In the end") -- I think missing value is more appropriate than empty string.
		
		newMethod("lastStringAfter")
		assertEqual(missing value, my lastStringAfter(missing value, missing value), "Bad parameters")
		assertEqual(missing value, my lastStringAfter("an apple a day", "orange "), "Not Found")
		assertEqual(" a day", my lastStringAfter("an apple a day", "apple"), "One Match")
		assertEqual(" vendor happy", my lastStringAfter("an apple a day makes the apple vendor happy", "apple"), "Multi Match")
		
		newMethod("stringBefore")
		assertEqual(missing value, my stringBefore("test.applescript", "orange"), "Not Found")
		assertEqual("an ", my stringBefore("an apple a day", "apple "), "Found")
		assertEqual(missing value, my stringBefore("an apple a day", "an apple"), "In the beginning") -- I think missing value is more appropriate than empty string.
		
		newMethod("title")
		assertEqual("Hello", my title("hello"), "Basic")
		assertEqual("Hello friend", my title("hello friend"), "Word only")
		
		newMethod("removeEnding")
		assertEqual("Hell", my removeEnding("Hello", "o"), "Basic")
		assertEqual("Hello", my removeEnding("Hello", "not found"), "Not found")
		
		done()
	end tell
end unitTest
