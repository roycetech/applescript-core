(*
	Usage:
		use regex : script "regex"

	Tried both sed and ruby.  Let's use ruby for more flexibility and familiarity.
	WARNING: Do not use unicode characters, it does not work with the ruby commandline!

	@Build:
		make compile-lib SOURCE=core/regex

	@Known Issues:
		July 29, 2023 9:37 PM - Removed in plutil validation because it fails intermittently on the "matches" handler.

	@Last Modified: 2023-09-05 12:05:52
*)

use framework "Foundation"
use scripting additions

use std : script "std"

use textUtil : script "string"
use listUtil : script "list"

use loggerFactory : script "logger-factory"

use spotScript : script "core/spot-test"

property logger : missing value
property ERROR_INVALID_PATTERN : 1000


on numberOfMatchesInString(pattern as text, searchString)
	if searchString is missing value then return 0

	set nsregex to current application's NSRegularExpression's regularExpressionWithPattern:pattern options:0 |error|:(missing value)
	(nsregex's numberOfMatchesInString:searchString options:0 range:{location:0, |length|:(count searchString)}) as integer
end numberOfMatchesInString


on matchesInString(pattern, searchString)
	if pattern is missing value  or searchString is missing value then return false

	set anNSString to current application's NSString's stringWithString:searchString
	set stringLength to anNSString's |length|()
	set nsregex to current application's NSRegularExpression's regularExpressionWithPattern:pattern options:0 |error|:(missing value)

	-- Check if there was an error
	if nsregex is missing value then
	    error "Error: Unable to create NSRegularExpression /'" & pattern & "/" number ERROR_INVALID_PATTERN
	end if

	set match to nsregex's firstMatchInString:anNSString options:0 range:{0, stringLength}
	if match is not missing value then return true

	false
end matchesInString


on firstMatchInString(pattern, searchString)
	if searchString is missing value or pattern is missing value then return missing value

	set anNSString to current application's NSString's stringWithString:searchString
	set stringLength to anNSString's |length|()
	set nsregex to current application's NSRegularExpression's regularExpressionWithPattern:pattern options:0 |error|:(missing value)

	set match to nsregex's firstMatchInString:anNSString options:0 range:{0, stringLength}

	if match is not missing value then
		set matchRange to match's numberOfRanges()
		--> 1, so exists only one range, with index=0
		set matchRange to match's rangeAtIndex:0
	else
		return missing value
	end if

	text ((matchRange's location) + 1) thru ((matchRange's location) + (matchRange's |length|)) of searchString
end firstMatchInString


on firstMatchInStringNoCase(pattern, searchString)
	if searchString is missing value or pattern is missing value then return missing value

	ignoring case
		set anNSString to current application's NSString's stringWithString:searchString
		set stringLength to anNSString's |length|()
		set caseInsensitiveOption to current application's NSRegularExpressionCaseInsensitive
		set nsregex to current application's NSRegularExpression's regularExpressionWithPattern:pattern options:caseInsensitiveOption |error|:(missing value)

		set match to nsregex's firstMatchInString:anNSString options:0 range:{0, stringLength}
		if match is missing value then return missing value

		set matchRange to match's numberOfRanges()
		set matchRange to match's rangeAtIndex:0
		text ((matchRange's location) + 1) thru ((matchRange's location) + (matchRange's |length|)) of searchString
	end ignoring
end firstMatchInStringNoCase


(* To test, generated by GPT. *)
on lastMatchInString(pattern, searchString)
	if searchString is missing value or pattern is missing value then return missing value

	set anNSString to current application's NSString's stringWithString:searchString
	set stringLength to anNSString's |length|()
	set nsregex to current application's NSRegularExpression's regularExpressionWithPattern:pattern options:0 |error|:(missing value)

	set matches to nsregex's matchesInString:anNSString options:0 range:{0, stringLength}

	if (matches's |count|()) > 0 then
		set lastMatch to (matches's lastObject())'s range()
		return text ((lastMatch's location) + 1) thru ((lastMatch's location) + (lastMatch's |length|)) of searchString
	end if

	missing value
end lastMatchInString


on stringByReplacingMatchesInString(pattern, searchString, replacement)
	if searchString is missing value then return missing value
	if pattern is missing value then return searchString

	set searchNSString to current application's NSString's stringWithString:searchString
	set replaceNSString to current application's NSString's stringWithString:replacement
	set stringLength to searchNSString's |length|()
	set nsregex to current application's NSRegularExpression's regularExpressionWithPattern:pattern options:0 |error|:(missing value)
	if nsregex is missing value then error "Unsupported pattern: [" & pattern & "]" number ERROR_INVALID_PATTERN

	(nsregex's stringByReplacingMatchesInString:searchNSString options:0 range:{0, stringLength} withTemplate:replaceNSString) as text
end stringByReplacingMatchesInString


(* @returns list {offset, length} *)
on rangeOfFirstMatchInString(pattern, searchString)
	if pattern is missing value or searchString is missing value then return missing value

	set nsregex to current application's NSRegularExpression's regularExpressionWithPattern:pattern options:0 |error|:(missing value)
	set matchRange to (nsregex's rangeOfFirstMatchInString:searchString options:0 range:{location:0, |length|:(count searchString)})
	{(matchRange's location) + 1, matchRange's |length|}
end rangeOfFirstMatchInString


-- TODO: allMatchesInString


-- = Recommended Above = -----

(* replace all for initial implementation. *)
on replace(source, pattern, replacement)
	set escapedPattern to escapePattern(pattern)
	set escapedSource to escapeSource(source)
	(do shell script "ruby -e \"p '" & escapedSource & "'.gsub(/" & pattern & "/, '" & replacement & "')\" | sed 's/\"//g'")
end replace


(* Shell implementation is slower than the Objective-C equivalent. *)
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
	pattern
end escapePattern

