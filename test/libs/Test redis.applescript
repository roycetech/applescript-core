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
*)
use AppleScript
use scripting additions
use textUtil : script "core/string"

property parent : script "com.lifepillar/ASUnit"

---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "redis" -- The name of the script to be tested
property commonKey : "unit-test"
property redisCli : missing value
global sutScript -- The variable holding the script to be tested
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
			
			set sutScript to load script (deploymentPath & scriptName & ".scpt") as alias
			set redisCli to sutScript's REDIS_CLI
		end try
		assertInstanceOf(script, sutScript)
	end script
end script


script |setValue tests|
	property parent : TestSet(me)
	
	on setUp()
	end setUp
	on tearDown()
		TopLevel's __deleteValue(TopLevel's commonKey)
	end tearDown
	
	script |key is missing value|
		property parent : UnitTest(me)
		set sut to sutScript's new(0)
		try
			sut's setValue(missing value, 1)
		on error
			fail("Error is not expected")
		end try
	end script

	script |Setting to a is missing value erases existing value|
		property parent : UnitTest(me)
		set sut to sutScript's new(0)
		TopLevel's __writeValue(TopLevel's commonKey, "initial")
		sut's setValue(TopLevel's commonKey, missing value)
		assertEqual("", TopLevel's __readValue(TopLevel's commonKey))
		assertEqual("none", TopLevel's __readType(TopLevel's commonKey))
	end script

	script |String value|
		property parent : UnitTest(me)
		set sut to sutScript's new(0)
		sut's setValue(TopLevel's commonKey, "string-value")
		assertEqual("string-value", TopLevel's __readValue(TopLevel's commonKey))
		assertEqual("string", TopLevel's __readType(TopLevel's commonKey))
	end script

	script |Multi-word key|
		property parent : UnitTest(me)
		set sut to sutScript's new(0)
		sut's setValue("multi word", "string-value")
		assertEqual("string-value", TopLevel's __readValue("multi word"))
		assertEqual("string", TopLevel's __readType("multi word"))
		TopLevel's __deleteValue("multi word")
	end script

	script |String value, dotted key|
		property parent : UnitTest(me)
		set sut to sutScript's new(0)
		sut's setValue("string.com", "string-value")
		assertEqual("string-value", TopLevel's __readValue("string.com"))
		assertEqual("string", TopLevel's __readType("string.com"))
	end script

	script |Integer value|
		property parent : UnitTest(me)
		set sut to sutScript's new(0)
		sut's setValue(TopLevel's commonKey, 1)
		assertEqual("1", TopLevel's __readValue(TopLevel's commonKey))
		assertEqual("string", TopLevel's __readType(TopLevel's commonKey))
	end script

	script |Float value|
		property parent : UnitTest(me)
		set sut to sutScript's new(0)
		sut's setValue(TopLevel's commonKey, 1.5)
		assertEqual("1.5", TopLevel's __readValue(TopLevel's commonKey))
		assertEqual("string", TopLevel's __readType(TopLevel's commonKey))
	end script

	script |Boolean false|
		property parent : UnitTest(me)
		set sut to sutScript's new(0)
		sut's setValue(TopLevel's commonKey, false)
		assertEqual("false", TopLevel's __readValue(TopLevel's commonKey))
		assertEqual("string", TopLevel's __readType(TopLevel's commonKey))
	end script

	script |Boolean true|
		property parent : UnitTest(me)
		set sut to sutScript's new(0)
		sut's setValue(TopLevel's commonKey, true)
		assertEqual("true", TopLevel's __readValue(TopLevel's commonKey))
		assertEqual("string", TopLevel's __readType(TopLevel's commonKey))
	end script

	script |Array|
		property parent : UnitTest(me)
		set sut to sutScript's new(0)
		sut's setValue(TopLevel's commonKey, {1, 2, 3})
		assertEqual("list", TopLevel's __readType(TopLevel's commonKey))
		assertEqual(textUtil's multiline("1
2
3"), TopLevel's __readListValue(TopLevel's commonKey))
	end script

	script |Array - Empty|
		property parent : UnitTest(me)
		set sut to sutScript's new(0)
		sut's setValue(TopLevel's commonKey, {})
		assertEqual("none", TopLevel's __readType(TopLevel's commonKey))
	end script

	script |Record|
		property parent : UnitTest(me)
		property sut : missing value
		set sut to sutScript's new(0)
		script Lambda
			sut's setValue(TopLevel's commonKey, {a: 1, b: 2})
		end script
		shouldRaise(sutScript's ERROR_UNSUPPORTED_TYPE, Lambda, "Expected unsupported error was not raised")
	end script

	script |Updating an existing element type|
		property parent : UnitTest(me)
		property sut : missing value
		set sut to sutScript's new(0)
		TopLevel's __writeValue(TopLevel's commonKey, true)
		sut's setValue(TopLevel's commonKey, 123)
		assertEqual("123", TopLevel's __readValue(TopLevel's commonKey))
	end script
