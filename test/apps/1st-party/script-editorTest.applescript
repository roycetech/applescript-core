(*!
	@header
	@abstract
		A template for unit testing.
	@discussion
		Copy this template in the folder containing the script to be tested and customize it as follows:

		1) Provide a description for this test suite and the name of the script to be tested.
		2) Write tests :)

	@charset macintosh
	@Created: July 26, 2023 3:07 PM
*)
use AppleScript
use scripting additions

property parent : script "com.lifepillar/ASUnit"

---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "script-editor" -- The name of the script to be tested
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use loggerFactory : script "logger-factory"
use testUtilLib : script "test-util"

property logger : missing value

property TopLevel : me
property suite : makeTestSuite(suitename)

loggerFactory's inject(me)
set testUtil to testUtilLib's new("plist-buddy-test")
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


script |getRootKeys tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	(* Manually Set *)
	property totalTestCases : 1  -- Current Test
	property sut : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
	end setUp
	on tearDown()
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
	end beforeClass
	on afterClass()
	end afterClass

	script |test something|
		property parent : UnitTest(me)
		ok(false)
	end script
end script
