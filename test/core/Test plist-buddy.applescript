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
	@Last Modified: September 3, 2023 10:29 AM
*)
use AppleScript
use scripting additions

use listUtil : script "list"

property parent : script "com.lifepillar/ASUnit"
property xmlUtil : missing value
---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "plist-buddy" -- The name of the script to be tested
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use loggerFactory : script "logger-factory"
use xmlUtilLib : script "core/test/xml-util"

property logger : missing value

property TopLevel : me
property suite : makeTestSuite(suitename)
property plist : "plist-buddy-test"

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
script |Load script|
	property parent : TestSet(me)
	script |Loading the script|
		property parent : UnitTest(me)
		try
			tell application "Finder"
				set deploymentPath to ((path to library folder from user domain) as text) & "Script Libraries:"
			end tell
			
			set sutScript to load script (deploymentPath & scriptName & ".scpt") as alias
			set TopLevel's xmlUtil to xmlUtilLib's newPlist(plist)
		end try
		assertInstanceOf(script, sutScript)
	end script
end script
 

script |getRootKeys tests|
	property parent : TestSet(me)
	property executedTestCases : 0
    property totalTestCases : 5
	property sut : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
		set sut to sutScript's new(plist) 
	end setUp
	on tearDown() 
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		xmlUtil's __createTestPlist()
	end beforeClass
	on afterClass()
		xmlUtil's __deleteTestPlist()
	end afterClass
	
	script |Empty|
		property parent : UnitTest(me)
		assertEqual({}, sut's getRootKeys())
	end script	

	script |Single|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("string", "string", "string-value") 
		assertEqual({"string"}, sut's getRootKeys())
		xmlUtil's __deleteValue("string")
	end script	

	script |Single - With Nested|
		property parent : UnitTest(me)
		xmlUtil's __insertXml("string", "<dict>
			<key>Nested</key>
			<integer>1</integer>
		</dict>")
		assertEqual({"string"}, sut's getRootKeys())
		xmlUtil's __deleteValue("string")
	end script	

	script |Single - Colonized|
		set caseKey to "_04 - Cycle: Terminal and Console"
		xmlUtil's __insertXml(caseKey, "<dict>
		<key>Subroutine</key>
		<string>keyboardmaestro://m=Subroutine%3A%20Cycle%20Apps</string>
	</dict>")
		assertEqual({caseKey}, sut's getRootKeys())
		xmlUtil's __deleteValue(caseKey)
	end script

	script |Variety|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("spaced key", "bool", "false")
		xmlUtil's __writeValue("dotted\\.key", "bool", "false")
		xmlUtil's __writeQuotedValue("/\\\\.6{3,}7?/", "string", "regex key")
		xmlUtil's __insertXml("nested-root", "<dict>
			<key>nested key</key>
			<integer>1</integer>
		</dict>")
		assertEqual({"/\\.6{3,}7?/", "dotted.key", "nested-root",  "spaced key"}, listUtil's simpleSort(sut's getRootKeys()))
		xmlUtil's __deleteValue("spaced key")
		xmlUtil's __deleteValue("dotted.key")
		xmlUtil's __deleteValue("/\\.6{3,}7?/")
		xmlUtil's __deleteValue("nested-root")
	end script
end script

script |getKeys tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 5
	property sut : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
		set sut to sutScript's new(plist) 
	end setUp
	on tearDown() 
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		xmlUtil's __createTestPlist()
	end beforeClass
	on afterClass()
		xmlUtil's __deleteTestPlist()
	end afterClass
	
	script |Empty|
		property parent : UnitTest(me)
		assertEqual({}, sut's getKeys())
	end script	

	script |Single|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("string", "string", "string-value")
		assertEqual({"string"}, sut's getKeys())
		xmlUtil's __deleteValue("string")
	end script	

	script |Single - With Nested|
		property parent : UnitTest(me)
		xmlUtil's __insertXml("string", "<dict>
			<key>Nested</key>
			<integer>1</integer>
		</dict>")
		assertEqual({"string", "Nested"}, sut's getKeys())
		xmlUtil's __deleteValue("string")
	end script	

	script |Single - Colonized|
		set caseKey to "04 - Cycle: Terminal and Console"
		xmlUtil's __insertXml(caseKey, "<dict>
		<key>Subroutine</key>
		<string>keyboardmaestro://m=Subroutine%3A%20Cycle%20Apps</string>
	</dict>")
		assertEqual({caseKey}, sut's getKeys())
		xmlUtil's __deleteValue(caseKey)
	end script

	script |Variety|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("spaced key", "bool", "false")
		xmlUtil's __writeValue("dotted\\.key", "bool", "false")
		xmlUtil's __writeQuotedValue("/\\\\.6{3,}7?/", "string", "regex key")
		xmlUtil's __insertXml("nested", "<dict>
			<key>nested key</key>
			<integer>1</integer>
		</dict>")
		assertEqual({"/\\.6{3,}7?/", "dotted.key", "nested", "nested key",  "spaced key"}, listUtil's simpleSort(sut's getKeys()))
		xmlUtil's __deleteValue("spaced key")
		xmlUtil's __deleteValue("dotted.key")
		xmlUtil's __deleteValue("/\\.6{3,}7?/")
		xmlUtil's __deleteValue("nested")
	end script
end script


script |getDictionaryKeys tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 4
	property sut : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
		set sut to sutScript's new(plist) 
	end setUp
	on tearDown() 
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		xmlUtil's __createTestPlist()
	end beforeClass
	on afterClass()
		xmlUtil's __deleteTestPlist()
	end afterClass
	
	script |Empty|
		property parent : UnitTest(me)
		assertEqual({}, sut's getDictionaryKeys("string"))
	end script	

	script |Single|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("string", "string", "string-value")
		assertEqual({}, sut's getDictionaryKeys("string"))
		xmlUtil's __deleteValue("string")
	end script	

	script |Single - With Nested|
		property parent : UnitTest(me)
		xmlUtil's __insertXml("string", "<dict>
			<key>Nested</key>
			<integer>1</integer>
		</dict>")
		assertEqual({"Nested"}, sut's getDictionaryKeys("string"))
		xmlUtil's __deleteValue("string")
	end script	

	script |Single - Colonized|
		property parent : UnitTest(me)
		set caseKey to "04 - Cycle: Terminal and Console"
		xmlUtil's __insertXml("_" & caseKey, "<dict>
		<key>Subroutine</key>
		<string>km://m=Subroutine%3A%20Cycle%20Apps</string>
	</dict>")
		assertEqual({"Subroutine"}, sut's getDictionaryKeys(caseKey))

		xmlUtil's __deleteValue(caseKey)
	end script
end script


script |hasValue tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 5
	property sut : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
		set sut to sutScript's new(plist) 
	end setUp
	on tearDown() 
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		xmlUtil's __createTestPlist()
	end beforeClass
	on afterClass()
		xmlUtil's __deleteTestPlist()
	end afterClass

	script |Missing value parameter|
		property parent : UnitTest(me)
		notOk(sut's hasValue(missing value))
	end script

	script |Not Found|
		property parent : UnitTest(me)
		xmlUtil's __deleteValue("Unicorn")
		notOk(sut's hasValue("Unicorn"))
	end script

	script |Found|
		property parent : UnitTest(me) 
		xmlUtil's __writeValue("Horse", "string", "'Little Pony'")
		ok(sut's hasValue("Horse"))
		xmlUtil's __deleteValue("Horse")
	end script

	script |Not Found - Nested|
		property parent : UnitTest(me)
		xmlUtil's __insertXml("Animals", "<dict>
			<key>Horse</key>
			<integer>1</integer>
		</dict>")
		notOk(sut's hasValue({"Animals", "Unicorn"}))
		xmlUtil's __deleteValue("Animals")
	end script

	script |Found - Nested|
		property parent : UnitTest(me)
		xmlUtil's __insertXml("Animals", "<dict>
			<key>Horse</key>
			<integer>1</integer>
		</dict>")
		ok(sut's hasValue({"Animals", "Horse"}))
		xmlUtil's __deleteValue("Animals")
	end script
end script


script |getValue tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 6
	property sut : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
		set sut to sutScript's new(plist) 
	end setUp
	on tearDown() 
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		xmlUtil's __createTestPlist()
	end beforeClass
	on afterClass()
		xmlUtil's __deleteTestPlist()
	end afterClass

	script |Missing value parameter|
		property parent : UnitTest(me)
		assertMissing(sut's getValue(missing value))
	end script

	script |Not Found|
		property parent : UnitTest(me)
		xmlUtil's __deleteValue("Unicorn")
		assertMissing(sut's getValue("Unicorn"))
	end script

	script |Found|
		property parent : UnitTest(me) 
		xmlUtil's __writeValue("Horse", "string", "'Little Pony'")
		assertEqual("Little Pony", sut's getValue("Horse"))
		xmlUtil's __deleteValue("Horse")
	end script

	script |Found - Regex Key|
		property parent : UnitTest(me) 
		xmlUtil's __writeValue("/aP\\b/", "string", "'Some Value'")
		assertEqual("Some Value", sut's getValue("/aP\\b/"))
		xmlUtil's __deleteValue("Horse")
	end script

	script |Nested - Not Found|
		property parent : UnitTest(me)
		xmlUtil's __insertXml("Animals", "<dict>
			<key>Horse</key>
			<integer>1</integer>
		</dict>")
		assertMissing(sut's getValue({"Animals", "Unicorn"}))
		xmlUtil's __deleteValue("Animals")
	end script

	script |Nested - Found|
		property parent : UnitTest(me)
		xmlUtil's __insertXml("Animals", "<dict>
			<key>Horse</key>
			<integer>1</integer>
		</dict>")
		assertEqual("1", sut's getValue({"Animals", "Horse"}))
		xmlUtil's __deleteValue("Animals")
	end script
end script


script |getElementType tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 5
	property sut : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
		set sut to sutScript's new(plist) 
	end setUp
	on tearDown() 
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		xmlUtil's __createTestPlist()
	end beforeClass
	on afterClass()
		xmlUtil's __deleteTestPlist()
	end afterClass
	
	script |Missing value parameter|
		property parent : UnitTest(me)
		xmlUtil's __deleteValue("none")
		assertMissing(sut's getElementType("none"))
	end script

	script |Not found|
		property parent : UnitTest(me)
		xmlUtil's __deleteValue("none")
		assertMissing(sut's getElementType("none"))
	end script

	script |Dictionary|
		property parent : UnitTest(me)
		xmlUtil's __insertXml("dictionary", "<dict>
			<key>Nested</key>
			<integer>1</integer>
		</dict>")
		assertEqual("dictionary", sut's getElementType("dictionary"))
		xmlUtil's __deleteValue("dictionary")
	end script

	script |Array|
		property parent : UnitTest(me)
		xmlUtil's __insertXml("array", "<array>
			<true/>
			<false/>
		</array>")
		assertEqual("array", sut's getElementType("array"))
		xmlUtil's __deleteValue("array")
	end script

	script |Scalar|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("boolean", "bool", true)
		assertEqual("string", sut's getElementType("boolean"))
		xmlUtil's __deleteValue("boolean")
	end script
end script


script |keyExists tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 6
	property sut : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
		set sut to sutScript's new(plist) 
	end setUp
	on tearDown() 
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass() 
		xmlUtil's __createTestPlist()
	end beforeClass
	on afterClass()
		-- xmlUtil's __deleteTestPlist()
	end afterClass
	
	script |Missing value parameter|
		property parent : UnitTest(me)
		notOk(sut's keyExists(missing value))
	end script

	script |Not Found|
		property parent : UnitTest(me)
		xmlUtil's __deleteValue("none")
		notOk(sut's keyExists("none"))
	end script

	script |Found|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("present", "string", "string-value")
		ok(sut's keyExists("present"))
		xmlUtil's __deleteValue("present")
	end script

	script |Found - Dotted Key|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("dotted\\.key", "string", "string-value")
		ok(sut's keyExists("dotted.key"))
		xmlUtil's __deleteValue("dotted.key")
	end script

	script |Nested Key - Not Found|
		property parent : UnitTest(me)
		xmlUtil's __insertXml("nested-root", "<dict>
			<key>nested-key</key>
			<integer>1</integer>
		</dict>")
		notOk(sut's keyExists({"nested-root", "unicorn"}))
		xmlUtil's __deleteValue("nested-root")
	end script

	script |Nested Key - Found|
		property parent : UnitTest(me)
		xmlUtil's __insertXml("nested-root", "<dict>
			<key>nested-key</key>
			<integer>1</integer>
		</dict>")
		ok(sut's keyExists({"nested-root", "nested-key"}))
		xmlUtil's __deleteValue("nested-root")
	end script
end script