end script


script |hasValue tests|
	property parent : TestSet(me)
	property sut : missing value
	on setUp()
		set sut to sutScript's new(0)
	end setUp
	on tearDown()
		TopLevel's __deleteValue(TopLevel's commonKey)
	end tearDown
	
	script |key is missing value|
		property parent : UnitTest(me)
		notOk(sut's hasValue(missing value))
	end script

	script |Existing element|
		property parent : UnitTest(me)
		TopLevel's __writeValue(TopLevel's commonKey, "any")
		ok(sut's hasValue(TopLevel's commonKey))
	end script

	script |Non-existing element|
		property parent : UnitTest(me)
		notOk(sut's hasValue("Unicorn"))
	end script
end script


script |getValue tests|
	property parent : TestSet(me)
	property sut : missing value
	on setUp()
		set sut to sutScript's new(0)
	end setUp
	on tearDown()
		TopLevel's __deleteValue(TopLevel's commonKey)
	end tearDown
	
	script |key is missing value|
		property parent : UnitTest(me)
		assertMissing(sut's getValue(missing value))
	end script

	script |Value Type: String|
		property parent : UnitTest(me)
		TopLevel's __writeValue(TopLevel's commonKey, "string-value")
		assertEqual("string-value", sut's getValue(TopLevel's commonKey))
	end script

	script |Value not found|
		property parent : UnitTest(me)
		assertMissing(sut's getValue("Unicorn"))
	end script

	script |Multi-word key|
		property parent : UnitTest(me)
		TopLevel's __writeValue("one two", "string-value")
		assertEqual("string-value", sut's getValue("one two"))
	end script

	script |Dotted key|
		property parent : UnitTest(me)
		TopLevel's __writeValue("one.two", "string-value")
		assertEqual("string-value", sut's getValue("one.two"))
	end script

	script |Value Type: Integer|
		property parent : UnitTest(me)
		TopLevel's __writeValue(TopLevel's commonKey, 1234)
		assertEqual("1234", sut's getValue(TopLevel's commonKey))
	end script

	script |Value Type: Float|
		property parent : UnitTest(me)
		TopLevel's __writeValue(TopLevel's commonKey, 12.34)
		assertEqual("12.34", sut's getValue(TopLevel's commonKey))
	end script

	script |Value Type: Boolean|
		property parent : UnitTest(me)
		TopLevel's __writeValue(TopLevel's commonKey, true)
		assertEqual("true", sut's getValue(TopLevel's commonKey))
	end script

	script |Value Type: Array|
		property parent : UnitTest(me)
		TopLevel's __writeList(TopLevel's commonKey, {1, 2, 3})
		assertEqual({"1", "2", "3"}, sut's getValue(TopLevel's commonKey))
	end script
end script


script |getValueWithDefault tests|
	property parent : TestSet(me)
	property sut : missing value
	on setUp()
		set sut to sutScript's new(0)
	end setUp
	on tearDown()
		TopLevel's __deleteValue(TopLevel's commonKey)
	end tearDown
	
	script |key is missing value|
		property parent : UnitTest(me)
		assertEqual("default", sut's getValueWithDefault(missing value, "default"))
	end script

	script |Existing value|
		property parent : UnitTest(me)
		TopLevel's __writeValue(TopLevel's commonKey, "existing")
		assertEqual("existing", sut's getValueWithDefault(TopLevel's commonKey, "default"))
	end script

	script |Not existing value|
		property parent : UnitTest(me)
		assertEqual("default", sut's getValueWithDefault(TopLevel's commonKey, "default"))
	end script
end script


script |getBool tests|
	property parent : TestSet(me)
	property sut : missing value
	on setUp()
		set sut to sutScript's new(0)
	end setUp
	on tearDown()
		TopLevel's __deleteValue(TopLevel's commonKey)
	end tearDown
	
	script |key is missing value|
		property parent : UnitTest(me)
		notOk(sut's getBool(missing value))
	end script

	script |Value is "True"|
		property parent : UnitTest(me)
		TopLevel's __writeValue(TopLevel's commonKey, "'True'")
		ok(sut's getBool(TopLevel's commonKey))
	end script

	script |Value is "true"|
		property parent : UnitTest(me)
		TopLevel's __writeValue(TopLevel's commonKey, "'true'")
		ok(sut's getBool(TopLevel's commonKey))
	end script

	script |Value is "TRUE"|
		property parent : UnitTest(me)
		TopLevel's __writeValue(TopLevel's commonKey, "'TRUE'")
		ok(sut's getBool(TopLevel's commonKey))
	end script

	script |Value is "rain"|
		property parent : UnitTest(me)
		TopLevel's __writeValue(TopLevel's commonKey, "'rain'")
		notOk(sut's getBool(TopLevel's commonKey))
	end script
