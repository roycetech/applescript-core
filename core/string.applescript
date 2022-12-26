global std

(*
	Usage:
		set textUtil to std's import("string")

	Online Tool:
		https://www.urlencoder.io
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

to spotCheck()
	init()
	set thisCaseId to "string-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Unit Test
		Wing It!
		Encode Multi Line Command
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
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


on stringAfter(sourceText, substring)
	if sourceText does not contain substring then return missing value
	if sourceText ends with substring then return missing value
	
	text ((offset of substring in sourceText) + (count of substring)) thru -1 of sourceText
end stringAfter


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


to removeUnicode(textWithUnicodeChar)
	do shell script "echo " & quoted form of textWithUnicodeChar & " | iconv -c -f utf-8 -t ascii || true"
end removeUnicode


(* Does not encode the parens () *)
(* 
on urlEncode(input)
	set jqPath to "/opt/homebrew/bin/jq"
	if jada's isWorkMac() then set jqPath to "/usr/local/bin/jq"
	
	do shell script "printf %s '" & input & "' | " & jqPath & " -sRr @uri"
	
	(* Fails when used in Workflow with some weird selector error.
	tell current application's NSString to set rawUrl to stringWithString_(input)
	set theEncodedURL to rawUrl's stringByAddingPercentEscapesUsingEncoding:4 -- 4 is NSUTF8StringEncoding
	
	theEncodedURL as Unicode text
	*)
end urlEncode
*)


(* 
	@Prefer to use urlEncode, unless encoding a shell command that can result in a conflict. 
	Visit https://www.urlencoder.org for an online tool.
*)
to encodeUrl(theString as text)
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


to decodeUrl(theString as text)
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
to formatNext(theString as text, theTokens as list)
	format(theString, theTokens)
end formatNext


(* Safer handler to use because it uses pure AppleScript and it does not shell out, so it does not conflict with the actual text. *)
to formatClassic(theString as text, theTokens as list)
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
	ucase(first character of theWord) & rest of characters of theWord
end title


to lower(theText)
	do shell script "echo '" & theText & "' | tr '[:upper:]' '[:lower:]'"
end lower


to upper(theText)
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


to splitWithTrim(theString as text, theDelimiter)
	set theList to split(theString, theDelimiter)
	set sanitized to {}
	repeat with next in theList
		set nextTrimmed to trim(next)
		if nextTrimmed is not equal to "" then set end of sanitized to nextTrimmed
	end repeat
	sanitized
end splitWithTrim


to join(aList, delimiter)
	set retval to ""
	repeat with i from 1 to (count of aList)
		set retval to retval & item i of aList
		if i is not equal to (count of aList) then set retval to retval & delimiter
	end repeat
	return retval
end join


to lastIndexOf(sourceText, substring)
	if (offset of substring in sourceText) is 0 then return 0
	set theList to my split(sourceText, substring)
	return (length of sourceText) - (length of last item of theList)
end lastIndexOf


to replaceAll(sourceText, substring, replacement)
	
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
		return replace(replacement & text startIdx thru length of sourceText, substring, replacement)
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


to rtrim(theText)
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


to ltrim(theText as text)
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
to trim(theText)
	-- do shell script "ruby -e \"p '" & theText & "'.strip\" | sed 's/\"//g'"
	do shell script "echo \"" & theText & "\" |  sed 's/ *$//g'  |  sed 's/^ *//g'"
end trim


(* Used for debugging to determine the ASCII number of each character of the string provided. *)
to printAsciiNumber(theString)
	repeat with nextChar in characters of theString
		log nextChar & " " & (ASCII number nextChar)
	end repeat
end printAsciiNumber


to isUnicode(theString)
	set inspected to ""
	repeat with nextChar in characters of theString
		set inspected to inspected & (ASCII character (ASCII number nextChar))
	end repeat
	theString is not equal to inspected
end isUnicode


on hasUnicode(theString)
	isUnicode(theString)
end hasUnicode


to removeEnding(theText as text, ending as text)
	try
		text 1 thru -((length of ending) + 1) of theText
	on error
		theText
	end try
end removeEnding


to unitTest()
	set utLib to std's import("unit-test")
	set ut to utLib's new()
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
		
		newMethod("decodeUrl")
		assertEqual("hello world", my decodeUrl("hello%20world"), "Basic")
		
		newMethod("stringAfter")
		assertEqual(missing value, my stringAfter("an apple a day", "orange "), "Not Found")
		assertEqual("a day", my stringAfter("an apple a day", "apple "), "Found")
		assertEqual(missing value, my stringAfter("an apple a day", "a day"), "In the end") -- I think missing value is more appropriate than empty string.
		
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
	
	return
	
	set actual801 to splitWithTrim("
	one,
	two
	", ",")
	set case801 to "Case 801: splitWithTrim - happy"
	std's assert({"one", "two"}, actual801, case801)
	
	set actual701 to replaceFirst("three one plus one", "one", "two")
	set case701 to "Case 701: replaceFirst - happy"
	std's assert("three two plus one", actual701, case701)
	
	set actual1 to replace("The amazing race", "The amazing race", "Great script")
	log "Case 1: Replace entire text: " & actual1
	if actual1 is not "Great script" then error "Assertion failed for case 1: " & actual1
	
	set actual2 to replace("abcdefg", "abc", "xyz")
	log "Case 2: Replace Beginning: " & actual2
	if actual2 is not "xyzdefg" then error "Assertion failed for case 2: " & actual2
	
	set actual5 to replace("", "cde", "")
	log "Case 5: Replace an empty string: " & actual5
	if actual5 is not "" then error "Assertion failed for case 5: " & actual5
	
	set actual6 to replace("abcdefg", "cde", "")
	log "Case 6: Replace with an empty string: " & actual6
	if actual6 is not "abfg" then error "Assertion failed for case 6: " & actual6
	
	set actual7 to replace("abcdefg", "xyz", "123")
	log "Case 7: Replace not found: " & actual7
	if actual7 is not "abcdefg" then error "Assertion failed for case 7: " & actual7
	
	set actual8 to replace("abcdefgabc", "b", "88")
	log "Case 8: Replace multiple: " & actual8
	if actual8 is not "a88cdefga88c" then error "Assertion failed for case 8: " & actual8
	
	set actual9 to replace("Macintosh HD:Users:cloud.strife:projects:@rt-learn-lang:applescript:DEPLOYED:Common:sublimetext3.applescript", ".applescript", ".scpt")
	log "Case 9: Replace multiple: " & actual9
	if actual9 is not "Macintosh HD:Users:cloud.strife:projects:@rt-learn-lang:applescript:DEPLOYED:Common:sublimetext3.scpt" then error "Assertion failed for case 9: " & actual9
	
	set actual101 to lastIndexOf("/Users/cloud.strife/projects/@rt-learn-lang/applescript/DEPLOYED/Common/sublimetext3.applescript", "*")
	set case101 to "Case 101: Last Index Of - Not found"
	std's assert(0, actual101, case101)
	
	set actual102 to lastIndexOf("/Users/cloud.strife", "/")
	set case102 to "Case 102: Last Index Of - Found"
	std's assert(7, actual102, case102)
	
	set actual201 to rtrim("1234  ")
	set case201 to "Case 201: Basic scenario"
	std's assert("1234", actual201, case201)
	
	set actual202 to rtrim("  ")
	set case202 to "Case 202: Spaces only"
	std's assert("", actual202, case202)
	
	set actual203 to rtrim("1234")
	set case203 to "Case 203: No trailing space"
	std's assert("1234", actual203, case203)
	
	set actual204 to rtrim("1234
")
	set case204 to "Case 204: Space and newline"
	std's assert("1234", actual204, case204)
	
	set actual301 to trim("    1234 abc    ")
	set case301 to "Case 301: Space and newline"
	std's assert("1234 abc", actual301, case301)
	
	set actual501 to format("Hello {}", "baby")
	set case501 to "Case 501: format - Single token"
	std's assert("Hello baby", actual501, case501)
	
	set actual502 to format("Hello {}, how are you {}", {"baby", "love"})
	set case502 to "Case 502: format - Multi token"
	std's assert("Hello baby, how are you love", actual502, case502)
	
	set actual503 to format("Hello {}, how are you {}", {"baby", "love/care"})
	set case503 to "Case 503: format - With forward slash"
	std's assert("Hello baby, how are you love/care", actual503, case503)
	
	set actual504 to format(" -i {} ec2-user", "~/.ssh/test.pem")
	set case504 to "Case 504: format - With forward slash - Actual"
	std's assert(" -i ~/.ssh/test.pem ec2-user", actual504, case504)
	
	set actual601 to substringFrom("", 5)
	set case601 to "Case 601: substringFrom - empty string, postive index"
	std's assert("", actual601, case601)
	
	logger's info("All unit test cases passed.")
end unitTest


to init()
	if initialized of me then return
	set initialized of me to true

	set std to script "std"
	set logger to std's import("logger")'s new("string")
end init
