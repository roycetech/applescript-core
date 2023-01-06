global std, textUtil

(*
	Usage:
		set regex to std's import("regex")

	Tried both sed and ruby.  Let's use ruby for more flexibility and familiarity.
	WARNING: Do not use unicode characters, it does not work with the ruby commandline!
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

use framework "Foundation"
use scripting additions


on spotCheck()
	init()
	set thisCaseId to "regex-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	set uni to std's import("unicodes")
	
	set cases to listUtil's splitByLine("
		Unit Test
		Quickie
		Case Insensitive Match
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


on numberOfMatchesInString(pattern as text, searchString as text)
	set regex to current application's NSRegularExpression's regularExpressionWithPattern:pattern options:0 |error|:(missing value)
	return (regex's numberOfMatchesInString:searchString options:0 range:{location:0, |length|:(count searchString)}) as integer
end numberOfMatchesInString


on matchesInString(pattern as text, searchString as text)
	set anNSString to current application's NSString's stringWithString:searchString
	set stringLength to anNSString's |length|()
	set theRegex to current application's NSRegularExpression's regularExpressionWithPattern:pattern options:0 |error|:(missing value)
	set match to theRegex's firstMatchInString:anNSString options:0 range:{0, stringLength}
	if match is not missing value then return true
	
	false
end matchesInString


on firstMatchInString(pattern as text, searchString as text)
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


on firstMatchInStringNoCase(pattern as text, searchString as text)
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


on stringByReplacingMatchesInString(pattern, searchString, replacement)
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
on replace(source, pattern, replacement)
	set escapedPattern to escapePattern(pattern)
	set escapedSource to escapeSource(source)
	(do shell script "ruby -e \"p '" & escapedSource & "'.gsub(/" & pattern & "/, '" & replacement & "')\" | sed 's/\"//g'")
end replace


(* Shell implementation is slower the the Objective-C equivalent. *)
on matched(source, pattern)
	matchesInString(pattern, source)
end matched


on matches(pattern, source)
	matched(source, pattern)
end matches


on findFirst(source, pattern)
	set escapedPattern to escapePattern(pattern)
	set escapedSource to escapeSource(source)
	
	do shell script "ruby -e \"p '" & escapedSource & "'[/" & escapedPattern & "/]\" | sed 's/\"//g'"
end findFirst


-- Private Codes below =======================================================
on escapeSource(source)
	textUtil's replace(source, "'", "\\'")
end escapeSource


on escapePattern(pattern)
	return pattern
end escapePattern

(*
	Handler grouped by hundredths.
	Put the case you are debugging at the top, and move to correct place once verified.
*)
on unitTest()
	set utLib to std's import("unit-test")
	set ut to utLib's new()
	tell ut
		newMethod("findFirst")
		assertEqual("https://awesome.zoom.us/j/123456789", my findFirst("B + S Daily Standup at https://awesome.zoom.us/j/123456789. Starts on September 15, 2020 at 8:00:00 AM Philippine Standard Time and ends at 8:15:00 AM Philippine Standard Time.", "https:\\/\\/\\w+\\.\\w+\\.\\w+\\/j\\/\\d+(?:\\?pwd=\\w+)?"), "Happy: Found")
		
		newMethod("matched")
		assertTrue(my matched("amazing", "maz"), "Found")
		assertFalse(my matched("amazing", "Amaz"), "Not Found")
		assertTrue(my matched("amazing", "^amaz"), "Starting with")
		assertFalse(my matched("amazing", "^maz"), "Not starting with")
		assertTrue(my matched("amazing", "zing$"), "Ending with")
		assertFalse(my matched("amazing", "zin$"), "Not ending with")
		assertTrue(my matched("a maz ing", "\\bmaz\\b"), "Whole word")
		assertFalse(my matched("amazing", "\\bmaz\\b"), "Not whole word")
		
		newMethod("replace")
		assertEqual("These number(12) and number(354)", my replace("These 12 and 354", "(\\d+)", "number(\\1)"), "Replace a group")
		assertEqual("riojenhbkcm@mailinator.com", my replace("Email : riojenhbkcm@mailinator.com", "Email : (\\w+@mailinator.com)", "\\1"), "Extract info")
		assertEqual("Don't", my replace("Can't", "Ca", "Do"), "With a single quote")
		assertEqual("Can't set window id 3864 to {1146 and one third, 719.0}.", my replace("Can't set window id 3864 to {1146.66666666, 719.0}.", "\\.6{3,}7?", " and one third"), "Number with decimal")
		
		done()
	end tell
	
	logger's info("All unit test cases passed.")
end unitTest


on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("regex")
	set textUtil to std's import("string")
end init