end script


script |getInt tests|
	property parent : TestSet(me)
	property sut : missing value
	on setUp()
		set sut to sutScript's new(0)
	end setUp
	on tearDown()
		TopLevel's __deleteValue(TopLevel's commonKey)
	end tearDown
	
	script |key is missing value|
		property parent : UnitTest(me)
		assertMissing(sut's getInt(missing value))
	end script

	script |Basic|
		property parent : UnitTest(me)
		TopLevel's __writeValue(TopLevel's commonKey, "1234")
		assertEqual(1234, sut's getInt(TopLevel's commonKey))
	end script
end script

script |getReal tests|
	property parent : TestSet(me)
	property sut : missing value
	on setUp()
		set sut to sutScript's new(0)
	end setUp
	on tearDown()
		TopLevel's __deleteValue(TopLevel's commonKey)
	end tearDown
	
	script |key is missing value|
		property parent : UnitTest(me)
		assertMissing(sut's getReal(missing value))
	end script

	script |Basic|
		property parent : UnitTest(me)
		TopLevel's __writeValue(TopLevel's commonKey, 1.5)
		assertEqual(1.5, sut's getReal(TopLevel's commonKey))
	end script
end script


script |getList tests|
	property parent : TestSet(me)
	property sut : missing value
	on setUp()
		set sut to sutScript's new(0)
	end setUp
	on tearDown()
		TopLevel's __deleteValue(TopLevel's commonKey)
	end tearDown
	
	script |key is missing value|
		property parent : UnitTest(me)
		assertMissing(sut's getList(missing value))
	end script

	script |Array|
		property parent : UnitTest(me)
		set sut to sutScript's new(0)
		sut's setValue(TopLevel's commonKey, {1, 2, 3})
		assertEqual({"1", "2", "3"}, sut's getList(TopLevel's commonKey))
	end script
end script


