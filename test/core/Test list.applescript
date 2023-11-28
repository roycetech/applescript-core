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
property scriptName : "list" -- The name of the script to be tested
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
				set deploymentPath to ((path to library folder from user domain) as text) & "Script Libraries:core:"
			end tell
			
			set sutScript to load script (deploymentPath & scriptName & ".scpt") as alias
		end try
		assertInstanceOf(script, sutScript)
	end script
end script


script |clone tests|
	property parent : TestSet(me)
	script |Missing Value|
		property parent : UnitTest(me)
		assertMissing(sutScript's clone(missing value))
	end script
	
	script |Empty|
		property parent : UnitTest(me)
		assertEqual([], sutScript's clone([]))
		assertEqual({}, sutScript's clone([]))
	end script
	
	script |Non-Empty|
		property parent : UnitTest(me)
		set origin to {1, 2, 3}
		set actual to sutScript's clone(origin)
		assertEqual(count of origin, count of actual)
		repeat with i from 1 to count of origin
			assertEqual(item i of origin, contents of item i of actual)
		end repeat
	end script
	
	script |Original is unaffected by change to the clone|
		property parent : UnitTest(me)
		set origin to []
		set actual to sutScript's clone(origin)
		assertEqual(origin, actual)
		set end of actual to "modified"
		assertEqual(0, length of origin)
		assertEqual(1, length of actual)
	end script
	
	script |Type is preserved| 
		set origin to {1, 2, "3"}
		set actual to sutScript's clone(origin)
		assertEqual(count of origin, count of actual)
		repeat with i from 1 to count of origin
			assertEqual(item i of origin, contents of item i of actual)
		end repeat
	end script
end script


script |indexOf tests|
	property parent : TestSet(me)
	script |Missing List|
		property parent : UnitTest(me)
		assertMissing(sutScript's indexOf(missing value, "element"))
	end script

	script |Missing Element|
		property parent : UnitTest(me)
		assertEqual(2, sutScript's indexOf([1, missing value], missing value))
	end script

	script |Element not found|
		property parent : UnitTest(me)
		assertEqual(0, sutScript's indexOf([1, 2], "x"))
	end script

	script |Element found|
		property parent : UnitTest(me)
		assertEqual(2, sutScript's indexOf([1, 2], 2))
	end script

	script |Element found with different type|
		property parent : UnitTest(me)
		assertEqual(0, sutScript's indexOf([1, 2], "2"))
	end script
end script


script |indexOfText tests|
	property parent : TestSet(me)
	script |Missing List|
		property parent : UnitTest(me)
		assertMissing(sutScript's indexOfText(missing value, "element"))
	end script

	script |Existing Missing Element |
		property parent : UnitTest(me)
		assertEqual(2, sutScript's indexOfText([1, missing value], missing value))
	end script

	script |Non-Existing Missing Element|
		property parent : UnitTest(me)
		assertEqual(0, sutScript's indexOfText([1, 2], missing value))
	end script

	script |Element not found|
		property parent : UnitTest(me)
		assertEqual(0, sutScript's indexOfText([1, 2], "x"))
	end script

	script |Element found|
		property parent : UnitTest(me)
		assertEqual(2, sutScript's indexOfText([1, 2], 2))
	end script

	script |Element found with different type|
		property parent : UnitTest(me)
		assertEqual(2, sutScript's indexOfText([1, 2], "2"))
	end script
end script


script |remove tests|
	property parent : TestSet(me)
	script |Missing List|
		property parent : UnitTest(me)
		assertMissing(sutScript's remove(missing value, "element"))
	end script

	script |Missing Element - Single|
		property parent : UnitTest(me)
		assertEqual([1], sutScript's remove([1, missing value], missing value))
	end script

	script |Missing Element - Multiple|
		property parent : UnitTest(me)
		assertEqual([1], sutScript's remove([missing value, 1, missing value], missing value))
	end script

	script |Element not found|
		property parent : UnitTest(me)
		assertEqual([1, 2], sutScript's remove([1, 2], "x"))
	end script

	script |Element found - Single|
		property parent : UnitTest(me)
		assertEqual([1], sutScript's remove([1, 2], 2))
	end script

	script |Element found - Multiple|
		property parent : UnitTest(me)
		assertEqual([1, 3, 4], sutScript's remove([1, 2, 3, 2, 4], 2))
	end script

	script |Element found with different type|
		property parent : UnitTest(me)
		assertEqual([1, 2], sutScript's remove([1, 2], "2"))
	end script
end script



script |splitByLine tests|
	property parent : TestSet(me)

	script |Missing Value|
		property parent : UnitTest(me)
		assertMissing(sutScript's splitByLine(missing value))
	end script

	script |Basic Scenario|
		property parent : UnitTest(me)
		assertEqual({"one", "two"}, sutScript's splitByLine("one
two"))
	end script

	script |With dollar sign|
		property parent : UnitTest(me)
		assertEqual({"$one", "two"}, sutScript's splitByLine("$one
two"))
	end script

	script |With single quote|
		property parent : UnitTest(me)
		assertEqual({"I'm", "steady"}, sutScript's splitByLine("I'm
steady"))
	end script

	script |With tilde|
		property parent : UnitTest(me)
		assertEqual({"~Struck~", "out"}, sutScript's splitByLine("~Struck~
out"))
	end script

	script |With blank lines|
		property parent : UnitTest(me)
		assertEqual({"one", "two", "three"}, sutScript's splitByLine("
one
	two
three	
"))
	end script

	script |Combination of ASCII 10 and 13|
		property parent : UnitTest(me)
		property LF : ASCII Character 10
		property CR : ASCII Character 13

		set stringInput to LF & tab & tab & "one" & CR & tab & tab & "two" & CR & tab & tab & "three" & LF & tab
		assertEqual({"one", "two", "three"}, sutScript's splitByLine(stringInput))
	end script

end script


script |listsEqual tests|
	property parent : TestSet(me)
	
	script |Missing Value - Left|
		property parent : UnitTest(me)
		notOk(sutScript's listsEqual(missing value, 2))
	end script

	script |Missing Value - right|
		property parent : UnitTest(me)
		notOk(sutScript's listsEqual(1, missing value))
	end script

	script |Missing Value - both|
		property parent : UnitTest(me)
		ok(sutScript's listsEqual(missing value, missing value))
	end script

	script |Equal|
		property parent : UnitTest(me)
		ok(sutScript's listsEqual([1, 2], [1, 2]))
	end script

	script |Not equal|
		property parent : UnitTest(me)
		notOk(sutScript's listsEqual([1, 2], [1, 3]))
	end script

	script |Different Size|
		property parent : UnitTest(me)
		notOk(sutScript's listsEqual([1, 2], [1, 2, 3]))
	end script

	script |Different types|
		property parent : UnitTest(me)
		notOk(sutScript's listsEqual([1, 2], [1, "2"]))
	end script
end script


script |simpleSort tests|
	property parent : TestSet(me)
	
	script |Missing Value|
		property parent : UnitTest(me)
		assertMissing(sutScript's simpleSort(missing value))
	end script

	script |Basic Sorting|
		property parent : UnitTest(me)
		assertEqual({"a", "b", "c"}, sutScript's simpleSort({"b", "c", "a"}))
	end script
end script


script |newWithElements tests|
	property parent : TestSet(me)
	
	script |Invalid Count|
		property parent : UnitTest(me)
		script Lambda
			sutScript's newWithElements("a", 0)
		end script
		shouldRaise(sutScript's ERROR_LIST_COUNT_INVALID, Lambda, "Expected invalid count error was not thrown")
	end script

	script |Single fill|
		property parent : UnitTest(me)
		assertEqual({"a"}, sutScript's newWithElements("a", 1))
	end script

	script |Multiple fill|
		property parent : UnitTest(me)
		assertEqual({22, 22}, sutScript's newWithElements(22, 2))
	end script
end script


script |lastMatchingIndexOf tests|
	property parent : TestSet(me)
	
	script |Missing list|
		property parent : UnitTest(me)
		assertEqual(-1, sutScript's lastMatchingIndexOf(missing value, "a"))
	end script

	script |Missing target - not found|
		property parent : UnitTest(me)
		assertEqual(0, sutScript's lastMatchingIndexOf({1}, missing value))
	end script

	script |Missing target - found|
		property parent : UnitTest(me)
		assertEqual(2, sutScript's lastMatchingIndexOf({1, missing value}, missing value))
	end script

	script |No match|
		property parent : UnitTest(me)
		assertEqual(0, sutScript's lastMatchingIndexOf({"apple", "orange", "application"}, "orangutan"))
	end script

	script |Single match|
		property parent : UnitTest(me)
		assertEqual(2, sutScript's lastMatchingIndexOf({"apple", "orange", "application"}, "orange"))
	end script

	script |Multiple match|
		property parent : UnitTest(me)
		assertEqual(3, sutScript's lastMatchingIndexOf({"apple", "orange", "application"}, "app"))
	end script
end script
 

script |listContains tests|
	property parent : TestSet(me)
	
	script |Missing list|
		property parent : UnitTest(me)
		notOk(sutScript's listContains(missing value, "a"))
	end script

	script |Missing target - not found|
		property parent : UnitTest(me)
		notOk(sutScript's listContains({1}, missing value))
	end script

	script |Missing target - found|
		property parent : UnitTest(me)
		ok(sutScript's listContains({1, missing value}, missing value))
	end script

	script |Empty list|
		property parent : UnitTest(me)
		notOk(sutScript's listContains({}, "x"))
	end script

	script |Not found|
		property parent : UnitTest(me)
		notOk(sutScript's listContains({1}, 2))
	end script

	script |Found|
		property parent : UnitTest(me)
		ok(sutScript's listContains({1, 2, 3}, 2))
	end script

	script |With Dollar Sign|
		property parent : UnitTest(me)
		ok(sutScript's listContains({1, "$five", 3}, "$five"))
	end script
end script

