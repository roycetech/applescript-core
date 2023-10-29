(*!
	@header
	@abstract
		A template for unit testing.
	@discussion
		Copy this template in the folder containing the script to be tested and customize it as follows:
	
		1) Provide a description for this test suite and the name of the script to be tested.
		2) Write tests :)

	@charset macintosh
	@Created:
*)
use AppleScript
use scripting additions
 
use omz : script "core/oh-my-zsh"

property parent : script "com.lifepillar/ASUnit"

---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "regex-pattern" -- The name of the script to be tested
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use loggerFactory : script "core/logger-factory"

property logger : missing value

property TopLevel : me
property suite : makeTestSuite(suitename)

loggerFactory's inject(me)
autorun(suite)

---------------------------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------------------------

-- Don't change this test case if you are testing an external script
-- in the same folder as this test script! We load the script in a test case, because
-- this will work when all the tests in the current folder are run together using loadTestsFromFolder().
-- Besides, this will make sure that we are using the latest version of the script
-- to be tested even if we do not recompile this test script.
script |Load script|
	property parent : TestSet(me)
	script |Loading the script|
		property parent : UnitTest(me)
		try
			tell application "Finder"
				set deploymentPath to ((path to library folder from user domain) as text) & "Script Libraries:core:"
			end tell
			
			set sutScript to load script (deploymentPath & scriptName & ".scpt") as alias
		end try
		assertInstanceOf(script, sutScript)
	end script
end script


