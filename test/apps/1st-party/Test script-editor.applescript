(*!
	@header
	@abstract
		A template for unit testing.
	@discussion
		Copy this template in the folder containing the script to be tested and customize it as follows:

		1) Provide a description for this test suite and the name of the script to be tested.
		2) Write tests :)

	NOTE: Kills existing script editor app. Must not have a macro that auto-launches the app on quit.

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

use loggerFactory : script "core/logger-factory"

use usrLib : script "core/user"
use scriptEditorUtilLib : script "core/test/script-editor-util"

property logger : missing value

property scriptEditorUtil : missing value

property TopLevel : me
property suite : makeTestSuite(suitename)

property TEST_SCRIPT_CONTENT : "log \"Test Contents\""

loggerFactory's inject(me)
set scriptEditorUtil to scriptEditorUtilLib's new()
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


script |isNewDocumentWindowPresent tests|
	property parent : TestSet(me)
	property sut : missing value

	script |#beforeClass|
		property parent : UnitTest(me)
		TopLevel's scriptEditorUtil's killApp()
		set my sut to sutScript's new()
	end script	

	script |App not running|
		property parent : UnitTest(me)
		notOk(sut's isNewDocumentWindowPresent())  
	end script

	script |Script Editor Initial Launch|
		property parent : UnitTest(me)
		TopLevel's scriptEditorUtil's killApp()
		TopLevel's scriptEditorUtil's launchAppViaDock()
		TopLevel's scriptEditorUtil's quitApp()
		TopLevel's scriptEditorUtil's launchAppViaDock()
		ok(sut's isNewDocumentWindowPresent())  		
	end script

	script |Script Editor with a script|
		property parent : UnitTest(me)
		TopLevel's scriptEditorUtil's killApp()
		TopLevel's scriptEditorUtil's launchAppViaDock()
		TopLevel's scriptEditorUtil's getTestingTab()
		TopLevel's scriptEditorUtil's writeScript(TEST_SCRIPT_CONTENT)
		notOk(sut's isNewDocumentWindowPresent())  		
	end script
end script


script |getFrontContents tests|
	property parent : TestSet(me)
	property sut : missing value

	script |#beforeClass|
		property parent : UnitTest(me)
		TopLevel's scriptEditorUtil's getTestingTab()
		TopLevel's scriptEditorUtil's clearScript()
		set my sut to sutScript's new()
	end script	

	script |Empty script|
		property parent : UnitTest(me)
		assertEqual("", sut's getFrontContents())  
	end script

	script |With some script|
		property parent : UnitTest(me) 
		TopLevel's scriptEditorUtil's writeScript("log \"Test Contents\"")
		assertEqual("log \"Test Contents\"", sut's getFrontContents())
	end script 

	script |Script Editor not running|
		property parent : UnitTest(me)
		TopLevel's scriptEditorUtil's killApp()
		assertMissing(sut's getFrontContents()) 
	end script

	script |Script Editor at a new Document window|
		property parent : UnitTest(me)
		TopLevel's scriptEditorUtil's killApp()
		TopLevel's scriptEditorUtil's launchAppViaDock() 	
		assertMissing(sut's getFrontContents()) 
	end script

	script |#afterSuite|
		property parent : UnitTest(me)
		TopLevel's scriptEditorUtil's killApp()
	end script	
end script
