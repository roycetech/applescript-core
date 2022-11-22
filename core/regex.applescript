global std, logger, textUtil, uni

(*
	Usage:
		set regex to std's import("regex")

	Tried both sed and ruby.  Let's use ruby for more flexibility and familiarity.
	WARNING: Do not use unicode characters, it does not work with the ruby commandline!
*)

property initialized : false

-- spotCheck() -- IMPORTANT: Comment out on deploy.

use framework "Foundation"
use scripting additions


to spotCheck()
	init()
	set thisCaseId to "regex-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Unit Test
		Quickie
		Case Insensitive Match
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
		log rangeOfFirstMatchInString("\\d+", "Hello prisoner 14867")
		log stringByReplacingMatchesInString(uni's OMZ_ARROW & "  [a-zA-Z-]+\\sgit:\\([a-zA-Z0-9/-]+\\)(?: " & uni's OMZ_GIT_X & ")?\\s", uni's OMZ_ARROW & "  mobile-gateway git:(feature/MT-3644-Mobile-Gateway-create-service-adapter) " & uni's OMZ_GIT_X & " docker network", "")
		
		log stringByReplacingMatchesInString("hello", "hello world", "")
		log firstMatchInString("\\w+", "hello world")
		log matchesInString("\\w+$", "hello world ")
		log numberOfMatchesInString("\\w+", "hello world -")
		
	else if caseIndex is 3 then
		log firstMatchInStringNoCase("abc", "the world of ABC is ok.")
		log firstMatchInString("abc", "the world of ABC is ok.")
		log firstMatchInStringNoCase("abc", "the world of abc is ok.")
		log firstMatchInString("abc", "the world of abc is ok.")
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


