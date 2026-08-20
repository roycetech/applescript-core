(*!
	@header
	@abstract
		ASUnit tests for core/switch.
	@discussion
		Uses a temporary plist so tests do not touch the live switches.plist.

	@charset macintosh
	@Created: September 4, 2023 12:53 PM
	@Last Modified: 2026-08-20 14:03:00
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
use usrLib : script "core/user"

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
			set skipDecoration of sutScript to true
			set TopLevel's xmlUtil to xmlUtilLib's newPlist(plistKey)
		end try
		assertInstanceOf(script, sutScript)
	end script
end script


script |switch.new tests|
	property parent : TestSet(me)

	script |#beforeClass|
		property parent : UnitTest(me)
		xmlUtil's __createTestPlist()
	end script

	script |Missing value|
		property parent : UnitTest(me)
		script Lambda
			sutScript's new(missing value)
		end script
		shouldRaise(sutScript's ERROR_MISSING_SWITCH_NAME, Lambda, "Expected error was not thrown")
	end script

	script |#afterClass|
		property parent : UnitTest(me)
		xmlUtil's __deleteTestPlist()
	end script
end script


script |switch.active tests|
	property parent : TestSet(me)
	property sut : missing value
	property originalPlistName : missing value

	on tearDown()
		xmlUtil's __deleteValue(TopLevel's commonSwitchName)
	end tearDown

	script |#beforeClass|
		property parent : UnitTest(me)
		xmlUtil's __createTestPlist()
		set originalPlistName to switchesPlistName of sutScript
		set switchesPlistName of sutScript to TopLevel's plistKey
	end script

	script |Unregistered switch name|
		property parent : UnitTest(me)
		set sut to sutScript's new("Unicorn")
		notOk(sut's active())
	end script

	script |Empty string value|
		property parent : UnitTest(me)
		xmlUtil's __writeQuotedValue(TopLevel's commonSwitchName, "string", "")
		set sut to sutScript's new(TopLevel's commonSwitchName)
		notOk(sut's active())
	end script

	script |Registered inactive|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", false)
		set sut to sutScript's new(TopLevel's commonSwitchName)
		notOk(sut's active())
	end script

	script |Registered active|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", true)
		set sut to sutScript's new(TopLevel's commonSwitchName)
		ok(sut's active())
	end script

	script |#afterClass|
		property parent : UnitTest(me)
		xmlUtil's __deleteTestPlist()
		set switchesPlistName of sutScript to the originalPlistName
	end script
end script


script |switch.inactive tests|
	property parent : TestSet(me)
	property sut : missing value
	property originalPlistName : missing value

	on tearDown()
		xmlUtil's __deleteValue(TopLevel's commonSwitchName)
	end tearDown

	script |#beforeClass|
		property parent : UnitTest(me)
		xmlUtil's __createTestPlist()
		set originalPlistName to switchesPlistName of sutScript
		set switchesPlistName of sutScript to TopLevel's plistKey
	end script

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
	end script

	script |Registered active|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", true)
		set sut to sutScript's new(TopLevel's commonSwitchName)
		notOk(sut's inactive())
	end script

	script |#afterClass|
		property parent : UnitTest(me)
		xmlUtil's __deleteTestPlist()
		set switchesPlistName of sutScript to the originalPlistName
	end script
end script


script |switch.isActive tests|
	property parent : TestSet(me)
	property sut : missing value
	property originalPlistName : missing value

	on tearDown()
		xmlUtil's __deleteValue(TopLevel's commonSwitchName)
	end tearDown

	script |#beforeClass|
		property parent : UnitTest(me)
		xmlUtil's __createTestPlist()
		set originalPlistName to switchesPlistName of sutScript
		set switchesPlistName of sutScript to TopLevel's plistKey
	end script

	script |Registered inactive|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", false)
		set sut to sutScript's new(TopLevel's commonSwitchName)
		notOk(sut's isActive())
	end script

	script |Registered active|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", true)
		set sut to sutScript's new(TopLevel's commonSwitchName)
		ok(sut's isActive())
	end script

	script |#afterClass|
		property parent : UnitTest(me)
		xmlUtil's __deleteTestPlist()
		set switchesPlistName of sutScript to the originalPlistName
	end script
end script


script |switch.isInactive tests|
	property parent : TestSet(me)
	property sut : missing value
	property originalPlistName : missing value

	on tearDown()
		xmlUtil's __deleteValue(TopLevel's commonSwitchName)
	end tearDown

	script |#beforeClass|
		property parent : UnitTest(me)
		xmlUtil's __createTestPlist()
		set originalPlistName to switchesPlistName of sutScript
		set switchesPlistName of sutScript to TopLevel's plistKey
	end script

	script |Registered inactive|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", false)
		set sut to sutScript's new(TopLevel's commonSwitchName)
		ok(sut's isInactive())
	end script

	script |Registered active|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", true)
		set sut to sutScript's new(TopLevel's commonSwitchName)
		notOk(sut's isInactive())
	end script

	script |#afterClass|
		property parent : UnitTest(me)
		xmlUtil's __deleteTestPlist()
		set switchesPlistName of sutScript to the originalPlistName
	end script
end script


script |switch.turnOn tests|
	property parent : TestSet(me)
	property sut : missing value
	property originalPlistName : missing value

	on tearDown()
		xmlUtil's __deleteValue(TopLevel's commonSwitchName)
	end tearDown

	script |#beforeClass|
		property parent : UnitTest(me)
		xmlUtil's __createTestPlist()
		set originalPlistName to switchesPlistName of sutScript
		set switchesPlistName of sutScript to TopLevel's plistKey
	end script

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

	script |#afterClass|
		property parent : UnitTest(me)
		xmlUtil's __deleteTestPlist()
		set switchesPlistName of sutScript to the originalPlistName
	end script
