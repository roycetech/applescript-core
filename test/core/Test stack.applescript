(*!
	@header
	@abstract
		A template for unit testing.
	@discussion
		Copy this template in the folder containing the script to be tested and customize it as follows:

		1) Provide a description for this test suite and the name of the script to be tested.
		2) Write tests :)

	@charset macintosh
	@Created: September 4, 2023 1:40 PM
*)
use AppleScript
use scripting additions

property parent : script "com.lifepillar/ASUnit"

---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "stack" -- The name of the script to be tested
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

property TopLevel : me
property suite : makeTestSuite(suitename)

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


script |stack.clear tests|
	property parent : TestSet(me)

	script |Empty stack|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		sut's clear()
		assertEqual({}, _stack of sut)
	end script

	script |Non-empty stack|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set _stack of sut to {1}
		sut's clear()
		assertEqual({}, _stack of sut)
	end script
end script


script |stack.getSize tests|
	property parent : TestSet(me)

	script |Empty stack|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		assertEqual(0, sut's getSize())
	end script

	script |Non-empty stack|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set _stack of sut to {1}
		assertEqual(1, sut's getSize())
	end script
end script


script |stack.push tests|
	property parent : TestSet(me)

	script |Empty stack|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		sut's push(1)
		assertEqual({1}, _stack of sut)
	end script

	script |Non-empty stack|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set _stack of sut to {1}
		sut's push(2)
		assertEqual({1, 2}, _stack of sut)
	end script
end script


script |stack.peek tests|
	property parent : TestSet(me)

	script |Empty stack|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		assertMissing(sut's peek())
	end script

	script |Non-empty stack|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set _stack of sut to {1}
		
		assertEqual(1, sut's peek())
	end script
end script


script |stack.pop() tests|
	property parent : TestSet(me)

	script |Empty stack|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		assertMissing(sut's pop())
	end script

	script |Non-empty stack|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set _stack of sut to {1}
		assertEqual(1, sut's pop())
		assertEqual({}, _stack of sut)
	end script
end script
