(*!
	@header
	@abstract
		A template for unit testing.
	@discussion
		Copy this template in the folder containing the script to be tested and customize it as follows:

		1) Provide a description for this test suite and the name of the script to be tested.
		2) Write tests :)

	@charset macintosh
	@Created: November 30, 2023 10:06 AM
*)
use AppleScript
use scripting additions

use std : script "core/std"
use textUtil : script "core/string"             
use retryLib : script "core/retry"
    
property parent : script "com.lifepillar/ASUnit"

---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "safari-javascript" -- The name of the script to be tested
property testUrl : "http://localhost:8080"
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use loggerFactory : script "core/logger-factory"
property logger : missing value
property retry : missing value
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
		property parent : unitTest(me)
		try
			tell application "Finder"
				set deploymentPath to ((path to library folder from user domain) as text) & "Script Libraries:core:"
			end tell
			set sutScript to load script (deploymentPath & scriptName & ".scpt") as alias
			set retry to retryLib's new()
		end try
		assertInstanceOf(script, sutScript)
	end script
end script


script |getBaseFilename tests|
	property parent : TestSet(me)
	property sut : missing value 

	on setUp() 
		TopLevel's __createTestFile()
	end setUp

	on tearDown()
		TopLevel's __deleteTestFile()   
	end tearDown 

	script |Basic Test|
		property parent : unitTest(me)
		assertEqual("README.md", sutScript's getBaseFilename("/Users/cloud.strife/Projects/README.md"))
	end script
end script 