end script


script |switch.turnOff tests|
	property parent : TestSet(me)
	property sut : missing value
	property originalPlistName : missing value

	on tearDown()
		xmlUtil's __deleteValue(TopLevel's commonSwitchName)
	end tearDown

	script |#beforeClass|
		property parent : UnitTest(me)
		xmlUtil's __createTestPlist()
		set originalPlistName to switchesPlistName of sutScript
		set switchesPlistName of sutScript to TopLevel's plistKey
	end script

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

	script |#afterClass|
		property parent : UnitTest(me)
		xmlUtil's __deleteTestPlist()
		set switchesPlistName of sutScript to the originalPlistName
	end script
end script


script |switch.toggle tests|
	property parent : TestSet(me)
	property sut : missing value
	property originalPlistName : missing value

	on tearDown()
		xmlUtil's __deleteValue(TopLevel's commonSwitchName)
	end tearDown

	script |#beforeClass|
		property parent : UnitTest(me)
		xmlUtil's __createTestPlist()
		set originalPlistName to switchesPlistName of sutScript
		set switchesPlistName of sutScript to TopLevel's plistKey
	end script

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

	script |#afterClass|
		property parent : UnitTest(me)
		xmlUtil's __deleteTestPlist()
		set switchesPlistName of sutScript to the originalPlistName
	end script
end script


script |switch.setValue tests|
	property parent : TestSet(me)
	property sut : missing value
	property originalPlistName : missing value

	on tearDown()
		xmlUtil's __deleteValue(TopLevel's commonSwitchName)
	end tearDown

	script |#beforeClass|
		property parent : UnitTest(me)
		xmlUtil's __createTestPlist()
		set originalPlistName to switchesPlistName of sutScript
		set switchesPlistName of sutScript to TopLevel's plistKey
	end script

	script |Set true|
		property parent : UnitTest(me)
		set sut to sutScript's new(TopLevel's commonSwitchName)
		sut's setValue(true)
		assertEqual("<true/>", xmlUtil's __grepValueXml(TopLevel's commonSwitchName))
	end script

	script |Set false|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", true)
		set sut to sutScript's new(TopLevel's commonSwitchName)
		sut's setValue(false)
		assertEqual("<false/>", xmlUtil's __grepValueXml(TopLevel's commonSwitchName))
	end script

	script |#afterClass|
		property parent : UnitTest(me)
		xmlUtil's __deleteTestPlist()
		set switchesPlistName of sutScript to the originalPlistName
	end script
end script


script |Switch static.active tests|
	property parent : TestSet(me)
	property originalPlistName : missing value

	on tearDown()
		xmlUtil's __deleteValue(TopLevel's commonSwitchName)
	end tearDown

	script |#beforeClass|
		property parent : UnitTest(me)
		xmlUtil's __createTestPlist()
		set originalPlistName to switchesPlistName of sutScript
		set switchesPlistName of sutScript to TopLevel's plistKey
	end script

	script |Unregistered switch name|
		property parent : UnitTest(me)
		notOk(sutScript's active("Unicorn"))
	end script

	script |Registered inactive|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", false)
		notOk(sutScript's active(TopLevel's commonSwitchName))
	end script

	script |Registered active|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", true)
		ok(sutScript's active(TopLevel's commonSwitchName))
	end script

	script |#afterClass|
		property parent : UnitTest(me)
		xmlUtil's __deleteTestPlist()
		set switchesPlistName of sutScript to the originalPlistName
	end script
end script


script |Switch static.inactive tests|
	property parent : TestSet(me)
	property originalPlistName : missing value

	on tearDown()
		xmlUtil's __deleteValue(TopLevel's commonSwitchName)
	end tearDown

	script |#beforeClass|
		property parent : UnitTest(me)
		xmlUtil's __createTestPlist()
		set originalPlistName to switchesPlistName of sutScript
		set switchesPlistName of sutScript to TopLevel's plistKey
	end script

	script |Unregistered switch name|
		property parent : UnitTest(me)
		ok(sutScript's inactive("Unicorn"))
	end script

	script |Registered inactive|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", false)
		ok(sutScript's inactive(TopLevel's commonSwitchName))
	end script

	script |Registered active|
		property parent : UnitTest(me)
		xmlUtil's __writeValue(TopLevel's commonSwitchName, "bool", true)
		notOk(sutScript's inactive(TopLevel's commonSwitchName))
	end script

	script |#afterClass|
		property parent : UnitTest(me)
		xmlUtil's __deleteTestPlist()
		set switchesPlistName of sutScript to the originalPlistName
	end script
end script
