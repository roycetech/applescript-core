(*!
	@header
	@abstract
		A template for unit testing.
	@discussion
		Copy this template in the folder containing the script to be tested and customize it as follows:

		1) Provide a description for this test suite and the name of the script to be tested.
		2) Write tests :)

	@charset macintosh
	@Created: September 4, 2023 12:53 PM
*)
use AppleScript
use scripting additions

property parent : script "com.lifepillar/ASUnit"
property xmlUtil : missing value

---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "switch" -- The name of the script to be tested
property commonSwitchName : "unit-test-switch-name"
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use xmlUtilLib : script "core/test/xml-util"

property TopLevel : me
property suite : makeTestSuite(suitename)
property plistKey : "switch-test"

set xmlUtil to xmlUtilLib's newPlist(plistKey)
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
			set TopLevel's xmlUtil to xmlUtilLib's newPlist(plistKey)
		end try
		assertInstanceOf(script, sutScript)
	end script
end script


script |switch.active tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 4
	property sut : missing value
	property originalPlistName : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
	end setUp
	on tearDown()
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		xmlUtil's __createTestPlist()
		set originalPlistName to switchesPlistName of sutScript
	end beforeClass
	on afterClass()
		xmlUtil's __deleteTestPlist()
		set switchesPlistName of sutScript to the originalPlistName
	end afterClass

	script |Missing value|
		property parent : UnitTest(me)
		script Lambda
			set sut to sutScript's new(missing value)
		end script
		shouldRaise(sutScript's ERROR_MISSING_SWITCH_NAME, Lambda, "Expected error was not thrown")
	end script

	script |Unregistered switch name|
		property parent : UnitTest(me)
		set sut to sutScript's new("Unicorn")
		notOk(sut's active())
	end script

	script |Registered inactive|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", false)
		set sut to sutScript's new(TopLevel's commonSwitchName)
		notOk(sut's active())
		xmlUtil's __deleteValue(TopLevel's commonSwitchName)
	end script

	script |Registered active|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", true)

		set switchesPlistName of sutScript to TopLevel's plistKey
		set sut to sutScript's new(TopLevel's commonSwitchName)
		ok(sut's active())
		xmlUtil's __deleteValue(TopLevel's commonSwitchName)
	end script
end script


script |switch.inactive tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 4
	property sut : missing value
	property originalPlistName : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
	end setUp
	on tearDown()
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		xmlUtil's __createTestPlist()
		set originalPlistName to switchesPlistName of sutScript
	end beforeClass
	on afterClass()
		xmlUtil's __deleteTestPlist()
		set switchesPlistName of sutScript to the originalPlistName
	end afterClass

	script |Unregistered switch name|
		property parent : UnitTest(me)
		set sut to sutScript's new("Unicorn")
		ok(sut's inactive())
	end script

	script |Registered inactive|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", false)
		set sut to sutScript's new(TopLevel's commonSwitchName)
		ok(sut's inactive())
		xmlUtil's __deleteValue(TopLevel's commonSwitchName)
	end script

	script |Registered active|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", true)

		set switchesPlistName of sutScript to TopLevel's plistKey
		set sut to sutScript's new(TopLevel's commonSwitchName)
		notOk(sut's inactive())
		xmlUtil's __deleteValue(TopLevel's commonSwitchName)
	end script
end script


script |switch.turnOn tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 3
	property sut : missing value
	property originalPlistName : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
	end setUp
	on tearDown()
		xmlUtil's __deleteValue(TopLevel's commonSwitchName)
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		xmlUtil's __createTestPlist()
		set originalPlistName to switchesPlistName of sutScript
	end beforeClass
	on afterClass()
		xmlUtil's __deleteTestPlist()
		set switchesPlistName of sutScript to the originalPlistName
	end afterClass

	script |Unregistered switch name|
		property parent : UnitTest(me)
		set sut to sutScript's new(TopLevel's commonSwitchName)
		sut's turnOn()
		assertEqual("<true/>", xmlUtil's __grepValueXml(TopLevel's commonSwitchName))
	end script

	script |Registered inactive|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", false)
		set sut to sutScript's new(TopLevel's commonSwitchName)
		sut's turnOn()
		assertEqual("<true/>", xmlUtil's __grepValueXml(TopLevel's commonSwitchName))
	end script

	script |Registered already active|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", true)
		set sut to sutScript's new(TopLevel's commonSwitchName)
		sut's turnOn()
		assertEqual("<true/>", xmlUtil's __grepValueXml(TopLevel's commonSwitchName))
	end script
