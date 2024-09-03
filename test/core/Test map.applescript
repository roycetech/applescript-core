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

property parent : script "com.lifepillar/ASUnit"

---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "map" -- The name of the script to be tested
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use loggerFactory : script "core/logger-factory"
use usrLib : script "core/user"

property logger : missing value
property commonKey : "unit-test"
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
		on error the errorMessage number the errorNumber 
			display dialog errorMessage
		end try
		assertInstanceOf(script, sutScript)
	end script
end script


script |map.newFromRecord tests|
	property parent : TestSet(me)
	script |Missing value|
		property parent : UnitTest(me)
		assertMissing(sutScript's newFromRecord(missing value))
	end script

	script |Empty Record|
		property parent : UnitTest(me)
		assertEqual("{}", sutScript's newFromRecord({})'s toString())
	end script

	script |Happy Path|
		property parent : UnitTest(me)
		assertEqual("{a: 1, b: bee}", sutScript's newFromRecord({a: 1, b: "bee"})'s toString())
	end script
end script


script |map.newFromString tests|
	property parent : TestSet(me)
	script |Missing value|
		property parent : UnitTest(me)
		assertMissing(sutScript's newFromString(missing value))
	end script

	script |Empty Text|
		property parent : UnitTest(me)
		assertEqual("{}", sutScript's newFromString("
")'s toString())
	end script

	script |Unrecognized Text|
		property parent : UnitTest(me)
		script Lambda
			sutScript's newFromString("huh?!")
		end script
		shouldRaise(sutScript's ERROR_INVALID_SOURCE_TEXT, Lambda, "Expected error was not thrown")
	end script

	script |Happy Path - skip|
		property parent : UnitTest(me)
		skip("String comparison results in strange comparison.")
		assertEqual("{ts:･TypeScript,･md:･Markdown}", sutScript's newFromString("
			ts: TypeScript
			md: Markdown
		")'s toString())
	end script

	script |Happy Path|
		property parent : UnitTest(me)
		set actual to sutScript's newFromString("
			ts: TypeScript
			md: Markdown
		")
		assertEqual("TypeScript", actual's getValue("ts"))
		assertEqual("Markdown", actual's getValue("md"))
		assertEqual({"ts", "md"}, actual's getKeys())
	end script
end script


script |map.clear|
	property parent : TestSet(me)
	script |Empty Map|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		sut's clear()
		assertEqual("{}", sut's toString())
	end script

	script |Happy Case|
		property parent : UnitTest(me)
		set sut to sutScript's fromRecord({a: 1})
		sut's clear()
		assertEqual("{}", sut's toString())
	end script
end script

script |map.isEmpty|
	property parent : TestSet(me)
	script |Empty Map|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		ok(sut's isEmpty())
	end script

	script |Happy Case|
		property parent : UnitTest(me)
		set sut to sutScript's fromRecord({a: 1})
		notOk(sut's isEmpty())
	end script
end script

 
script |map.getValue|
	property parent : TestSet(me)
	script |Empty Map|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		assertMissing(sut's getValue(TopLevel's commonKey))
	end script

	script |Not Found|
		property parent : UnitTest(me)
		set sut to sutScript's fromRecord({a: 1})
		assertMissing(sut's getValue("unicorn"))
	end script

	script |Created using fromRecord, Found|
		property parent : UnitTest(me)
		set sut to sutScript's fromRecord({a: 1})
		-- sut's putValue("b", 2)
		assertEqual("1", sut's getValue("a")) 
		-- assertEqual(2, sut's getValue("b"))
	end script

	script |Created using new() - String|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		sut's putValue("a", "1")
		assertEqual("1", sut's getValue("a")) 
	end script

	script |Created using new() - Integer|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		sut's putValue("a", 1)
		assertEqual(1, sut's getValue("a")) 
	end script

	script |Created using new() - Boolean|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		sut's putValue("a", true)
		ok(sut's getValue("a"))
	end script

	script |Created using new() - Float|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		sut's putValue("a", 1.6)
		assertEqual(1.6, sut's getValue("a"))
	end script

	script |Created using new() - Array|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		sut's putValue("a", {1, "2"})
		assertEqual({1, "2"}, sut's getValue("a"))
	end script
end script


script |map.toJsonString|
	property parent : TestSet(me)
	script |Empty Map|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		assertEqual("{}", sut's toJsonString())
	end script

	script |fromRecord|
		property parent : UnitTest(me)
		assertEqual("{\"a\": \"1\", \"b\": \"bee\"}", sutScript's newFromRecord({a: 1, b: "bee"})'s toJsonString())
	end script

	script |Happy Path - new()|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		sut's putValue("a", 1) 
		sut's putValue("b", "bee")
		assertEqual("{\"a\": 1, \"b\": \"bee\"}", sut's toJsonString())
	end script

	script |Happy Path - newFromString|
		property parent : UnitTest(me)
		set sut to sutScript's newFromString("
			a: 1
			b: bee
		")
		assertEqual("{\"a\": \"1\", \"b\": \"bee\"}", sut's toJsonString())
	end script
end script



script |map.putValue tests|
	property parent : TestSet(me)
	script |String|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		sut's putValue(TopLevel's commonKey, "string-value")
		assertEqual("string-value", sut's getValue(TopLevel's commonKey))
	end script

	script |Integer|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		sut's putValue(TopLevel's commonKey, 1)
		assertEqual(1, sut's getValue(TopLevel's commonKey))
	end script

	script |Float|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		sut's putValue(TopLevel's commonKey, 1.1)
		assertEqual(1.1, sut's getValue(TopLevel's commonKey))
	end script

	script |Boolean|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		sut's putValue(TopLevel's commonKey, false)
		notOk(sut's getValue(TopLevel's commonKey))
	end script

end script