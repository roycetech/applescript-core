(*!
	@header
	@abstract
		A template for unit testing.
	@discussion
		Copy this template in the folder containing the script to be tested and customize it as follows:
	
		1) Provide a description for this test suite and the name of the script to be tested.
		2) Write tests :)

	@charset macintosh
	@Created: September 4, 2023 2:02 PM
*)
use AppleScript
use scripting additions

property parent : script "com.lifepillar/ASUnit"
property xmlUtil : missing value

---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "property-list" -- The name of the script to be tested
property commonKeyName : "unit-test-plist-key"
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use textUtil : script "core/string"
use usrLib : script "core/user"
use xmlUtilLib : script "core/test/xml-util"
 
property TopLevel : me
property suite : makeTestSuite(suitename)
property plistKey : "plist-test"

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
script |Load script - property-list|
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
			set xmlUtil to xmlUtilLib's newPlist(plistKey)
		end try
		assertInstanceOf(script, sutScript)
	end script
end script


script |property-list.new tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 2

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
	end setUp
	on tearDown()
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		TopLevel's xmlUtil's __createTestPlist()
	end beforeClass
	on afterClass()
		TopLevel's xmlUtil's __deleteTestPlist()
	end afterClass
	
	script |Plist not found|
		property parent : UnitTest(me)
		script Lambda
			sutScript's new("Unicorn")
		end script
		shouldRaise(sutScript's ERROR_PLIST_NOT_FOUND, Lambda, "Expected error was not thrown")
	end script

	script |Plist found|
		property parent : UnitTest(me)
		set sut to sutScript's new(TopLevel's plistKey)
		assertInstanceOf(script, sut)
		assertEqual("PListClassicInstance", name of sut)
	end script
end script


