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
*)
use AppleScript
use scripting additions

property parent : script "com.lifepillar/ASUnit"

(* For OS X 10.8 and earlier, use this instead:
property parent : load script Â
	(((path to library folder from user domain) as text) Â
		& "Script Libraries:com.lifepillar:ASUnit.scptd") as alias
*)
---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "plutil" -- The name of the script to be tested
property plist : "~/applescript-core/test-plutil.plist"
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

property TopLevel : me
property suite : makeTestSuite(suitename)

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
			
		on error the errorMessage number the errorNumber
			
			-- MyScript must return itself in its run method for this to work.
			set MyScript to run script Â
				((folder of file (path to me) of application "Finder" as text) Â
					& scriptName & ".applescript") as alias
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
		property parent : UnitTest(me)
		
		script InvalidPlistWrapper
			sut's new("unicorn;rm")
		end script
		shouldRaise(1, InvalidPlistWrapper, "Invalid plist name")
	end script
	
	script |Valid PList Name|
		property parent : UnitTest(me)
		
		assertEqual(name of sut's new("abc"), "PlutilPlistInstance")
	end script
	
	
	script |PList Name with Nesting|
		property parent : UnitTest(me)
		
		assertEqual(name of sut's new("abc/xyz/omg"), "PlutilPlistInstance")
	end script
end script





script |plutil getValue tests|
	property parent : TestSet(me)
	property sutLib : missing value
	property sut : missing value
	
	property executedTestCases : 0
	(* Manually Set *)
	property totalTestCases : 19
	
	on beforeClass()
		TopLevel's __createTestPlist()
	end beforeClass
	
	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
		
		set sutLib to sutScript's new()
		set sut to sutLib's new("test-plutil")
	end setUp
	
	on tearDown()
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	
	on afterClass()
		TopLevel's __deleteTestPlist()
	end afterClass
	
	script |Non existing PList|
		property parent : UnitTest(me)
		
		assertMissing(sut's getValue("unicorn"))
	end script
	
	script |Get non existing element|
		property parent : UnitTest(me)
		
		set caseSut to sutLib's new("unicorn-plist")
		assertMissing(caseSut's getValue("unicorn"))
	end script
	
	script |Missing value as parameter|
		property parent : UnitTest(me)
		assertMissing(sut's getValue(missing value))
	end script

	script |Invalid Parameter Type|
		property parent : UnitTest(me)

		assertMissing(sut's getValue(1)) 
	end script

	script |Dollar sign in Key Name|
		property parent : UnitTest(me)
		
		TopLevel's __writeString("$system", "system-value")
		assertEqual("system-value", sut's getValue("$system"))
	end script

	script |Special Characters|
		property parent : UnitTest(me)
		
		TopLevel's __writeString("string", "special&<>")
		assertEqual("special&<>", sut's getValue("string"))
	end script

	script |Dollar sign in value| 
		property parent : UnitTest(me)
		
		TopLevel's __writeString("string", "$dollars")

		assertEqual("$dollars", sut's getValue("string"))

		TopLevel's __deleteValue("string")
	end script

	script |Dot in keyname|
		property parent : UnitTest(me)
		
		do shell script "plutil -replace 'string\\.dotted' -string 'string-dotted-value' " & plist
		delay 0.1 -- improves success of the following statement.
		
		assertEqual("string-dotted-value", sut's getValue("string.dotted"))
		
		TopLevel's __deleteValue("string.dotted")
	end script
	
	script |Get string|
		property parent : UnitTest(me)
		
		TopLevel's __writeString("string", "string-value")

		assertEqual("string-value", sut's getValue("string"))
		
		TopLevel's __deleteValue("string")
	end script
	
	script |Get Int|
		property parent : UnitTest(me)
		
		do shell script "plutil -replace 'integer' -integer 1 " & plist
		delay 0.1 -- improves success of the following statement.
		
		assertEqual(1, sut's getValue("integer"))
		
		TopLevel's __deleteValue("integer")
	end script
	
	script |Get Boolean|
		property parent : UnitTest(me)
		
		do shell script "plutil -replace 'boolean' -bool true " & plist
		delay 0.1 -- improves success of the following statement.
		
		ok(sut's getValue("boolean"))
		
		TopLevel's __deleteValue("boolean")
	end script
	
	
	script |Get Float|
		property parent : UnitTest(me)
		
		do shell script "plutil -replace 'float' -float 1.5 " & plist
		delay 0.1 -- improves success of the following statement.
		
		assertEqual(1.5, sut's getValue("float"))
		
		TopLevel's __deleteValue("float")
	end script
	
	script |Get Date|
		property parent : UnitTest(me)
		
		do shell script "plutil -replace 'date' -date '2023-07-19T00:01:02Z' " & plist
		delay 0.1 -- improves success of the following statement.
		
		assertEqual("Wednesday, July 19, 2023 at 8:01:02 AM", sut's getValue("date") as text)
		
		TopLevel's __deleteValue("date")
	end script
	
	script |Get integer array|
		property parent : UnitTest(me)
		
		do shell script "plutil -insert 'array' -xml '<array><integer>1</integer><integer>2</integer></array>' " & plist
		delay 0.1 -- improves success of the following statement.
		
		assertEqual({1, 2}, sut's getValue("array"))
		
		TopLevel's __deleteValue("array")
	end script

	script |Get string array|
		property parent : UnitTest(me)
		
		do shell script "plutil -insert 'array' -xml '<array><string>a</string><string>b</string></array>' " & plist
		delay 0.1 -- improves success of the following statement.
		
		assertEqual({"a", "b"}, sut's getValue("array"))
		
		TopLevel's __deleteValue("array")
	end script

	script |Get string array with special characters|
		property parent : UnitTest(me)
		
		do shell script "plutil -insert 'array' -xml '<array><string>&amp;</string><string>&lt;</string><string>&gt;</string></array>' " & plist
		delay 0.1 -- improves success of the following statement.
		
		assertEqual({"&", "<", ">"}, sut's getValue("array"))
		
		TopLevel's __deleteValue("array")
	end script

	script |Get string array with dollar sign|
		property parent : UnitTest(me)
		
		do shell script "plutil -insert 'array' -xml '<array><string>$five</string></array>' " & plist
		delay 0.1 -- improves success of the following statement.
		
		assertEqual({"$five"}, sut's getValue("array"))
		
		TopLevel's __deleteValue("array")
	end script
	
	script |Get empty array|
		property parent : UnitTest(me)
		
		do shell script "plutil -insert 'array' -xml '<array></array>' " & plist
		delay 0.1 -- improves success of the following statement.
		
		assertEqual({}, sut's getValue("array"))
		
		TopLevel's __deleteValue("array")
	end script

	script |Get Dictionary|
		property parent : UnitTest(me)
		
		do shell script "plutil -insert 'dictionary' -xml '<dict><key>key1</key><string>first value</string></dict>' " & plist
		delay 0.1 -- improves success of the following statement.
		
		assertEqual({key1:"first value"}, sut's getValue("dictionary"))
		
		TopLevel's __deleteValue("dictionary")
	end script
end script


script |plutil setValue tests|
	property parent : TestSet(me)
	property sut : missing value
	
	property executedTestCases : 0
	(* Manually Set *)
	property totalTestCases : 2
	
	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
		
		set sutLib to sutScript's new()
		set sut to sutLib's new("test-plutil")
	end setUp
	
	on tearDown()
		
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	
	on beforeClass()
		TopLevel's __createTestPlist()
	end beforeClass
	
	on afterClass()
		TopLevel's __deleteTestPlist()
	end afterClass
	
	script |Missing Value as key|
		property parent : UnitTest(me)
		
		sut's setValue(missing value, 1)
		assertEqual("", TopLevel's __readAllKeys())
	end script
	
	script |Set String Value|
		property parent : UnitTest(me)
		
		sut's setValue("string", "string-value")
		assertEqual("string-value", TopLevel's __readValue("string"))
	end script
end script


script |plutil delete tests set|
	property parent : TestSet(me)
	property sut : missing value
	
	property beforeClassExecuted : false
	property executedTestCases : 0
	(* Manually Set *)
	property totalTestCases : 6
	
	(* Each Test. *)
	on setUp()
		if not beforeClassExecuted then beforeClass()
		set executedTestCases to executedTestCases + 1
		
		set sutLib to sutScript's new()
		set sut to sutLib's new("test-plutil")
	end setUp
	
	on beforeClass()
		TopLevel's __createTestPlist()
	end beforeClass
	
	on tearDown()
		TopLevel's __deleteValue("key-root")
		
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	
	
	on afterClass()
		TopLevel's __deleteTestPlist()
	end afterClass
	

	script |Delete Inexistent Key|
		property parent : UnitTest(me)
		
		try
			do shell script "plutil -remove 'Unicorn' " & plist
		end try
		
		notOk(sut's deleteKey("Unicorn"))
	end script
	
	script |Delete Missing Value Parameter|
		property parent : UnitTest(me)
		
		notOk(sut's deleteKey(missing value))
	end script

	script |Invalid Parameter Type|
		property parent : UnitTest(me)
		
		notOk(sut's deleteKey(1234))
	end script

	script |Delete with Dotted Key Name| 
		property parent : UnitTest(me)

		TopLevel's __writeString("key\\.com", "some value")
		
		ok(sut's deleteKey("key.com"))

		assertMissing(TopLevel's __readValue("key.com"))
	end script


	script |Delete Value|
		property parent : UnitTest(me)
		
		TopLevel's __writeString("string", "some value")
		
		ok(sut's deleteKey("string"))

		assertMissing(TopLevel's __readValue("string"))
	end script

	
	script |Delete Nested Parameter|
		property parent : UnitTest(me)
		
		do shell script "plutil -insert 'key-root' -xml '<dict></dict>' " & plist
		do shell script "plutil -replace 'key-root.key-nested' -string 'nested value' " & plist
		
		ok(sut's deleteKey({"key-root", "key-nested"}))
		
		try
			do shell script "plutil -extract 'key-root.key-nested' raw " & plist
			fail()
		end try
		try
			do shell script "plutil -extract 'key-root' raw " & plist
		on error
			fail()
		end try
	end script
end script


---------------------------------------------------------------------------------------
-- Shared Utilities
---------------------------------------------------------------------------------------
on __readAllKeys()
	do shell script "/usr/libexec/PlistBuddy \\
				-c \"Print\" ~/applescript-core/test-plutil.plist \\
			| grep -E '^\\s*[^[:space:]]+\\s*=' \\
			| awk '{print $1}'"
end __readAllKeys


on __readValue(keyName)
	try
		return do shell script "plutil -extract '" & keyName & "' raw " & plist
	end try
	missing value
end __readValue

on __writeString(keyName, newValue)
	__writeValue(keyName, "string", newValue)
end __readValue

on __writeValue(keyName, keyType, newValue)
	try
		do shell script "plutil -replace '" & keyName & "' -" & keyType & " '" & newValue & "' " & plist
	end try
	delay 0.1 -- improves success of the following statement.
end __readValue

on __deleteValue(keyName)
	try
		do shell script "plutil -remove '" & keyName & "' " & plist
	end try
end __deleteValue

on __createTestPlist()
	try
		do shell script "plutil -create xml1 " & plist
	end try
end __createTestPlist

on __deleteTestPlist()
	try
		do shell script "rm " & plist & " || true"
	end try
end __deleteTestPlist
