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

use textUtil : script "string"

property parent : script "com.lifepillar/ASUnit"

---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "file" -- The name of the script to be tested
property testFile : "~/applescript-core/file-test.txt"
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use loggerFactory : script "logger-factory"
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
		end try
		assertInstanceOf(script, sutScript)
	end script
end script


script |getBaseFilename tests|
	property parent : TestSet(me)
	property sut : missing value
	script |test something|
		property parent : UnitTest(me)
		assertEqual("README.md", sutScript's getBaseFilename("/Users/cloud.strife/Projects/README.md"))
	end script
end script


script |replaceText tests|
	property parent : TestSet(me)
	property sut : missing value

	on setUp()
		TopLevel's __createTestFile()
	end setUp
	on tearDown()
		TopLevel's __deleteTestFile()
	end tearDown

	script |Empty File|
		property parent : UnitTest(me)
		sutScript's replaceText(testFile, "{{keyword}}", "**replacement**")
		assertEqual("", TopLevel's __readTextFile())
	end script

	script |Substring Not Found|
		property parent : UnitTest(me)
		TopLevel's __writeTextFile("Lorem Ipsum
Second Line
")
		sutScript's replaceText(testFile, "{{keyword}}", "**replacement**")
		ok(TopLevel's __readTextFile() does not contain "**replacement**")
	end script

	script |Substring Found Once|
		property parent : UnitTest(me)
		TopLevel's __writeTextFile("Hello
{{keyword}}
")
		sutScript's replaceText(testFile, "{{keyword}}", "**replacement**")
		assertEqual(textUtil's multiline("Hello
**replacement**
"), TopLevel's __readTextFile())
	end script

	script |Substring Multiple Times|
		property parent : UnitTest(me)
		TopLevel's __writeTextFile("Hello
{{keyword}}
Yes
{{keyword}}
")
		sutScript's replaceText(testFile, "{{keyword}}", "**replacement**")
		assertEqual(textUtil's multiline("Hello
**replacement**
Yes
**replacement**
"), TopLevel's __readTextFile())
	end script
end script


(* !Do not use quoted form, they fail because of the tilde form. *)
on __writeTextFile(textToWrite)
	do shell script "echo '" & textToWrite & "' >> "  & testFile
end __writeTextFile


on __readTextFile()
	do shell script "cat "  &  testFile
end __readTextFile


on __createTestFile()
		do shell script "touch " & testFile
end __createTestFile


on __deleteTestFile()
	do shell script "rm "  & testFile
end __deleteTestFile

