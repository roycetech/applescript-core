(*!
	The subject script needs to be installed first because .applescript files could not be dynamically loaded as compared to .scpt.

	@header
	@abstract
		A template for unit testing.
	@discussion
		Copy this template in the folder containing the script to be tested and customize it as follows:

		1) Provide a description for this test suite and the name of the script to be tested.
		2) Write tests :)

	@charset macintosh

	@Adding New Test Cases:
		You need to manually update the number of max cases each time you change
		the number of test cases.

	@Created: July 18, 2023 2:03 PM
	@Last Modified: 2023-07-24 17:43:34
*)
use AppleScript
use scripting additions

property parent : script "com.lifepillar/ASUnit"

---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "plutil" -- The name of the script to be tested
property plist : "plutil-test"

global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use xmlUtilLib : script "core/test/xml-util"
use usrLib : script "core/user"

property logger : missing value
property xmlUtil : missing value

property TopLevel : me
property suite : makeTestSuite(suitename)

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
		property parent : unitTest(me)

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


script |plutil instantiation tests|
	property parent : TestSet(me)
	property sut : missing value

	on setUp()
		set sut to sutScript's new()
	end setUp

	script |Invalid PList Name|
		property parent : unitTest(me)
		skip("Removed dependency to flaky regex script")
		script InvalidPlistWrapper
			sut's new("unicorn;rm")
		end script
		shouldRaise(sutScript's ERROR_PLIST_PATH_INVALID, InvalidPlistWrapper, "Invalid plist name")
	end script

	script |Valid PList Name|
		property parent : unitTest(me)
		assertEqual(name of sut's new("abc"), "PlutilPlistInstance")
	end script


	script |PList Name with Nesting|
		property parent : unitTest(me)
		assertEqual(name of sut's new("abc/xyz/omg"), "PlutilPlistInstance")
	end script
end script


script |plutil _buildKeyNameFromList tests|
	property parent : TestSet(me)
	property sutLib : missing value
	property sut : missing value

	property executedTestCases : 0

	on beforeClass()
		TopLevel's xmlUtil's __createTestPlist()
	end beforeClass

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()

		set sutLib to sutScript's new()
		set sut to sutLib's new("plutil-test")
	end setUp

	on tearDown()
		if my name is "afterClass" then
			afterClass()
		end if
	end tearDown

	on afterClass()
		TopLevel's xmlUtil's __deleteTestPlist()
	end afterClass

	script |Single|
		property parent : unitTest(me)
		assertEqual("Single", sut's _buildKeyNameFromList({"Single"}))
	end script

	script |Single with Dot|
		property parent : unitTest(me)
		assertEqual("one\\.five", sut's _buildKeyNameFromList({"one.five"}))
	end script

	script |Multiple|
		property parent : unitTest(me)
		assertEqual("one.two", sut's _buildKeyNameFromList({"one", "two"}))
	end script

	script |afterClass|
		property parent : unitTest(me)
		ok(true)
	end script
end script


script |plutil hasValue tests|
	property parent : TestSet(me)
	property sut : missing value

	property executedTestCases : 0

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()

		set sutLib to sutScript's new()
		set sut to sutLib's new("plutil-test")
	end setUp

	on tearDown()
		if my name is "afterClass" then
			afterClass()
		end if
	end tearDown

	on beforeClass()
		TopLevel's xmlUtil's __createTestPlist()
	end beforeClass
	on afterClass()
		TopLevel's xmlUtil's __deleteTestPlist()
	end afterClass

	script |Not Found|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __deleteValue("unicorn")
		notOk(sut's hasValue("unicorn"))
	end script

	script |Found|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __writeValue("found", "bool", true)
		ok(sut's hasValue("found"))
	end script

	script |Nested Key name|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __writeQuotedValue("found\\.yes", "bool", true)
		ok(sut's hasValue("found.yes"))
	end script

	script |afterClass|
		property parent : unitTest(me)
		ok(true)
	end script
end script


script |plutil getValue tests|
	property parent : TestSet(me)
	property sutLib : missing value
	property sut : missing value

	property executedTestCases : 0

	on beforeClass()
		TopLevel's xmlUtil's __createTestPlist()
	end beforeClass

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()

		set sutLib to sutScript's new()
		set sut to sutLib's new("plutil-test")
	end setUp

	on tearDown()
		if my name is "afterClass" then afterClass()
	end tearDown

	on afterClass()
		TopLevel's xmlUtil's __deleteTestPlist()
	end afterClass

	script |Non existing PList|
		property parent : unitTest(me)
		assertMissing(sut's getValue("unicorn"))
	end script

	script |Get non existing element|
		property parent : unitTest(me)
		set caseSut to sutLib's new("unicorn-plist")
		assertMissing(caseSut's getValue("unicorn"))
	end script

	script |Dollar sign in Key Name|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __writeString("$system", "system-value")
		assertEqual("system-value", sut's getValue("$system"))
	end script

	script |Special Characters|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __writeString("string", "special&<>")
		assertEqual("special&<>", sut's getValue("string"))
	end script

	script |Dollar sign in value|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __writeString("string", "$dollars")
		assertEqual("$dollars", sut's getValue("string"))
		TopLevel's xmlUtil's __deleteValue("string")
	end script

	script |Dot in key name|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __writeQuotedValue("string\\.dotted", "string", "string-dotted-value")
		assertEqual("string-dotted-value", sut's getValue("string.dotted"))
		TopLevel's xmlUtil's __deleteValue("string.dotted")
	end script

	script |Get string|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __writeString("string", "string-value")
		assertEqual("string-value", sut's getValue("string"))
		TopLevel's xmlUtil's __deleteValue("string")
	end script

	script |Get Int|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __writeValue("integer", "integer", 1)
		assertEqual(1, sut's getValue("integer"))
		TopLevel's xmlUtil's __deleteValue("integer")
	end script

	script |Get Boolean|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __writeValue("boolean", "bool", true)
		ok(sut's getValue("boolean"))
		TopLevel's xmlUtil's __deleteValue("boolean")
	end script

	script |Get Float|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __writeValue("float", "float", 1.5)
		assertEqual(1.5, sut's getValue("float"))
		TopLevel's xmlUtil's __deleteValue("float")
	end script

	script |Get Date|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __writeValue("date", "date", "2023-07-19T00:01:02Z")
		assertEqual("Wednesday, July 19, 2023 at 8:01:02 AM", sut's getValue("date") as text)
		TopLevel's xmlUtil's __deleteValue("date")
	end script

	script |Get integer array|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("array", "<array><integer>1</integer><integer>2</integer></array>")
		assertEqual({1, 2}, sut's getValue("array"))
		TopLevel's xmlUtil's __deleteValue("array")
	end script

	script |Get string array|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("array", "<array><string>a</string><string>b</string></array>")
		assertEqual({"a", "b"}, sut's getValue("array"))
		TopLevel's xmlUtil's __deleteValue("array")
	end script

	script |Get string array with special characters|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("array", "<array><string>&amp;</string><string>&lt;</string><string>&gt;</string></array>")
		assertEqual({"&", "<", ">"}, sut's getValue("array"))
		TopLevel's xmlUtil's __deleteValue("array")
	end script

	script |Get string array with dollar sign|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("array", "<array><string>$five</string></array>")
		assertEqual({"$five"}, sut's getValue("array"))
		TopLevel's xmlUtil's __deleteValue("array")
	end script

	script |Get empty array|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("array", "<array></array>")
		assertEqual({}, sut's getValue("array"))
		TopLevel's xmlUtil's __deleteValue("array")
	end script

	script |Get Dictionary|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("dictionary", "<dict><key>key1</key><string>first value</string></dict>")
		assertEqual({key1:"first value"}, sut's getValue("dictionary"))
		TopLevel's xmlUtil's __deleteValue("dictionary")
	end script

	script |Get Dictionary, with number starting key|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("_1grand", "<dict><key>key1</key><string>first value</string></dict>")
		assertEqual({key1:"first value"}, sut's getValue("1grand"))
		TopLevel's xmlUtil's __deleteValue("_1grand")
	end script

	script |afterClass|
		property parent : unitTest(me)
		ok(true) -- dummy test to trigger the afterClass
	end script
end script


script |plutil getScalarValue tests|
	property parent : TestSet(me)
	property sut : missing value

	property executedTestCases : 0

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
		set sutLib to sutScript's new()
		set sut to sutLib's new("plutil-test")
	end setUp
	on tearDown()
		if my name is "afterClass" then afterClass()
	end tearDown
	on beforeClass()
		TopLevel's xmlUtil's __createTestPlist()
	end beforeClass
	on afterClass()
		TopLevel's xmlUtil's __deleteTestPlist()
	end afterClass

	script |Get Int|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __writeValue("integer", "integer", 1)
		assertEqual(1, sut's getInt("integer"))
	end script

	script |Get Int - Incorrect Type|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __writeValue("string", "string", "1")
		assertMissing(sut's getInt("string"))
	end script

	script |Get Int - dotted key|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __writeValue("integer\\.dotted", "integer", 2)
		assertEqual(2, sut's getInt("integer.dotted"))
		TopLevel's xmlUtil's __deleteValue("integer.dotted")
	end script

	script |Get Int - Nested key|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("integer-root", "<dict><key>integer-sub</key><integer>3</integer></dict>")
		assertEqual(3, sut's getInt({"integer-root", "integer-sub"}))
		TopLevel's xmlUtil's __deleteValue("integer-root\\.integer-sub")
	end script

	script |Get Real|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __writeValue("real", "float", 1.5)
		assertEqual(1.5, sut's getReal("real"))
		TopLevel's xmlUtil's __deleteValue("real")
	end script

	script |Get Boolean|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __writeValue("boolean", "bool", false)
		assertEqual(false, sut's getBool("boolean"))
		TopLevel's xmlUtil's __deleteValue("boolean")
	end script

	script |Get Date|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __writeValue("date", "date", "2023-07-19T00:01:02Z")
		-- Will likely fail due to localization.
		assertEqual(date "Wednesday, July 19, 2023 at 8:01:02 AM", sut's getDate("date"))
		TopLevel's xmlUtil's __deleteValue("date")
	end script

	script |afterClass|
		property parent : unitTest(me)
		ok(true)
	end script
end script


script |getList set|
	property parent : TestSet(me)
	property sut : missing value

	property executedTestCases : 0

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()

		set sutLib to sutScript's new()
		set sut to sutLib's new("plutil-test")
	end setUp

	on tearDown()
		if my name is "afterClass" then afterClass()
	end tearDown

	on beforeClass()
		TopLevel's xmlUtil's __createTestPlist()
	end beforeClass

	on afterClass()
		TopLevel's xmlUtil's __deleteTestPlist()
	end afterClass


	script |getList - Not Found|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __deleteValue("unicorn-list")
		assertMissing(sut's getList("unicorn-list"))
	end script

	script |getList - Empty List|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("empty-list", "<array/>")
		assertEqual({}, sut's getList("empty-list"))
		TopLevel's xmlUtil's __deleteValue("empty-list")
	end script

	script |getList - Integer List|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("integer-list", "<array><integer>1</integer></array>")
		assertEqual({1}, sut's getList("integer-list"))
		TopLevel's xmlUtil's __deleteValue("integer-list")
	end script

	script |getList - String List|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("string-list", "<array><string>1</string></array>")
		assertEqual({"1"}, sut's getList("string-list"))
		TopLevel's xmlUtil's __deleteValue("string-list")
	end script

	script |getList - Spaced Key|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("spaced list", "<array><string>1</string></array>")
		assertEqual({"1"}, sut's getList("spaced list"))
		TopLevel's xmlUtil's __deleteValue("spaced list")
	end script

	script |getList - Dotted Key|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("dotted\\.getList", "<array><integer>1</integer></array>")
		assertEqual({1}, sut's getList("dotted.getList"))
		TopLevel's xmlUtil's __deleteValue("dotted\\.getList")
	end script

	script |getList - Nested Key|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("array", "
		<dict>
			<key>array-sub</key>
			<array>
				<integer>1</integer>
			</array>
		</dict>")
		assertEqual({1}, sut's getList({"array", "array-sub"}))
		TopLevel's xmlUtil's __deleteValue("array")
	end script

	script |afterClass|
		property parent : unitTest(me)
		ok(true)
	end script
end script


script |plutil getValueWithDefault tests|
	property parent : TestSet(me)
	property sut : missing value

	property executedTestCases : 0

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()

		set sutLib to sutScript's new()
		set sut to sutLib's new("plutil-test")
	end setUp

	on tearDown()
		if my name is "afterClass" then afterClass()
	end tearDown

	on beforeClass()
		TopLevel's xmlUtil's __createTestPlist()
	end beforeClass
	on afterClass()
		TopLevel's xmlUtil's __deleteTestPlist()
	end afterClass

	script |With Value|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __writeValue("with-value", "string", "string-value")
		assertEqual("string-value", sut's getValueWithDefault("with-value", "default"))
		TopLevel's xmlUtil's __deleteValue("with-value")
	end script

	script |Without Value|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __deleteValue("no-value")
		assertEqual("default", sut's getValueWithDefault("no-value", "default"))
	end script

	script |afterClass|
		property parent : unitTest(me)
		ok(true)
	end script
end script


script |plutil appendValue tests|
	property parent : TestSet(me)
	property sut : missing value

	property executedTestCases : 0

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()

		set sutLib to sutScript's new()
		set sut to sutLib's new("plutil-test")
	end setUp

	on tearDown()
		if my name is "afterClass" then afterClass()
	end tearDown

	on beforeClass()
		TopLevel's xmlUtil's __createTestPlist()
	end beforeClass
	on afterClass()
		-- TopLevel's xmlUtil's __deleteTestPlist()
	end afterClass

	script |Non Existing|
		property parent : unitTest(me)
		sut's appendValue("unicorn-list", 1)
		assertEqual(textUtil's multiline("	<array>
		<integer>1</integer>
	</array>"), TopLevel's xmlUtil's __grepMultiLineValueXml("unicorn-list", "array"))
		TopLevel's xmlUtil's __deleteValue("unicorn-list")
	end script

	script |Ignore Missing New Value|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("list", "<array/>")
		sut's appendValue("list", missing value)
		assertEqual("", TopLevel's xmlUtil's __grepValueXml("<array/>"))
		TopLevel's xmlUtil's __deleteValue("list")
	end script

	script |First Element|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("list", "<array/>")
		sut's appendValue("list", true)
		assertEqual(textUtil's multiline("	<array>
		<true/>
	</array>"), TopLevel's xmlUtil's __grepMultiLineValueXml("list", "array"))
		TopLevel's xmlUtil's __deleteValue("list")
	end script

	script |Additional Element|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("list", "<array><real>1.5</real></array>")
		sut's appendValue("list", 2.5)
		assertEqual(textUtil's multiline("	<array>
		<real>1.5</real>
		<real>2.5</real>
	</array>"), TopLevel's xmlUtil's __grepMultiLineValueXml("list", "array"))
		TopLevel's xmlUtil's __deleteValue("list")
	end script

	script |Additional element, different type|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("list", "<array><real>1.5</real></array>")
		sut's appendValue("list", 3)
		assertEqual(textUtil's multiline("	<array>
		<real>1.5</real>
		<integer>3</integer>
	</array>"), TopLevel's xmlUtil's __grepMultiLineValueXml("list", "array"))
		TopLevel's xmlUtil's __deleteValue("list")
	end script

	script |Dotted Key|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("list\\.test", "<array/>")
		sut's appendValue("list.test", 3)
		assertEqual(textUtil's multiline("	<array>
		<integer>3</integer>
	</array>"), TopLevel's xmlUtil's __grepMultiLineValueXml("list.test", "array"))
		TopLevel's xmlUtil's __deleteValue("list\\.test")
	end script

	script |Spaced Key|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("space list", "<array/>")
		sut's appendValue("space list", 3)
		assertEqual(textUtil's multiline("	<array>
		<integer>3</integer>
	</array>"), TopLevel's xmlUtil's __grepMultiLineValueXml("space list", "array"))
		TopLevel's xmlUtil's __deleteValue("space list")
	end script

	script |Nested Key|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("list", "<dict><key>list-sub</key><array/></dict>")
		sut's appendValue({"list", "list-sub"}, 3)
		assertEqual(textUtil's multiline("		<array>
			<integer>3</integer>
		</array>"), TopLevel's xmlUtil's __grepMultiLineValueXml("list-sub", "array"))
		TopLevel's xmlUtil's __deleteValue("list")
	end script

	script |afterClass|
		property parent : unitTest(me)
		ok(true)
	end script
end script


script |plutil removeElement tests|
	property parent : TestSet(me)
	property sut : missing value

	property executedTestCases : 0

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()

		set sutLib to sutScript's new()
		set sut to sutLib's new("plutil-test")
	end setUp

	on tearDown()
		if my name is "afterClass" then afterClass()
	end tearDown


	on beforeClass()
		TopLevel's xmlUtil's __createTestPlist()
	end beforeClass
	on afterClass()
		TopLevel's xmlUtil's __deleteTestPlist()
	end afterClass


	script |Missing Value as element|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("array", "<array/>")
		notOk(sut's removeElement("array", missing value))
		TopLevel's xmlUtil's __deleteValue("array")
	end script

	script |Happy Case|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("array", "<array><string>element</string></array>")
		ok(sut's removeElement("array", "element"))
		TopLevel's xmlUtil's __deleteValue("array")
	end script

	script |Wrong Type|
		property parent : unitTest(me)
		skip("Known Issue, all elements are treated as string.")
		TopLevel's xmlUtil's __insertXml("array", "<array><string>1</string></array>")
		notOk(sut's removeElement("array", 1))
		TopLevel's xmlUtil's __deleteValue("array")
	end script

	script |Nonexistent Array|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("array", "<array><string>element</string></array>")
		notOk(sut's removeElement("array-unicorn", "element"))
		TopLevel's xmlUtil's __deleteValue("array")
	end script

	script |Nonexistent Element|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("array", "<array><string>element</string></array>")
		ok(sut's removeElement("array", "element"))
		TopLevel's xmlUtil's __deleteValue("array")
	end script

	script |Dotted Name|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("array\\.test", "<array><string>element</string></array>")
		ok(sut's removeElement("array.test", "element"))
		TopLevel's xmlUtil's __deleteValue("array\\.test")
	end script

	script |Nested|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("array-main", "
			<dict>
				<key>array-sub</key>
				<array>
					<string>element</string>
				</array>
			</dict>")
		ok(sut's removeElement({"array-main", "array-sub"}, "element"))
		TopLevel's xmlUtil's __deleteValue("array-main")
	end script

	script |afterClass|
		property parent : unitTest(me)
		ok(true)
	end script
end script


script |plutil _getDateText tests|
	property parent : TestSet(me)
	property sut : missing value

	property executedTestCases : 0

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()

		set sutLib to sutScript's new()
		set sut to sutLib's new("plutil-test")
	end setUp

	on tearDown()
		if my name is "afterClass" then afterClass()
	end tearDown

	on beforeClass()
		TopLevel's xmlUtil's __createTestPlist()
	end beforeClass

	on afterClass()
		TopLevel's xmlUtil's __deleteTestPlist()
	end afterClass

	script |Happy Case|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __writeValue("date", "date", "2023-07-19T00:01:02Z")
		assertEqual("2023-07-19T00:01:02Z", sut's _getDateText("date"))
		TopLevel's xmlUtil's __deleteValue("date")
	end script

	script |Nested Date|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("date", "<dict><key>date nest</key><date>2023-07-19T00:01:02Z</date></dict>")
		assertEqual("2023-07-19T00:01:02Z", sut's _getDateText({"date", "date nest"}))
		TopLevel's xmlUtil's __deleteValue("date nest")
	end script

	script |afterClass|
		property parent : unitTest(me)
		ok(true)
	end script
end script

script |plutil setValue tests|
	property parent : TestSet(me)
	property sut : missing value

	property executedTestCases : 0

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()

		set sutLib to sutScript's new()
		set sut to sutLib's new("plutil-test")
	end setUp

	on tearDown()
		if my name is "afterClass" then afterClass()
	end tearDown

	on beforeClass()
		TopLevel's xmlUtil's __createTestPlist()
	end beforeClass

	on afterClass()
		TopLevel's xmlUtil's __deleteTestPlist()
	end afterClass

	script |String Value|
		property parent : unitTest(me)
		sut's setValue("string", "string-value")
		assertEqual("string-value", TopLevel's xmlUtil's __readValue("string"))
	end script

	script |Integer Value|
		property parent : unitTest(me)
		sut's setValue("integer", 1)
		assertEqual("<integer>1</integer>", TopLevel's xmlUtil's __grepValueXml("integer"))
	end script

	script |Float Value|
		property parent : unitTest(me)
		sut's setValue("float", 1.5)
		assertEqual("<real>1.5</real>", TopLevel's xmlUtil's __grepValueXml("float"))
	end script

	script |Boolean Value|
		property parent : unitTest(me)
		sut's setValue("Boolean", true)
		assertEqual("<true/>", TopLevel's xmlUtil's __grepValueXml("Boolean"))
	end script

	script |Date Value|
		property parent : unitTest(me)
		set testDate to "7-31-2023" -- Will likely fail for different region due to localization.
		sut's setValue("Date", date testDate)
		assertEqual("<date>2023-07-31T04:00:00Z</date>", TopLevel's xmlUtil's __grepValueXml("Date"))
	end script

	script |Integer Array Values|
		property parent : unitTest(me)
		sut's setValue("Array", {1, 2, 3})
		assertEqual(textUtil's multiline("	<array>
		<integer>1</integer>
		<integer>2</integer>
		<integer>3</integer>
	</array>"), TopLevel's xmlUtil's __grepMultiLineValueXml("Array", "array"))
	end script

	script |String Array Values|
		property parent : unitTest(me)
		sut's setValue("Array", {"a", "b", "$Dollar and c & d"})
		assertEqual(textUtil's multiline("	<array>
		<string>a</string>
		<string>b</string>
		<string>\\$Dollar and c &amp; d</string>
	</array>"), TopLevel's xmlUtil's __grepMultiLineValueXml("Array", "array"))
	end script

	script |Record Value|
		property parent : unitTest(me)
		sut's setValue("Record", {one:"half"})
		assertEqual(textUtil's multiline("	<dict>
		<key>one</key>
		<string>half</string>
	</dict>"), TopLevel's xmlUtil's __grepMultiLineValueXml("Record", "dict"))
	end script

	script |Key starts with a number|
		property parent : unitTest(me)
		sut's setValue("1Password 6", 6)
		assertEqual("6", TopLevel's xmlUtil's __readValue("_1Password 6"))
	end script

	script |Key starts with a number, saving a record|
		property parent : unitTest(me)
		-- sut's setValue("1Password 6", {nested_key: "value"})
		sut's setValue("02-Concurrency", {nested_key:"value"})
		assertEqual(textUtil's multiline("	<dict>
		<key>nested_key</key>
		<string>value</string>
	</dict>"), TopLevel's xmlUtil's __grepMultiLineValueXml("_02-Concurrency", "dict"))
	end script

	script |Update Value Type|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __writeString("string", "original")
		sut's setValue("string", true)
		assertEqual("<true/>", TopLevel's xmlUtil's __grepValueXml("string"))
	end script

	script |Dotted Key|
		property parent : unitTest(me)
		sut's setValue("string.com", "string-value")
		assertEqual("string-value", TopLevel's xmlUtil's __readValue("string\\.com"))
	end script

	script |Nested Key|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __insertXml("string-root", "<dict/>")
		sut's setValue({"string-root", "string-sub"}, "string-value")
		assertEqual("string-value", TopLevel's xmlUtil's __readValue("string-root.string-sub"))
	end script

	script |Spaced Key|
		property parent : unitTest(me)
		sut's setValue("string spaced", "string-value")
		assertEqual("string-value", TopLevel's xmlUtil's __readValue("string spaced"))
	end script

	script |afterClass|
		property parent : unitTest(me)
		ok(true)
	end script
end script

script |plutil delete tests set|
	property parent : TestSet(me)
	property sut : missing value

	property beforeClassExecuted : false
	property executedTestCases : 0

	(* Each Test. *)
	on setUp()
		if not beforeClassExecuted then beforeClass()
		set executedTestCases to executedTestCases + 1

		set sutLib to sutScript's new()
		set sut to sutLib's new("plutil-test")
	end setUp

	on beforeClass()
		TopLevel's xmlUtil's __createTestPlist()
	end beforeClass

	on tearDown()
		TopLevel's xmlUtil's __deleteValue("key-root")
		if my name is "afterClass" then afterClass()
	end tearDown

	on afterClass()
		TopLevel's xmlUtil's __deleteTestPlist()
	end afterClass


	script |Delete Nonexistent Key|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __deleteValue("Unicorn")
		notOk(sut's deleteKey("Unicorn"))
	end script

	script |Delete Missing Value Parameter|
		property parent : unitTest(me)
		notOk(sut's deleteKey(missing value))
	end script

	script |Invalid Parameter Type|
		property parent : unitTest(me)
		notOk(sut's deleteKey(1234))
	end script

	script |Delete with Dotted Key Name|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __writeString("key\\.com", "some value")
		ok(sut's deleteKey("key.com"))
		assertMissing(TopLevel's xmlUtil's __readValue("key.com"))
	end script


	script |Delete Value|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __writeString("string", "some value")
		ok(sut's deleteKey("string"))
		assertMissing(TopLevel's xmlUtil's __readValue("string"))
	end script


	script |Delete Nested Parameter|
		property parent : unitTest(me)
		TopLevel's xmlUtil's __writeQuotedValue("key-root", "xml", "<dict></dict>")
		TopLevel's xmlUtil's __writeQuotedValue("key-root.key-nested", "string", "nested value")
		ok(sut's deleteKey({"key-root", "key-nested"}))
		assertMissing(TopLevel's xmlUtil's __readValue("key-root.key-nested", "raw"))
		refuteMissing(TopLevel's xmlUtil's __readValue("key-root", "raw"))
		TopLevel's xmlUtil's __deleteValue("key-root")
	end script

	script |afterClass|
		property parent : unitTest(me)
		ok(true)
	end script
end script


---------------------------------------------------------------------------------------
-- Shared Private Handler Tests
---------------------------------------------------------------------------------------
script |_getTypedGetterShellTemplate|
	property parent : TestSet(me)
	property sut : missing value
	property executedTestCases : 0

	on setUp()
		set sutLib to sutScript's new()
		set sut to sutLib's new("plutil-test")
	end setUp
	on tearDown()
	end tearDown

	script |Key Name - Text|
		property parent : unitTest(me)
		set actual to sut's _getTypedGetterShellTemplate("string", "unit")
		ok(actual contains "if [[ \"unit\" == *\".\"* ]]; then TMP=$(echo \"unit\" | sed 's/\\./\\\\./g');")
		ok(actual contains "plutil -extract \"$TMP\" raw -expect string ")
		ok(actual contains ".plist';")
		ok(actual ends with "fi")
	end script

	script |Key Name - List|
		property parent : unitTest(me)
		set actual to sut's _getTypedGetterShellTemplate("string", {"unit", "test"})
		ok(actual does not contain "else plutil")
		ok(actual contains "plutil -extract 'unit.test' raw -expect string")
		ok(actual ends with ".plist'")
	end script
end script


script |plutil _validatePlistKey tests|
	property parent : TestSet(me)
	property sut : missing value
	property executedTestCases : 0

	on setUp()
		set sutLib to sutScript's new()
		set sut to sutLib's new("plutil-test")
	end setUp

	script |Missing Key|
		property parent : unitTest(me)
		script Lambda
			sut's _validatePlistKey(missing value)
		end script
		shouldRaise(sutScript's ERROR_PLIST_KEY_MISSING_VALUE, Lambda, "Missing value for key but no error raised")
	end script

	script |Empty Key|
		property parent : unitTest(me)
		script Lambda
			sut's _validatePlistKey(" ")
		end script
		shouldRaise(sutScript's ERROR_PLIST_KEY_EMPTY, Lambda, "Empty key but no error raised")
	end script

	script |Invalid Key Type|
		property parent : unitTest(me)
		script Lambda
			sut's _validatePlistKey(1234)
		end script
		shouldRaise(sutScript's ERROR_PLIST_KEY_INVALID_TYPE, Lambda, "Invalid key type but no error raised")
	end script
end script
