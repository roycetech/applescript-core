(*!
	@header
	@abstract
		A template for unit testing.
	@discussion
		Copy this template in the folder containing the script to be tested and customize it as follows:
	
		1) Provide a description for this test suite and the name of the script to be tested.
		2) Write tests :)

	@charset macintosh
	@Created: August 26, 2023 11:01 AM
*)
use AppleScript
use scripting additions

property parent : script "com.lifepillar/ASUnit"

---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "string" -- The name of the script to be tested
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


script |stringAfter tests|
	property parent : TestSet(me)
	script |source text is missing value|
		property parent : UnitTest(me)
		assertMissing(sutScript's stringAfter(missing value, "abc"))
	end script

	script |substring is missing value|
		property parent : UnitTest(me)
		assertMissing(sutScript's stringAfter("abc", missing value))
	end script

	script |substring is not found|
		property parent : UnitTest(me)
		assertMissing(sutScript's stringAfter("abc", "x"))
	end script

	script |substring is found|
		property parent : UnitTest(me)
		assertEqual("bad wolf", sutScript's stringAfter("The big bad wolf", "big "))
	end script

	script |substring is found multiple times|
		property parent : UnitTest(me)
		assertEqual("bad wolf and the big bad lion", sutScript's stringAfter("The big bad wolf and the big bad lion", "big "))
	end script

	script |substring is at the end|
		property parent : UnitTest(me)
		assertMissing(sutScript's stringAfter("The big bad wolf", "wolf"))
	end script
end script


script |lastStringAfter tests|
	property parent : TestSet(me)
	script |source text is missing value|
		property parent : UnitTest(me)
		assertMissing(sutScript's lastStringAfter(missing value, "abc"))
	end script

	script |substring is missing value|
		property parent : UnitTest(me)
		assertMissing(sutScript's lastStringAfter("abc", missing value))
	end script

	script |substring is not found|
		property parent : UnitTest(me)
		assertMissing(sutScript's lastStringAfter("abc", "x"))
	end script

	script |substring is found|
		property parent : UnitTest(me)
		assertEqual("bad wolf", sutScript's lastStringAfter("The big bad wolf", "big "))
	end script

	script |substring is found multiple times|
		property parent : UnitTest(me)
		assertEqual("bad lion", sutScript's lastStringAfter("The big bad wolf and the big bad lion", "big "))
	end script
end script


script |stringBefore tests|
	property parent : TestSet(me)
	script |source text is missing value|
		property parent : UnitTest(me)
		assertMissing(sutScript's stringBefore(missing value, "abc"))
	end script

	script |substring is missing value|
		property parent : UnitTest(me)
		assertMissing(sutScript's stringBefore("abc", missing value))
	end script

	script |substring is not found|
		property parent : UnitTest(me)
		assertMissing(sutScript's stringBefore("abc", "x"))
	end script

	script |substring is found - midway|
		property parent : UnitTest(me)
		assertEqual("The big", sutScript's stringBefore("The big bad wolf", " bad"))
	end script

	script |substring is found - ending|
		property parent : UnitTest(me)
		assertEqual("The big bad", sutScript's stringBefore("The big bad wolf", " wolf"))
	end script

	script |substring is found - beginning|
		property parent : UnitTest(me)
		assertMissing(sutScript's stringBefore("The big bad wolf", "The"))
	end script
end script


script |stringBetween tests|
	property parent : TestSet(me)
		
	script |source text is missing value|
		property parent : UnitTest(me)
		assertMissing(sutScript's stringBetween(missing value, "abc", "xyz"))
	end script

	script |substringStart is missing value|
		property parent : UnitTest(me)
		assertMissing(sutScript's stringBetween("abcde", missing value, "xyz"))
	end script

	script |substringStart is not found|
		property parent : UnitTest(me)
		assertMissing(sutScript's stringBetween("abcde", "x", "e"))
	end script

	script |substringEnd is missing value|
		property parent : UnitTest(me)
		assertMissing(sutScript's stringBetween("abcde", "abc", missing value))
	end script

	script |substringEnd is not found|
		property parent : UnitTest(me)
		assertMissing(sutScript's stringBetween("abcde", "a", "x"))
	end script

	script |Happy|
		property parent : UnitTest(me)
		assertEqual("bc", sutScript's stringBetween("abcde", "a", "d"))
	end script
end script


script |ltrim tests|
	property parent : TestSet(me)
		
	script |Preceeding space and new line|
		property parent : UnitTest(me)
		assertEqual("SELECT", sutScript's ltrim("
	SELECT"))
	end script

	script |No leading whitespace|
		property parent : UnitTest(me)
		assertEqual("SELECT", sutScript's ltrim("SELECT"))
	end script

	script |Spaces only|
		property parent : UnitTest(me)
		assertEqual("", sutScript's ltrim("   "))
	end script

	script |Empty string|
		property parent : UnitTest(me)
		assertEqual("", sutScript's ltrim(""))
	end script
end script


script |replaceFirst tests|
	property parent : TestSet(me)
		
	script |Missing value|
		property parent : UnitTest(me)
		assertMissing(sutScript's replaceFirst(missing value, "a", "b"))
	end script

	script |Missing substring|
		property parent : UnitTest(me)
		assertEqual("abc", sutScript's replaceFirst("abc", missing value, "b"))
	end script

	script |Missing replacement|
		property parent : UnitTest(me)
		assertEqual("ab", sutScript's replaceFirst("abc", "c", missing value))
	end script

	script |Not found|
		property parent : UnitTest(me)
		assertEqual("big fat fish", sutScript's replaceFirst("big fat fish", "cat", "train"))
	end script

	script |Longer substring|
		property parent : UnitTest(me)
		assertEqual("big fat fish", sutScript's replaceFirst("big fat fish", "big fat fish oil", "train"))
	end script

	script |Single Match|
		property parent : UnitTest(me)
		assertEqual("big fat wolf", sutScript's replaceFirst("big fat fish", "fish", "wolf"))
	end script

	script |Multiple matches|
		property parent : UnitTest(me)
		assertEqual("one by two", sutScript's replaceFirst("two by two", "two", "one"))
	end script
end script


script |replaceLast tests|
	property parent : TestSet(me)
		
	script |Missing value|
		property parent : UnitTest(me)
		assertMissing(sutScript's replaceLast(missing value, "a", "b"))
	end script

	script |Missing substring|
		property parent : UnitTest(me)
		assertEqual("abc", sutScript's replaceLast("abc", missing value, "b"))
	end script

	script |Missing replacement|
		property parent : UnitTest(me)
		assertEqual("ab", sutScript's replaceLast("abc", "c", missing value))
	end script

	script |Not found|
		property parent : UnitTest(me)
		assertEqual("big fat fish", sutScript's replaceLast("big fat fish", "cat", "train"))
	end script

	script |Longer substring|
		property parent : UnitTest(me)
		assertEqual("big fat fish", sutScript's replaceLast("big fat fish", "big fat fish oil", "train"))
	end script

	script |Single Match|
		property parent : UnitTest(me)
		assertEqual("big healthy fish", sutScript's replaceLast("big fat fish", "fat", "healthy"))
	end script

	script |Multiple matches|
		property parent : UnitTest(me)
		assertEqual("big fat fish and healthy goat", sutScript's replaceLast("big fat fish and fat goat", "fat", "healthy"))
	end script
end script

script |format tests|
	property parent : TestSet(me)
		
	script |Missing value|
		property parent : UnitTest(me)
		assertMissing(sutScript's format(missing value, {1}))
	end script

	script |Missing value for tokens|
		property parent : UnitTest(me)
		assertEqual("Result: missing value", sutScript's format("Result: {}", missing value))
	end script

	script |Scalar Token - end|
		property parent : UnitTest(me)
		assertEqual("Result: 1", sutScript's format("Result: {}", 1))
	end script

	script |Scalar Token - mid|
		property parent : UnitTest(me)
		assertEqual("Result: 1 ok?", sutScript's format("Result: {} ok?", 1))
	end script

	script |Scalar Token - start|
		property parent : UnitTest(me)
		assertEqual("I. Result", sutScript's format("{} Result", "I."))
	end script

	script |List Token|
		property parent : UnitTest(me)
		assertEqual("Result: 1, 2", sutScript's format("Result: {}, {}", {1, 2}))
	end script

	script |With single quote|
		property parent : UnitTest(me)
		assertEqual("Child's play", sutScript's format("{} play", "Child's"))
	end script

	script |With bang|
		property parent : UnitTest(me)
		assertEqual("Pew!", sutScript's format("{}", "Pew!"))
	end script

	script |With Double Quotes|
		property parent : UnitTest(me)
		assertEqual("{\"attr-name\": 1}", sutScript's format("{\"{}\": 1}", "attr-name"))
	end script

	script |Multiline|
		property parent : UnitTest(me)
		assertEqual("javascript;
$('a') = 'hello';", sutScript's format("javascript;
$('{}') = '{}';", {"a", "hello"}))
	end script
end script


script |replace|
	property parent : TestSet(me)
		
	script |Missing source text|
		property parent : UnitTest(me)
		assertEqual("1", sutScript's replace(missing value, missing value, 1))
	end script

	script |Missing substring|
		property parent : UnitTest(me)
		assertEqual("source", sutScript's replace("source", missing value, "changed"))
	end script

	script |Substring found, missing replacement|
		property parent : UnitTest(me)
		assertEqual("sce", sutScript's replace("source", "our", missing value))
	end script

	script |Substring not found|
		property parent : UnitTest(me)
		assertEqual("source", sutScript's replace("source", "x", "y"))
	end script

	script |Starts with|
		property parent : UnitTest(me)
		assertEqual("xxxrce", sutScript's replace("source", "sou", "xxx"))
	end script

	script |Middle|
		property parent : UnitTest(me)
		assertEqual("sxxxce", sutScript's replace("source", "our", "xxx"))
	end script

	script |Ends with|
		property parent : UnitTest(me)
		assertEqual("souxxx", sutScript's replace("source", "rce", "xxx"))
	end script

	script |Single quotes|
		property parent : UnitTest(me)
		assertEqual("document.querySelector('a[href*=xyz]').click()", sutScript's replace("document.querySelector('a[href*={}]').click()", "{}", "xyz"))
	end script

	script |Multiple|
		property parent : UnitTest(me)
		assertEqual("six by six", sutScript's replace("two by two", "two", "six"))
	end script

	script |With parenthesis|
		property parent : UnitTest(me)
		assertEqual("yo(nes", sutScript's replace("yo(no", "no", "nes"))
	end script

	script |Escape the parenthesis|
		property parent : UnitTest(me)
		assertEqual("yo\\(no", sutScript's replace("yo(no", "(", "\\("))
	end script

	script |Escape two parentheses|
		property parent : UnitTest(me)
		assertEqual("yo\\(no\\)", sutScript's replace(sutScript's replace("yo(no)", "(", "\\("), ")", "\\)"))
	end script

	script |Escape slashes|
		property parent : UnitTest(me)
		assertEqual("https:\\/\\/localhost:8080\\/yo", sutScript's replace("https://localhost:8080/yo", "/", "\\/"))
	end script

	script |Escape ending in a slash|
		property parent : UnitTest(me)
		assertEqual("https:\\/\\/localhost:8080\\/yo\\/", sutScript's replace("https://localhost:8080/yo/", "/", "\\/"))
	end script

	script |Bugged sample|
		property parent : UnitTest(me)
		assertEqual("=Applications=Setapp", sutScript's replace("/Applications/Setapp", "/", "="))
	end script

	script |Escaping square brackets|
		property parent : UnitTest(me)
		assertEqual("\\[Square] Bracket", sutScript's replace("[Square] Bracket", "[", "\\["))
	end script
end script


script |decodeUrl|
	property parent : TestSet(me)
	script |Missing source text|
		property parent : UnitTest(me)
		assertEqual("hello world", sutScript's decodeUrl("hello%20world"))
	end script
end script


script |title|
	property parent : TestSet(me)

	script |Missing source text|
		property parent : UnitTest(me)
		assertMissing(sutScript's title(missing value))
	end script

	script |Basic|
		property parent : UnitTest(me)
		assertEqual("Hello world", sutScript's title("hello world"))
	end script
end script


script |removeEnding|
	property parent : TestSet(me)

	script |Not found|
		property parent : UnitTest(me)
		assertEqual("Hello", sutScript's removeEnding("Hello", "not found"))
	end script

	script |Found|
		property parent : UnitTest(me)
		assertEqual("Hell", sutScript's removeEnding("Hello", "o"))
	end script
end script
