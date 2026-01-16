(*!
	@header
	@abstract
		A template for unit testing.
	@discussion
		Copy this template in the folder containing the script to be tested and customize it as follows:

		1) Provide a description for this test suite and the name of the script to be tested.
		2) Write tests :)

	NOTE: Kills existing script editor app. Must not have a macro that auto-launches the app on quit.

	@Created: Thu, Jan 15, 2026, at 08:21:47 AM
*)
use AppleScript
use scripting additions

property parent : script "com.lifepillar/ASUnit"

---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "finder" -- The name of the script to be tested
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use loggerFactory : script "core/logger-factory"

use std : script "core/std"
use usrLib : script "core/user"
-- use scriptEditorUtilLib : script "core/test/script-editor-util"

property logger : missing value

-- property scriptEditorUtil : missing value

property TopLevel : me
property suite : makeTestSuite(suitename)

loggerFactory's inject(me)
-- set scriptEditorUtil to scriptEditorUtilLib's new()
autorun(suite)

---------------------------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------------------------

-- Don't change this test case if you are testing an external script
-- in the same folder as this test script! We load the script in a test case, because
-- this will work when all the tests in the current folder are run together using loadTestsFromFolder().
-- Besides, this will make sure that we are using the latest version of the script
-- to be tested even if we do not recompile this test script.
script |Load script - scriptEditorTest|
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


script |untilde tests|
	property parent : TestSet(me)
	property sut : missing value

	script |#beforeClass|
		property parent : UnitTest(me)
		set my sut to sutScript's new()
	end script	

	script |tilde only| 
		property parent : UnitTest(me)
		assertEqual("/Users/" & std's getUsername(), sut's untilde("~"))
	end script

	script |User Path|
		property parent : UnitTest(me)
		assertEqual("/Users/" & std's getUsername() & "/Documents", sut's untilde("~/Documents"))
	end script

	script |Non-user path|
		property parent : UnitTest(me)
		assertEqual("/Applications/AppleScript", sut's untilde("/Applications/AppleScript"))
	end script
end script