to numberOfMatchesInString(pattern as text, searchString as text)
	set regex to current application's NSRegularExpression's regularExpressionWithPattern:pattern options:0 |error|:(missing value)
	return (regex's numberOfMatchesInString:searchString options:0 range:{location:0, |length|:(count searchString)}) as integer
end numberOfMatchesInString


to matchesInString(pattern as text, searchString as text)
	set anNSString to current application's NSString's stringWithString:searchString
	set stringLength to anNSString's |length|()
	set theRegex to current application's NSRegularExpression's regularExpressionWithPattern:pattern options:0 |error|:(missing value)
	set match to theRegex's firstMatchInString:anNSString options:0 range:{0, stringLength}
	if match is not missing value then return true
	
	false
end matchesInString


to firstMatchInString(pattern as text, searchString as text)
	set anNSString to current application's NSString's stringWithString:searchString
	set stringLength to anNSString's |length|()
	set theRegex to current application's NSRegularExpression's regularExpressionWithPattern:pattern options:0 |error|:(missing value)
	
	set match to theRegex's firstMatchInString:anNSString options:0 range:{0, stringLength}
	
	if match is not missing value then
		set matchRange to match's numberOfRanges()
		--> 1, so exists only one range, with index=0
		set matchRange to match's rangeAtIndex:0
	else
		return missing value
	end if
	
	text ((matchRange's location) + 1) thru ((matchRange's location) + (matchRange's |length|)) of searchString
end firstMatchInString


to firstMatchInStringNoCase(pattern as text, searchString as text)
	ignoring case
		set anNSString to current application's NSString's stringWithString:searchString
		set stringLength to anNSString's |length|()
		set caseInsensitiveOption to current application's NSRegularExpressionCaseInsensitive
		set theRegex to current application's NSRegularExpression's regularExpressionWithPattern:pattern options:caseInsensitiveOption |error|:(missing value)
		
		set match to theRegex's firstMatchInString:anNSString options:0 range:{0, stringLength}
		if match is missing value then return missing value
		
		set matchRange to match's numberOfRanges()
		set matchRange to match's rangeAtIndex:0
		text ((matchRange's location) + 1) thru ((matchRange's location) + (matchRange's |length|)) of searchString
	end ignoring
end firstMatchInStringNoCase


to stringByReplacingMatchesInString(pattern, searchString, replacement)
	set searchNSString to current application's NSString's stringWithString:searchString
	set replaceNSString to current application's NSString's stringWithString:replacement
	set stringLength to searchNSString's |length|()
	set theRegex to current application's NSRegularExpression's regularExpressionWithPattern:pattern options:0 |error|:(missing value)
	(theRegex's stringByReplacingMatchesInString:searchNSString options:0 range:{0, stringLength} withTemplate:replaceNSString) as text
end stringByReplacingMatchesInString


(* @returns list {offset, length} *)
on rangeOfFirstMatchInString(pattern as text, searchString as text)
	set regex to current application's NSRegularExpression's regularExpressionWithPattern:pattern options:0 |error|:(missing value)
	set matchRange to (regex's rangeOfFirstMatchInString:searchString options:0 range:{location:0, |length|:(count searchString)})
	{matchRange's location, matchRange's |length|}
end rangeOfFirstMatchInString


-- TODO: allMatchesInString


-- = Recommended Above = -----

(* replace all for initial implementation. *)
to replace(source, pattern, replacement)
	set escapedPattern to escapePattern(pattern)
	set escapedSource to escapeSource(source)
	(do shell script "ruby -e \"p '" & escapedSource & "'.gsub(/" & pattern & "/, '" & replacement & "')\" | sed 's/\"//g'")
end replace


(* Shell implementation is slower the the Objective-C equivalent. *)
to matched(source, pattern)
	matchesInString(pattern, source)
end matched


to matches(pattern, source)
	matched(source, pattern)
end matches


to findFirst(source, pattern)
	_checkUnicode(source)
	
	set escapedPattern to escapePattern(pattern)
	set escapedSource to escapeSource(source)
	
	do shell script "ruby -e \"p '" & escapedSource & "'[/" & escapedPattern & "/]\" | sed 's/\"//g'"
end findFirst


-- Private Codes below =======================================================
to escapeSource(source)
	textUtil's replace(source, "'", "\\'")
end escapeSource


to escapePattern(pattern)
	return pattern
end escapePattern

(*
	Handler grouped by hundredths.
	Put the case you are debugging at the top, and move to correct place once verified.
*)
to unitTest()
	set actual101 to findFirst("Badgers + Scrappers Daily Standup at https://awesome.zoom.us/j/123456789. Starts on September 15, 2020 at 8:00:00 AM Philippine Standard Time and ends at 8:15:00 AM Philippine Standard Time.", "https:\\/\\/\\w+\\.\\w+\\.\\w+\\/j\\/\\d+(?:\\?pwd=\\w+)?")
	set case101 to "Case 101: Found"
	std's assert("https://awesome.zoom.us/j/123456789", actual101, case101)
	
	
	set actual101 to matched("amazing", "maz")
	set case101 to "Case 101: Found"
	std's assert(true, actual101, case101)
	
	set actual102 to matched("amazing", "Amaz")
	set case102 to "Case 102: Not Found"
	std's assert(false, actual102, case102)
	
	set actual103 to matched("amazing", "^maz")
	set case103 to "Case 103: ^, mismatch"
	std's assert(false, actual103, case103)
	
	set actual104 to matched("amazing", "ing$")
	set case104 to "Case 104: $, matched"
	std's assert(true, actual104, case104)
	
	set actual105 to matched("amazing ", "ing$")
	set case105 to "Case 105: $, mismatched"
	std's assert(false, actual105, case105)
	
	set actual106 to matched("session", "\\bse\\b")
	set case106 to "Case 106: \\b, non-whole word"
	std's assert(false, actual106, case106)
	
	set actual107 to matched("se", "\\bse\\b")
	set case107 to "Case 107: \\b, whole word"
	std's assert(true, actual107, case107)
	
	set actual201 to replace("These 12 and 354", "(\\d+)", "number(\\1)")
	-- set actual201 to replace("These 12 and 354", "([[:digit:]]+)", "number(\\1)")
	set case201 to "Case 201: Replace group"
	std's assert("These number(12) and number(354)", actual201, case201)
	
	-- set actual202 to replace("Email : riojenhbkcm@mailinator.com", "Email : ([[:alnum:]]+@mailinator.com)", "\\1")
	set actual202 to replace("Email : riojenhbkcm@mailinator.com", "Email : (\\w+@mailinator.com)", "\\1")
	set case202 to "Case 202: Extracting info"
	std's assert("riojenhbkcm@mailinator.com", actual202, case202)
	
	set actual203 to replace("Can't", "an", "on")
	set case203 to "Case 203: With illegal quote"
	std's assert("Con't", actual203, case203)
	
	set actual204 to replace("Can't set window id 3864 to {1146.66666666, 719.0}.", "\\.6{3,}7?", " and one third")
	set case204 to "Case 204: Number with decimal"
	std's assert("Can't set window id 3864 to {1146 and one third, 719.0}.", actual204, case204)
	
	set actual301 to findFirst("Email : riojenhbkcm@mailinator.com", "\\w+@mailinator.com")
	set case301 to "Case 301: Extracting info"
	std's assert("riojenhbkcm@mailinator.com", actual301, case301)
	
	logger's info("All unit test cases passed.")
end unitTest


on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("regex")
	set textUtil to std's import("string")
	set uni to std's import("unicodes")
end init