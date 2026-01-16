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

property parent : script "com.lifepillar/ASUnit"

---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "keyboard-maestro" -- The name of the script to be tested
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use loggerFactory : script "core/logger-factory"

use usrLib : script "core/user"

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
		set usr to usrLib's new()
		if usr's getDeploymentType() is "computer" then
			set objectDomain to local domain
		else
			set objectDomain to user domain
		end if
		try
			tell application "Finder"
				set deploymentPath to ((path to library folder from objectDomain) as text) & "Script Libraries:core:"
			end tell

			set sutScript to load script (deploymentPath & scriptName & ".scpt") as alias
		end try
		assertInstanceOf(script, sutScript)
	end script
end script


script |createTriggerLink tests|
	property parent : TestSet(me)
	property sut : missing value
	
	on setUp()
		set sut to sutScript's new()
	end setUp
	
	script |Basic, no params|
		property parent : UnitTest(me)
		assertEqual("kmtrigger://m=poc", sut's createTriggerLink("poc", missing value))
	end script
	script |Basic, with param|
		property parent : UnitTest(me)
		assertEqual("kmtrigger://m=poc&value=one", sut's createTriggerLink("poc", "one"))
	end script
end script

