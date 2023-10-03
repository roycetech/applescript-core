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
property scriptName : "regex" -- The name of the script to be tested
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


(* (pattern, searchString) *)
script |lastMatchInString tests|
	property parent : TestSet(me)
	
	script |searchString is missing value|
		property parent : UnitTest(me)
		assertMissing(sutScript's lastMatchInString("abc", missing value))
	end script

	script |pattern is missing value|
		property parent : UnitTest(me)
		assertMissing(sutScript's lastMatchInString(missing value, "abc"))
	end script

	script |Not found|
		property parent : UnitTest(me)
		assertMissing(sutScript's lastMatchInString("abc", "autonomy"))
	end script

	script |Multiple Matches|
		property parent : UnitTest(me)
		assertEqual("3", sutScript's lastMatchInString("\\d", "Buy 1 take 3"))
	end script

	script |Single Match|
		property parent : UnitTest(me)
		assertEqual("1", sutScript's lastMatchInString("\\d", "Buy 1 take four"))
	end script
end script


script |regex numberOfMatchesInString tests|
	property parent : TestSet(me)

	script |Missing pattern|
		property parent : UnitTest(me)
		assertEqual(0, sutScript's numberOfMatchesInString(missing value, "hello world -"))
	end script

	script |Missing source text|
		property parent : UnitTest(me)
		assertEqual(0, sutScript's numberOfMatchesInString(".*", missing value))
	end script

	script |Happy Case|
		property parent : UnitTest(me)
		assertEqual(2, sutScript's numberOfMatchesInString("\\w+", "hello world -"))
	end script
end script



script |regex findFirst tests|
	property parent : TestSet(me)

	script |Happy Case|
		property parent : UnitTest(me)
		set source to "B + S Daily Standup at https://awesome.zoom.us/j/123456789. Starts on September 15, 2020 at 8:00:00 AM Norwegian Standard Time and ends at 8:15:00 AM Norwegian Standard Time."
		set pattern to  "https:\\/\\/\\w+\\.\\w+\\.\\w+\\/j\\/\\d+(?:\\?pwd=\\w+)?"
		assertEqual("https://awesome.zoom.us/j/123456789", sutScript's findFirst(source, pattern))
	end script
end script


script |regex matched tests|
	property parent : TestSet(me)

	script |Found|
		property parent : UnitTest(me)
		ok(sutScript's matched("amazing", "maz"))
	end script

	script |Not Found|
		property parent : UnitTest(me)
		notOk(sutScript's matched("amazing", "Amaz"))
	end script

	script |Starting with|
		property parent : UnitTest(me)
		ok(sutScript's matched("amazing", "^amaz"))
	end script

	script |Not starting with|
		property parent : UnitTest(me)
		notOk(sutScript's matched("amazing", "^maz"))
	end script

	script |Ending with|
		property parent : UnitTest(me)
		ok(sutScript's matched("amazing", "ing$"))
	end script

	script |Not ending with| 
		property parent : UnitTest(me)
		notOk(sutScript's matched("amazing", "inn$"))
	end script

	script |Whole word|
		property parent : UnitTest(me)
		ok(sutScript's matched("a maz ing", "\\bmaz\\b"))
	end script

	script |Not whole word| 
		property parent : UnitTest(me)
		notOk(sutScript's matched("amazing", "\\bmaz\\b"))
	end script

	script |Invalid Expression| 
		property parent : UnitTest(me)
		script Lambda
			sutScript's matched("amazing", "\\bmaz\\")
		end script
		shouldRaise(sutScript's ERROR_INVALID_PATTERN, Lambda, "Invalid regular expression but no error raised")
	end script
end script


script |replace tests|
	property parent : TestSet(me)
	
	script |Replace groups|
		property parent : UnitTest(me)
		assertEqual("These number(12) and number(354)", sutScript's replace("These 12 and 354", "(\\d+)", "number(\\1)"))
	end script

	script |Extract info|
		property parent : UnitTest(me)
		assertEqual("riojenhbkcm@mailinator.com", sutScript's replace("Email : riojenhbkcm@mailinator.com", "Email : (\\w+@mailinator.com)", "\\1"))
	end script

	script |With a single quote|
		property parent : UnitTest(me)
		assertEqual("Don't", sutScript's replace("Can't", "Ca", "Do"))
	end script

	script |Number with decimal|
		property parent : UnitTest(me)
		assertEqual("Can't set window id 3864 to {1146 and one third, 719.0}.", sutScript's replace("Can't set window id 3864 to {1146.66666666, 719.0}.", "\\.6{3,}7?", " and one third"))
	end script
end script


script |firstMatchInString tests|
	property parent : TestSet(me)
	property sut : missing value

	script |Basic match|
		property parent : UnitTest(me)
		assertEqual("hello", sutScript's firstMatchInString("\\w+", "hello world"))
	end script

	script |No match|
		property parent : UnitTest(me)
		assertMissing(sutScript's firstMatchInString("\\d+", "hello world"))
	end script

	script |Different case|
		property parent : UnitTest(me)
		assertMissing(sutScript's firstMatchInString("abc", "the world of ABC is ok."))
	end script
end script


script |firstMatchInStringNoCase tests|
	property parent : TestSet(me)
	property sut : missing value

	script |Missing pattern|
		property parent : UnitTest(me)
		assertMissing(sutScript's firstMatchInStringNoCase(missing value, "hello world"))
	end script

	script |No match|
		property parent : UnitTest(me)
		assertMissing(sutScript's firstMatchInStringNoCase("\\d+", "hello world"))
	end script

	script |Case-sensitive match|
		property parent : UnitTest(me)
		assertEqual("hello", sutScript's firstMatchInStringNoCase("hello", "hello world"))
	end script

	script |Case-insensitive match|
		property parent : UnitTest(me)
		assertEqual("hello", sutScript's firstMatchInStringNoCase("HELLO", "hello world"))
	end script
end script


script |rangeOfFirstMatchInString tests|
	property parent : TestSet(me)
	property sut : missing value

	script |String is missing value|
		property parent : UnitTest(me)
		assertMissing(sutScript's rangeOfFirstMatchInString("\\w", missing value))
	end script

	script |Pattern is missing value|
		property parent : UnitTest(me)
		assertMissing(sutScript's rangeOfFirstMatchInString(missing value, "abc"))
	end script

	script |Happy Case|
		property parent : UnitTest(me)
		assertEqual({16, 5}, sutScript's rangeOfFirstMatchInString("\\d+", "Hello prisoner 14867"))
	end script
end script


script |matchesInString tests|
	property parent : TestSet(me)
	property sut : missing value

	script |String is missing value|
		property parent : UnitTest(me)
		notOk(sutScript's matchesInString("\\w", missing value))
	end script

	script |Pattern is missing value|
		property parent : UnitTest(me)
		notOk(sutScript's matchesInString(missing value, "abc"))
	end script

	script |End of line example|
		property parent : UnitTest(me)
		notOk(sutScript's matchesInString("\\w+$", "hello world "))
	end script

	script |session - fails intermittently on Terminal Focus|
		property parent : UnitTest(me)
		ok(sutScript's matchesInString("^(?:[a-zA-Z0-9_-]+/)*[a-zA-Z0-9_-]+$", "session"))
	end script
end script


script |stringByReplacingMatchesInString tests|
	property parent : TestSet(me)
	property sut : missing value

	script |Pattern with unicode|
		property parent : UnitTest(me)
		assertEqual("docker network", sutScript's stringByReplacingMatchesInString(omz's OMZ_ARROW & "  [a-zA-Z-]+\\sgit:\\([a-zA-Z0-9/-]+\\)(?: " & omz's OMZ_GIT_X & ")?\\s", omz's OMZ_ARROW & "  some-project git:(feature/RT-1000-Some-Feature) " & omz's OMZ_GIT_X & " docker network", ""))
	end script

	script |Basic match|
		property parent : UnitTest(me)
		assertEqual(" world", sutScript's stringByReplacingMatchesInString("hello", "hello world", ""))
	end script

	script |Pattern is missing value|
		property parent : UnitTest(me)
		assertEqual("unchanged", sutScript's stringByReplacingMatchesInString(missing value, "unchanged", "change it!"))
	end script

	script |Pattern is invalid|
		property parent : UnitTest(me)
		script Lambda
			sutScript's stringByReplacingMatchesInString("[invalid", "some string", "change it!")
		end script
		shouldRaise(sutScript's ERROR_INVALID_PATTERN, Lambda, "Expected error was not thrown")
	end script

end script