end script


script |switch.turnOff tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 3
	property sut : missing value
	property originalPlistName : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
	end setUp
	on tearDown()
		xmlUtil's __deleteValue(TopLevel's commonSwitchName)
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		xmlUtil's __createTestPlist()
		set originalPlistName to switchesPlistName of sutScript
	end beforeClass
	on afterClass()
		xmlUtil's __deleteTestPlist()
		set switchesPlistName of sutScript to the originalPlistName
	end afterClass

	script |Unregistered switch name|
		property parent : UnitTest(me)
		set sut to sutScript's new(TopLevel's commonSwitchName)
		sut's turnOff()
		assertEqual("<false/>", xmlUtil's __grepValueXml(TopLevel's commonSwitchName))
	end script

	script |Registered inactive|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", false)
		set sut to sutScript's new(TopLevel's commonSwitchName)
		sut's turnOff()
		assertEqual("<false/>", xmlUtil's __grepValueXml(TopLevel's commonSwitchName))
	end script

	script |Registered already active|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", true)
		set sut to sutScript's new(TopLevel's commonSwitchName)
		sut's turnOff()
		assertEqual("<false/>", xmlUtil's __grepValueXml(TopLevel's commonSwitchName))
	end script
end script


script |switch.toggle tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 3
	property sut : missing value
	property originalPlistName : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
	end setUp
	on tearDown()
		xmlUtil's __deleteValue(TopLevel's commonSwitchName)
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		xmlUtil's __createTestPlist()
		set originalPlistName to switchesPlistName of sutScript
	end beforeClass
	on afterClass()
		xmlUtil's __deleteTestPlist()
		set switchesPlistName of sutScript to the originalPlistName
	end afterClass

	script |Unregistered switch name|
		property parent : UnitTest(me)
		set sut to sutScript's new(TopLevel's commonSwitchName)
		sut's toggle()
		assertEqual("<true/>", xmlUtil's __grepValueXml(TopLevel's commonSwitchName))
	end script

	script |Registered inactive|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", false)
		set sut to sutScript's new(TopLevel's commonSwitchName)
		sut's toggle()
		assertEqual("<true/>", xmlUtil's __grepValueXml(TopLevel's commonSwitchName))
	end script

	script |Registered already active|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", true)
		set sut to sutScript's new(TopLevel's commonSwitchName)
		sut's toggle()
		assertEqual("<false/>", xmlUtil's __grepValueXml(TopLevel's commonSwitchName))
	end script
end script


script |Switch static.active tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 3
	property sut : missing value
	property originalPlistName : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
	end setUp
	on tearDown()
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		xmlUtil's __createTestPlist()
		set originalPlistName to switchesPlistName of sutScript
	end beforeClass
	on afterClass()
		xmlUtil's __deleteTestPlist()
		set switchesPlistName of sutScript to the originalPlistName
	end afterClass

	script |Unregistered switch name|
		property parent : UnitTest(me)
		notOk(sutScript's active("Unicorn"))
	end script

	script |Registered inactive|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", false)
		notOk(sutScript's active(TopLevel's commonSwitchName))
		xmlUtil's __deleteValue(TopLevel's commonSwitchName)
	end script

	script |Registered active|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", true)
		set switchesPlistName of sutScript to TopLevel's plistKey
		ok(sutScript's active(TopLevel's commonSwitchName))
		xmlUtil's __deleteValue(TopLevel's commonSwitchName)
	end script
end script


script |Switch static.inactive tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 3
	property sut : missing value
	property originalPlistName : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
	end setUp
	on tearDown()
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		xmlUtil's __createTestPlist()
		set originalPlistName to switchesPlistName of sutScript
	end beforeClass
	on afterClass()
		xmlUtil's __deleteTestPlist()
		set switchesPlistName of sutScript to the originalPlistName
	end afterClass

	script |Unregistered switch name|
		property parent : UnitTest(me)
		ok(sutScript's inactive("Unicorn"))
	end script

	script |Registered ininactive|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", false)
		ok(sutScript's inactive(TopLevel's commonSwitchName))
		xmlUtil's __deleteValue(TopLevel's commonSwitchName)
	end script

	script |Registered inactive|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", true)
		set switchesPlistName of sutScript to TopLevel's plistKey
		notOk(sutScript's inactive(TopLevel's commonSwitchName))
		xmlUtil's __deleteValue(TopLevel's commonSwitchName)
	end script
end script