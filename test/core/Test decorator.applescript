(*!
	@header
	@abstract
		A template for unit testing.
	@discussion
		Copy this template in the folder containing the script to be tested and customize it as follows:
	
		1) Provide a description for this test suite and the name of the script to be tested.
		2) Write tests :)

	@Known Issues:
		August 10, 2023 1:58 PM - It's difficult to have a separate factory for testing because the 
		initialization happens at the time of instantiation. Because of this,
		we'll just back up actual config, and restore it on clean up.

	@charset macintosh
	@Created:
*)
use AppleScript
use scripting additions

use usrLib : script "core/user"

property parent : script "com.lifepillar/ASUnit"
property xmlUtil : missing value
---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "decorator" -- The name of the script to be tested
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use loggerFactory : script "core/logger-factory"
use xmlUtilLib : script "core/test/xml-util"

property logger : missing value

property TopLevel : me
property suite : makeTestSuite(suitename)
property plist : "decorator-test"
property plistPath : "~/applescript-core/config-lib-factory.plist"

loggerFactory's inject(me)
set xmlUtil to xmlUtilLib's newPlist(plist)
autorun(suite)

---------------------------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------------------------

-- Don't change this test case if you are testing an external script
-- in the same folder as this test script! We load the script in a test case, because
-- this will work when all the tests in the current folder are run together using loadTestsFromFolder().
-- Besides, this will make sure that we are using the latest version of the script
-- to be tested even if we do not recompile this test script.
script |Load script - decorator|
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
			set xmlUtil to xmlUtilLib's newPlist(plist)
		end try
		assertInstanceOf(script, sutScript)
	end script
end script


script |getHierarchy tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 4
	property originalFactoryXml : missing value
	
	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
		set originalFactoryXml to xmlUtil's __grepValueXml("SublimeTextInstance")
	end setUp
	on tearDown()
		if executedTestCases is equal to the totalTestCases then afterClass()
		TopLevel's xmlUtil's __writeQuotedValue("SublimeTextInstance", "xml", originalFactoryXml)
	end tearDown
	on beforeClass()
	end beforeClass
	on afterClass()
	end afterClass
	
	script |No override|
		property parent : UnitTest(me)
		script Empty
		end script
		set sut to sutScript's new(Empty)
		skip("Different behavior during suite test")
		assertEqual({"ASUnit", "Test decorator", "Empty"}, sut's _getHierarchy())
	end script
	
	script |Integration - No override|
		property parent : UnitTest(me)
		set dialogLib to script "core/dialog"
		set dialog to dialogLib's new()
		set sut to sutScript's new(dialog)
		assertEqual({"dialog", "DialogInstance"}, sut's _getHierarchy())
	end script
	
	script |Integration - Single override|
		property parent : UnitTest(me)
		set systemEventsLib to script "core/system-events"
		set systemEvents to systemEventsLib's new()
		set sut to sutScript's new(systemEvents)
		assertEqual({"system-events", "SystemEventsInstance"}, sut's _getHierarchy())
	end script
	
	script |Integration - Double override|
		property parent : UnitTest(me)
		skip("No public example yet.")
		set systemEventsLib to script "core/sublime-text"
		set systemEvents to systemEventsLib's new()
		set sut to sutScript's new(systemEvents)
		assertEqual({"sublime-text", "SublimeTextInstance", "SublimeTextWindowFocusInstance", "SublimeTextFrontFileToucher"}, sut's _getHierarchy())
	end script
end script