script |property-list.setValue tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 10
	property sut : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
		set sut to sutScript's new(TopLevel's plistKey)
	end setUp
	on tearDown()
		TopLevel's xmlUtil's __deleteValue(TopLevel's commonKeyName)
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		TopLevel's xmlUtil's __createTestPlist()
	end beforeClass
	on afterClass()
		TopLevel's xmlUtil's __deleteTestPlist()
	end afterClass
	
	script |String|
		property parent : UnitTest(me)
		sut's setValue(TopLevel's commonKeyName, "string-value")
		assertEqual("<string>string-value</string>", TopLevel's xmlUtil's __grepValueXml(TopLevel's commonKeyName))
	end script

	script |String - Update to another type|
		property parent : UnitTest(me)
		TopLevel's xmlUtil's __writeValue(TopLevel's commonKeyName, "string", "string-existing")
		sut's setValue(TopLevel's commonKeyName, true)
		assertEqual("<true/>", TopLevel's xmlUtil's __grepValueXml(TopLevel's commonKeyName))
	end script

	script |Int|
		property parent : UnitTest(me)
		sut's setValue(TopLevel's commonKeyName, 1)
		assertEqual("<integer>1</integer>", TopLevel's xmlUtil's __grepValueXml(TopLevel's commonKeyName))
	end script

	script |Float|
		property parent : UnitTest(me)
		sut's setValue(TopLevel's commonKeyName, 1.5)
		assertEqual("<real>1.5</real>", TopLevel's xmlUtil's __grepValueXml(TopLevel's commonKeyName))
	end script

	script |Boolean|
		property parent : UnitTest(me)
		sut's setValue(TopLevel's commonKeyName, false)
		assertEqual("<false/>", TopLevel's xmlUtil's __grepValueXml(TopLevel's commonKeyName))
	end script

	script |Date|
		property parent : UnitTest(me)
		sut's setValue(TopLevel's commonKeyName, current date)
		ok(TopLevel's xmlUtil's __grepValueXml(TopLevel's commonKeyName) starts with "<date>")
	end script

	script |Array|
		property parent : UnitTest(me)
		sut's setValue(TopLevel's commonKeyName, {1, "text"})
		assertEqual("<array><integer>1</integer><string>text</string></array>", textUtil's replace(TopLevel's xmlUtil's __grepValueXml(TopLevel's commonKeyName), " ", ""))
	end script

	script |Array - Empty|
		property parent : UnitTest(me)
		sut's setValue(TopLevel's commonKeyName, {})
		assertEqual("<array/>", TopLevel's xmlUtil's __grepValueXml(TopLevel's commonKeyName))
	end script

	script |Record|
		property parent : UnitTest(me)
		sut's setValue(TopLevel's commonKeyName, {a: 1})
		assertEqual("<dict><key>a</key><integer>1</integer></dict>", textUtil's replace(TopLevel's xmlUtil's __grepValueXml(TopLevel's commonKeyName), " ", ""))
	end script

	script |Number Key| 
		property parent : UnitTest(me)
		sut's setValue(1, 2)
		assertEqual("<integer>2</integer>", TopLevel's xmlUtil's __grepValueXml(1))
		TopLevel's xmlUtil's __deleteValue(1)
	end script
end script


script |property-list.getValue tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 8
	property sut : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
		set sut to sutScript's new(TopLevel's plistKey)
	end setUp
	on tearDown()
		TopLevel's xmlUtil's __deleteValue(TopLevel's commonKeyName)
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		TopLevel's xmlUtil's __createTestPlist()
	end beforeClass
	on afterClass()
		TopLevel's xmlUtil's __deleteTestPlist()
	end afterClass
	
	script |String|
		property parent : UnitTest(me)
		TopLevel's xmlUtil's __writeValue(TopLevel's commonKeyName, "string", "string-value")
		assertEqual("string-value", sut's getValue(TopLevel's commonKeyName))
	end script

	script |Int|
		property parent : UnitTest(me)
		TopLevel's xmlUtil's __writeValue(TopLevel's commonKeyName, "integer", 1)
		assertEqual(1, sut's getValue(TopLevel's commonKeyName))
	end script 

	script |Float|
		property parent : UnitTest(me)
		TopLevel's xmlUtil's __writeValue(TopLevel's commonKeyName, "float", 1.5)
		assertEqual(1.5, sut's getValue(TopLevel's commonKeyName))
	end script

	script |Boolean|
		property parent : UnitTest(me)
		TopLevel's xmlUtil's __writeValue(TopLevel's commonKeyName, "bool", true)
		ok(sut's getValue(TopLevel's commonKeyName))
	end script

	script |Array|
		property parent : UnitTest(me)
		TopLevel's xmlUtil's __insertXml(TopLevel's commonKeyName, "<array><integer>1</integer><string>text</string></array>")
		assertEqual({1, "text"}, sut's getValue(TopLevel's commonKeyName))
	end script

	script |Empty Array|
		property parent : UnitTest(me)
		TopLevel's xmlUtil's __insertXml(TopLevel's commonKeyName, "<array/>")
		assertEqual({}, sut's getValue(TopLevel's commonKeyName))
	end script

	script |Record|
		property parent : UnitTest(me)
		TopLevel's xmlUtil's __insertXml(TopLevel's commonKeyName, "<dict><key>a</key><integer>1</integer></dict>")		
		assertEqual({a: 1}, sut's getValue(TopLevel's commonKeyName))
	end script

	script |Number Key| 
		property parent : UnitTest(me)
		-- TopLevel's xmlUtil's __writeValue(1, "integer", 2) -- Breaks because plutil can't have number as key.
		sut's setValue(1, 2)
		assertEqual(2, sut's getValue(1))
		TopLevel's xmlUtil's __deleteValue(1)
	end script
end script


script |property-list.hasValue tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 2
	property sut : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
		set sut to sutScript's new(TopLevel's plistKey)
	end setUp
	on tearDown()
		TopLevel's xmlUtil's __deleteValue(TopLevel's commonKeyName)
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		TopLevel's xmlUtil's __createTestPlist()
	end beforeClass
	on afterClass()
		TopLevel's xmlUtil's __deleteTestPlist()
	end afterClass
	
	script |Not found|
		property parent : UnitTest(me)
		notOk(sut's hasValue("Unicorn"))
	end script

	script |Found|
		property parent : UnitTest(me)
		TopLevel's xmlUtil's __writeValue(TopLevel's commonKeyName, "string", "string-value")
		ok(sut's hasValue(TopLevel's commonKeyName))
	end script
end script


script |property-list.appendElement tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 2
	property sut : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
		set sut to sutScript's new(TopLevel's plistKey)
	end setUp
	on tearDown()
		TopLevel's xmlUtil's __deleteValue(TopLevel's commonKeyName)
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		TopLevel's xmlUtil's __createTestPlist()
	end beforeClass
	on afterClass()
		TopLevel's xmlUtil's __deleteTestPlist()
	end afterClass
	
	script |Empty array|
		property parent : UnitTest(me)
		sut's appendElement(TopLevel's commonKeyName, "first-element")
		assertEqual("<array><string>first-element</string></array>", textUtil's replace(TopLevel's xmlUtil's __grepValueXml(TopLevel's commonKeyName), " ", ""))
	end script

	script |Non-empty array|
		property parent : UnitTest(me)
		TopLevel's xmlUtil's __insertXml(TopLevel's commonKeyName, "<array><string>first-element</string></array>")
		sut's appendElement(TopLevel's commonKeyName, 2)
		assertEqual("<array><string>first-element</string><integer>2</integer></array>", textUtil's replace(TopLevel's xmlUtil's __grepValueXml(TopLevel's commonKeyName), " ", ""))
	end script