script |appendElement tests|
	property parent : TestSet(me)
	property sut : missing value
	on setUp()
		set sut to sutScript's new(0)
	end setUp
	on tearDown()
		TopLevel's __deleteValue(TopLevel's commonKey)
	end tearDown
	
	script |key is missing value|
		property parent : UnitTest(me)
		script Lambda
			sut's appendElement(missing value, 1234)
		end script
		shouldRaise(sutScript's ERROR_KEY_IS_MISSING, Lambda, "Expected error was not raised")
	end script

	script |value is missing value|
		property parent : UnitTest(me)
		script Lambda
			sut's appendElement(TopLevel's commonKey, missing value)
		end script
		shouldRaise(sutScript's ERROR_VALUE_IS_MISSING, Lambda, "Expected error was not raised")
	end script

	script |First element|
		property parent : UnitTest(me)
		sut's appendElement(TopLevel's commonKey, "first-value")
		assertEqual("first-value", TopLevel's __readListValue(TopLevel's commonKey))
	end script

	script |Second element|
		property parent : UnitTest(me)
		TopLevel's __writeList(TopLevel's commonKey, {"first-value"})
		sut's appendElement(TopLevel's commonKey, "second-value")
		assertEqual(textUtil's multiline("first-value
second-value"), TopLevel's __readListValue(TopLevel's commonKey))
	end script
end script


script |removeElement tests|
	property parent : TestSet(me)
	property sut : missing value
	on setUp()
		set sut to sutScript's new(0)
	end setUp
	on tearDown()
		TopLevel's __deleteValue(TopLevel's commonKey)
	end tearDown
	
	script |key is missing value|
		property parent : UnitTest(me)

		script Lambda
			sut's removeElement(missing value, 1234, 1)
		end script
		shouldRaise(sutScript's ERROR_KEY_IS_MISSING, Lambda, "Expected key missing error was not thrown")
	end script

	script |value is missing value|
		property parent : UnitTest(me)
		script Lambda
			sut's removeElement(TopLevel's commonKey, missing value, 1)
		end script
		shouldRaise(sutScript's ERROR_VALUE_IS_MISSING, Lambda, "Expected value missing error was not thrown")		
	end script

	script |value is not found|
		property parent : UnitTest(me)
		TopLevel's __writeList(TopLevel's commonKey, {"one", "two", "three"})
		assertEqual(0, sut's removeElement(TopLevel's commonKey, "unicorn", 1))
	end script

	script |value is found once|
		property parent : UnitTest(me)
		TopLevel's __writeList(TopLevel's commonKey, {"one", "two", "three"})
		assertEqual(1, sut's removeElement(TopLevel's commonKey, "one", 1))
		assertEqual(textUtil's multiline("two
three"), TopLevel's __readListValue(TopLevel's commonKey))
	end script

	script |value is found multiple times|
		property parent : UnitTest(me)
		TopLevel's __writeList(TopLevel's commonKey, {"one", "two", "three", "two", "two"})
		assertEqual(2, sut's removeElement(TopLevel's commonKey, "two", 2))
		assertEqual(textUtil's multiline("one
three
two"), TopLevel's __readListValue(TopLevel's commonKey))
	end script

	script |Remove all|
		property parent : UnitTest(me)
		TopLevel's __writeList(TopLevel's commonKey, {"one", "two", "three", "two", "two"})
		assertEqual(3, sut's removeElement(TopLevel's commonKey, "two", 0))
		assertEqual(textUtil's multiline("one
three"), TopLevel's __readListValue(TopLevel's commonKey))
	end script

	script |Remove from end|
		property parent : UnitTest(me)
		TopLevel's __writeList(TopLevel's commonKey, {"one", "two", "three", "two", "two"})
		assertEqual(2, sut's removeElement(TopLevel's commonKey, "two", -2))
		assertEqual(textUtil's multiline("one
two
three"), TopLevel's __readListValue(TopLevel's commonKey))
	end script
end script


script |deleteKey tests|
	property parent : TestSet(me)
	property sut : missing value
	on setUp()
		set sut to sutScript's new(0)
	end setUp
	on tearDown()
		TopLevel's __deleteValue(TopLevel's commonKey)
	end tearDown
	
	script |key is missing value|
		property parent : UnitTest(me)

		script Lambda
			sut's deleteKey(missing value)
		end script
		shouldRaise(sutScript's ERROR_KEY_IS_MISSING, Lambda, "Expected key missing error was not thrown")
	end script

	script |Key not found|
		property parent : UnitTest(me)
		notOk(sut's deleteKey("Unicorn"))
	end script

	script |Key found - String|
		property parent : UnitTest(me)
		TopLevel's __writeValue(TopLevel's commonKey, "initial")
		ok(sut's deleteKey(TopLevel's commonKey))
	end script

	script |Key found - List|
		property parent : UnitTest(me)
		TopLevel's __writeList(TopLevel's commonKey, {"one", "two", "three"})
		ok(sut's deleteKey(TopLevel's commonKey))
	end script
end script


script |Expiration tests|
	property parent : TestSet(me)
	property sut : missing value
	on setUp()
		set sut to sutScript's new(1)
	end setUp
	on tearDown()
		TopLevel's __deleteValue(TopLevel's commonKey)
	end tearDown
	
	script |Scalar|
		property parent : UnitTest(me)

		sut's setValue(TopLevel's commonKey, 1234)
		assertEqual("1234", TopLevel's __readValue(TopLevel's commonKey))
		delay 1
		assertEqual("", TopLevel's __readValue(TopLevel's commonKey))
	end script

	script |Array|
		property parent : UnitTest(me)

		sut's setValue(TopLevel's commonKey, {1, 2})
		assertEqual(textUtil's multiline("1
2"), TopLevel's __readListValue(TopLevel's commonKey))
		delay 1
		assertEqual("", TopLevel's __readListValue(TopLevel's commonKey))
	end script
end script


on __readValue(key)
	do shell script redisCli & " GET '" & key & "'" 
end __readValue

on __readListValue(key)
	do shell script redisCli & " LRANGE '" & key & "' 0 -1"
end __readValue

on __readType(key)
	do shell script redisCli & " TYPE '" & key & "'" 
end __readValue

on __writeValue(key, valueParam)
	set command to redisCli & " SET '" & key & "' " & valueParam & " EX 60" 
	do shell script command
end __readValue

on __writeList(key, listData)
	repeat with nextElement in listData
		do shell script redisCli & " RPUSH '" & key & "' " & nextElement
	end repeat
	do shell script redisCli & " EXPIRE '" & key & "' 60"
end __readValue

on __deleteValue(key)
	do shell script redisCli & " DEL '" & key & "'" 
end __readValue