script |regex-pattern numberOfMatchesInString tests|
	property parent : TestSet(me)

	script |Missing source text|
		property parent : UnitTest(me)
		set sut to sutScript's new(".*")
		assertEqual(0, sut's numberOfMatchesInString(missing value))
	end script

	script |Happy Case|
		property parent : UnitTest(me)
		set sut to sutScript's new("\\w+")
		assertEqual(2, sut's numberOfMatchesInString("hello world -"))
	end script
end script


(* (pattern, searchString) *)
script |lastMatchInString tests|
	property parent : TestSet(me)
	
	script |searchString is missing value|
		property parent : UnitTest(me)
		set sut to sutScript's new("abc")
		assertMissing(sut's lastMatchInString(missing value))
	end script

	script |Not found|
		property parent : UnitTest(me)
		set sut to sutScript's new("abc")
		assertMissing(sut's lastMatchInString("autonomy"))
	end script

	script |Multiple Matches|
		property parent : UnitTest(me)
		set sut to sutScript's new("\\d")
		assertEqual("3", sut's lastMatchInString("Buy 1 take 3"))
	end script

	script |Single Match|
		property parent : UnitTest(me)
		set sut to sutScript's new("\\d")
		assertEqual("1", sut's lastMatchInString("Buy 1 take four"))
	end script
end script


script |regex-pattern findFirst tests|
	property parent : TestSet(me)

	script |Happy Case|
		property parent : UnitTest(me)
		set pattern to  "https:\\/\\/\\w+\\.\\w+\\.\\w+\\/j\\/\\d+(?:\\?pwd=\\w+)?"
		set sut to sutScript's new(pattern)
		set source to "B + S Daily Standup at https://awesome.zoom.us/j/123456789. Starts on September 15, 2020 at 8:00:00 AM Norwegian Standard Time and ends at 8:15:00 AM Norwegian Standard Time."
		assertEqual("https://awesome.zoom.us/j/123456789", sut's findFirst(source, pattern))
	end script
end script


script |regex-pattern matched tests|
	property parent : TestSet(me)

	script |Found|
		property parent : UnitTest(me)
		set sut to sutScript's new("maz")
		ok(sut's matched("amazing"))
	end script

	script |Not Found|
		property parent : UnitTest(me)
		set sut to sutScript's new("Amaz")
		notOk(sut's matched("amazing"))
	end script

	script |Starting with|
		property parent : UnitTest(me)
		set sut to sutScript's new("^amaz")
		ok(sut's matched("amazing"))
	end script

	script |Not starting with|
		property parent : UnitTest(me)
		set sut to sutScript's new("^maz")
		notOk(sut's matched("amazing"))
	end script

	script |Ending with|
		property parent : UnitTest(me)
		set sut to sutScript's new("ing$")
		ok(sut's matched("amazing"))
	end script

	script |Not ending with| 
		property parent : UnitTest(me)
		set sut to sutScript's new("inn$")
		notOk(sut's matched("amazing"))
	end script

	script |Whole word|
		property parent : UnitTest(me)
		set sut to sutScript's new("\\bmaz\\b")
		ok(sut's matched("a maz ing"))
	end script

	script |Not whole word| 
		property parent : UnitTest(me)
		set sut to sutScript's new("\\bmaz\\b")
		notOk(sut's matched("amazing"))
	end script

	script |Invalid Expression| 
		property parent : UnitTest(me)
		script Lambda
		set sut to sutScript's new("\\bmaz\\")
			sut's matched("amazing")
		end script
		shouldRaise(sutScript's ERROR_INVALID_PATTERN, Lambda, "Invalid regular expression but no error raised")
	end script
end script


script |replace tests|
	property parent : TestSet(me)
	
	script |Replace groups|
		property parent : UnitTest(me)
		set sut to sutScript's new("(\\d+)")
		assertEqual("These number(12) and number(354)", sut's replace("These 12 and 354", "number(\\1)"))
	end script

	script |Extract info|
		property parent : UnitTest(me)
		set sut to sutScript's new("Email : (\\w+@mailinator.com)")
		assertEqual("riojenhbkcm@mailinator.com", sut's replace("Email : riojenhbkcm@mailinator.com", "\\1"))
	end script

	script |With a single quote|
		property parent : UnitTest(me)
		set sut to sutScript's new("Ca")
		assertEqual("Don't", sut's replace("Can't", "Do"))
	end script

	script |Number with decimal|
		property parent : UnitTest(me)
		set sut to sutScript's new("\\.6{3,}7?")
		assertEqual("Can't set window id 3864 to {1146 and one third, 719.0}.", sut's replace("Can't set window id 3864 to {1146.66666666, 719.0}.", " and one third"))
	end script
end script


script |firstMatchInString tests|
	property parent : TestSet(me)
	property sut : missing value

	script |Basic match|
		property parent : UnitTest(me)
		set sut to sutScript's new("\\w+")
		assertEqual("hello", sut's firstMatchInString("hello world"))
	end script

	script |No match|
		property parent : UnitTest(me)
		set sut to sutScript's new("\\d+")
		assertMissing(sut's firstMatchInString("hello world"))
	end script

	script |Different case|
		property parent : UnitTest(me)
		set sut to sutScript's new("abc")
		assertMissing(sut's firstMatchInString("the world of ABC is ok."))
	end script
end script


script |firstMatchInStringNoCase tests|
	property parent : TestSet(me)
	property sut : missing value

	script |No match|
		property parent : UnitTest(me)
		set sut to sutScript's new("\\d+")
		assertMissing(sut's firstMatchInStringNoCase("hello world"))
	end script

	script |Case-sensitive match|
		property parent : UnitTest(me)
		set sut to sutScript's new("hello")
		assertEqual("hello", sut's firstMatchInStringNoCase("hello world"))
	end script

	script |Case-insensitive match|
		property parent : UnitTest(me)
		set sut to sutScript's new("HELLO")
		assertEqual("hello", sut's firstMatchInStringNoCase("hello world"))
	end script
end script


script |rangeOfFirstMatchInString tests|
	property parent : TestSet(me)
	property sut : missing value

	script |String is missing value|
		property parent : UnitTest(me)
		set sut to sutScript's new("\\w")
		assertMissing(sut's rangeOfFirstMatchInString(missing value))
	end script

	script |Happy Case|
		property parent : UnitTest(me)
		set sut to sutScript's new("\\d+")
		assertEqual({16, 5}, sut's rangeOfFirstMatchInString("Hello prisoner 14867"))
	end script
end script


script |matchesInString tests|
	property parent : TestSet(me)
	property sut : missing value

	script |String is missing value|
		property parent : UnitTest(me)
		set sut to sutScript's new("\\w")
		notOk(sut's matchesInString(missing value))
	end script

	script |End of line example|
		property parent : UnitTest(me)
		set sut to sutScript's new("\\w+$")
		notOk(sut's matchesInString("hello world "))
	end script

	script |session - fails intermittently on Terminal Focus|
		property parent : UnitTest(me)
		set sut to sutScript's new("^(?:[a-zA-Z0-9_-]+/)*[a-zA-Z0-9_-]+$")
		ok(sut's matchesInString("session")) 
	end script
end script


script |stringByReplacingMatchesInString tests|
	property parent : TestSet(me)
	property sut : missing value

	script |Pattern with unicode|
		property parent : UnitTest(me)
		set sut to sutScript's new(omz's OMZ_ARROW & "  [a-zA-Z-]+\\sgit:\\([a-zA-Z0-9/-]+\\)(?: " & omz's OMZ_GIT_X & ")?\\s")
		assertEqual("docker network", sut's stringByReplacingMatchesInString(omz's OMZ_ARROW & "  some-project git:(feature/RT-1000-Some-Feature) " & omz's OMZ_GIT_X & " docker network", ""))
	end script

	script |Basic match|
		property parent : UnitTest(me)
		set sut to sutScript's new("hello")
		assertEqual(" world", sut's stringByReplacingMatchesInString("hello world", ""))
	end script

	script |Pattern is invalid|
		property parent : UnitTest(me)
		script Lambda
			set sut to sutScript's new("[invalid")
			sut's stringByReplacingMatchesInString("some string", "change it!")
		end script
		shouldRaise(sutScript's ERROR_INVALID_PATTERN, Lambda, "Expected error was not thrown")
	end script
end script