end script


script |property-list.deleteKey tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 3
	property sut : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
		set sut to sutScript's new(TopLevel's plistKey)
	end setUp
	on tearDown()
		TopLevel's xmlUtil's __deleteValue(TopLevel's commonKeyName)
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		TopLevel's xmlUtil's __createTestPlist()
	end beforeClass
	on afterClass()
		TopLevel's xmlUtil's __deleteTestPlist()
	end afterClass
	
	script |Not found|
		property parent : UnitTest(me)
		notOk(sut's deleteKey(TopLevel's commonKeyName))
	end script

	script |Found - scalar|
		property parent : UnitTest(me)
		TopLevel's xmlUtil's __writeValue(TopLevel's commonKeyName, "string", "for-deletion")
		assertEqual("<string>for-deletion</string>", TopLevel's xmlUtil's __grepValueXml(TopLevel's commonKeyName))
		ok(sut's deleteKey(TopLevel's commonKeyName))
		refuteEqual("<string>for-deletion</string>", TopLevel's xmlUtil's __grepValueXml(TopLevel's commonKeyName))
	end script

	script |Found - composite|
		property parent : UnitTest(me)
		TopLevel's xmlUtil's __insertXml(TopLevel's commonKeyName, "<array/>")
		assertEqual("<array/>", TopLevel's xmlUtil's __grepValueXml(TopLevel's commonKeyName))
		ok(sut's deleteKey(TopLevel's commonKeyName))
		refuteEqual("<array/>", TopLevel's xmlUtil's __grepValueXml(TopLevel's commonKeyName))
	end script
end script


script |property-list.plistExists tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 2
	property sut : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
		set sut to sutScript's new(TopLevel's plistKey)
	end setUp
	on tearDown()
		TopLevel's xmlUtil's __deleteValue(TopLevel's commonKeyName)
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		TopLevel's xmlUtil's __createTestPlist()
	end beforeClass
	on afterClass()
		TopLevel's xmlUtil's __deleteTestPlist()
	end afterClass
	
	script |Not found|
		property parent : UnitTest(me)
		notOk(sutScript's plistExists("Unicorn"))
	end script

	script |Found|
		property parent : UnitTest(me)
		ok(sutScript's plistExists(TopLevel's plistKey))
	end script
end script


script |property-list.createNewPlist tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 2
	property sut : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
		set sut to sutScript's new(TopLevel's plistKey)
	end setUp
	on tearDown()
		TopLevel's xmlUtil's __deleteValue(TopLevel's commonKeyName)
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		TopLevel's xmlUtil's __createTestPlist()
	end beforeClass
	on afterClass()
		TopLevel's xmlUtil's __deleteTestPlist()
	end afterClass
	
	script |Found|
		property parent : UnitTest(me)
		script Lambda
			sutScript's createNewPList(TopLevel's plistKey)
		end script
		shouldRaise(sutScript's ERROR_PLIST_CREATE_ALREADY_EXISTS, Lambda, "Expected error was not raised")
	end script 

	script |Not found|
		property parent : UnitTest(me)
		TopLevel's xmlUtil's __deleteTestPlist()
		ok(sutScript's createNewPList(TopLevel's plistKey))
	end script
end script