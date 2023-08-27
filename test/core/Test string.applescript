(*!
	@header
	@abstract
		A template for unit testing.
	@discussion
		Copy this template in the folder containing the script to be tested and customize it as follows:
	
		1) Provide a description for this test suite and the name of the script to be tested.
		2) Write tests :)

	@charset macintosh
	@Created: August 26, 2023 11:01 AM
*)
use AppleScript
use scripting additions

property parent : script "com.lifepillar/ASUnit"

---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "string" -- The name of the script to be tested
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use loggerFactory : script "logger-factory"

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
				set deploymentPath to ((path to library folder from user domain) as text) & "Script Libraries:"
			end tell
			
			set sutScript to load script (deploymentPath & scriptName & ".scpt") as alias
		end try
		assertInstanceOf(script, sutScript)
	end script
end script


script |stringBetween tests|
	property parent : TestSet(me)
		
	script |source text is missing value|
		property parent : UnitTest(me)
		assertMissing(sutScript's stringBetween(missing value, "abc", "xyz"))
	end script

	script |substringStart is missing value|
		property parent : UnitTest(me)
		assertMissing(sutScript's stringBetween("abcde", missing value, "xyz"))
	end script

	script |substringStart is not found|
		property parent : UnitTest(me)
		assertMissing(sutScript's stringBetween("abcde", "x", "e"))
	end script

	script |substringEnd is missing value|
		property parent : UnitTest(me)
		assertMissing(sutScript's stringBetween("abcde", "abc", missing value))
	end script

	script |substringEnd is not found|
		property parent : UnitTest(me)
		assertMissing(sutScript's stringBetween("abcde", "a", "x"))
	end script

	script |Happy|
		property parent : UnitTest(me)
		assertEqual("bc", sutScript's stringBetween("abcde", "a", "d"))
	end script


end script

