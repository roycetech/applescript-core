(*!
	Script Editor app needs to be NOT running initially.
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
property scriptName : "dec-script-editor-content" -- The name of the script to be tested
property tempFile : missing value -- The name of the temp file to open the Script Editor app with.
global sutBaseScript -- The variable holding the base script to be wrapped
global sutScript -- The variable holding the decorator script to be tested
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
				set deploymentPath to ((path to library folder from user domain) as text) & "Script Libraries:"
			end tell
			set sutBaseScript to load script (deploymentPath & "script-editor.scpt") as alias
			set sutScript to load script (deploymentPath & scriptName & ".scpt") as alias
			set tempFile to POSIX path of (path to temporary items from user domain) & "/Test.applescript"
		end try
		assertInstanceOf(script, sutScript)
	end script
end script


script |createTempDocument and writeDataToTempDocument Set|
	property parent : TestSet(me)
	on setUp()
		TopLevel's __launchApp()
	end setUp
	on tearDown()
		TopLevel's __terminateApp()
	end tearDown

	script |Window is created|
		property parent : UnitTest(me)
		set base to sutBaseScript's new()
		set sut to sutScript's decorate(base)
		sut's createTempDocument("unit")
		tell application "Script Editor"
			set windowNames to name of windows -- Log History is implicitly created.
		end tell
		assertEqual(3, count of windowNames)
		ok(windowNames contains "Test.applescript")
		ok(windowNames contains "Log History")
		ok(windowNames contains "unit")
	end script

	script |Window is created + Text Written to the Document|
		property parent : UnitTest(me)
		set base to sutBaseScript's new()
		set sut to sutScript's decorate(base)
		sut's createTempDocument("unit")
		sut's writeDataToTempDocument("Test Code")
		assertEqual("Test Code", TopLevel's __getTempDocumentContent())
	end script
end script


on __launchApp()
	-- activate application "Script Editor"
	do shell script "touch " & tempFile & " && open -a 'Script Editor' " & tempFile
	delay 1
end __launchApp


on __terminateApp()
	tell application "Script Editor" to quit
	do shell script "rm " & tempFile
end __terminateApp


on __getTempDocumentContent()
	tell application "Script Editor"
		contents of selection of document "unit"
	end tell
end __getTempDocumentContent

