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

	@Known Issues:
		October 3, 2023 9:30 PM - Still fails intermittently, about 1 in every 5 runs. Warzone.
*)
use AppleScript
use scripting additions

use std : script "core/std"
use textUtil : script "core/string"
use usrLib : script "core/user"
use retryLib : script "core/retry"

property parent : script "com.lifepillar/ASUnit"

---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "file" -- The name of the script to be tested
property testFile : "~/applescript-core/file-test.txt"
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use loggerFactory : script "core/logger-factory"
property logger : missing value
property retry : missing value
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
			set retry to retryLib's new()
		end try
		assertInstanceOf(script, sutScript)
	end script
end script


script |getBaseFilename tests| 
	property parent : TestSet(me)
	property sut : missing value 

	on setUp() 
		TopLevel's __createTestFile() 
	end setUp

	on tearDown()
		TopLevel's __deleteTestFile()   
	end tearDown 

	script |Basic Test|
		property parent : unitTest(me)
		assertEqual("README.md", sutScript's getBaseFilename("/Users/cloud.strife/Projects/README.md"))
	end script

	script |Missing Value|
		property parent : unitTest(me)
		assertMissing(sutScript's getBaseFilename(missing value))
	end script
end script 


script |getContainingDirectory tests| 
	property parent : TestSet(me)
	property sut : missing value 

	script |Missing Value|
		property parent : unitTest(me)
		assertMissing(sutScript's getContainingDirectory(missing value))
	end script

	script |Root file|
		property parent : unitTest(me)
		assertEqual("/", sutScript's getContainingDirectory("/unit-test.txt"))
	end script

	script |Home File|
		property parent : unitTest(me)
		assertEqual("/Users/" & std's getUsername(), sutScript's getContainingDirectory("~/unit-test.txt"))
	end script

	script |Home Subdirectory|
		property parent : unitTest(me)
		assertEqual("/Users/" & std's getUsername() & "/Library" , sutScript's getContainingDirectory("~/Library/Script Libraries/"))
	end script

	script |Basic|
		property parent : unitTest(me)
		assertEqual("/etc" , sutScript's getContainingDirectory("/etc/hosts"))
	end script
end script 
 

script |getFolderName tests| 
	property parent : TestSet(me)
	property sut : missing value 

	script |Missing Value|
		property parent : unitTest(me)
		assertMissing(sutScript's getFolderName(missing value))
	end script

	script |Root file|
		property parent : unitTest(me)
		assertMissing(sutScript's getFolderName("/unit-test.txt"))
	end script

	script |Home Path|
		property parent : unitTest(me)
		assertEqual(std's getUsername(), sutScript's getFolderName("~/unit-test.txt"))
	end script

	script |Home Sub Path|
		property parent : unitTest(me)
		assertEqual("Projects", sutScript's getFolderName("~/Projects/unit-test.txt"))
	end script

	script |Basic|
		property parent : unitTest(me)
		assertEqual("strife", sutScript's getFolderName("/Users/cloud/strife/unit-test.txt"))
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
		property parent : unitTest(me)
		sutScript's replaceText(testFile, "{{keyword}}", "**replacement**")
		assertEqual("", TopLevel's __readTestFile())
	end script
	
	script |Substring Not Found| 
		property parent : unitTest(me)
		TopLevel's __writeTextFile("Lorem Ipsum
Second Line
")
		sutScript's replaceText(testFile, "{{keyword}}", "**replacement**")
		ok(TopLevel's __readTestFile() does not contain "**replacement**")
	end script
	
	script |Substring Found Once| 
		property parent : unitTest(me)
		TopLevel's __writeTextFile("Hello
{{keyword}}
")
		sutScript's replaceText(testFile, "{{keyword}}", "**replacement**")
		assertEqual(textUtil's multiline("Hello
**replacement**
"), TopLevel's __readTestFile())
	end script
	
	script |Substring Multiple Times|
		property parent : unitTest(me)
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
"), TopLevel's __readTestFile())
	end script
	
	script |Substring with Ampersand|
		property parent : unitTest(me)
		TopLevel's __writeTextFile("Hello
{{keyword}}
")
		sutScript's replaceText(testFile, "{{keyword}}", "**&replacement**")
		assertEqual(textUtil's multiline("Hello
**&replacement**
"), TopLevel's __readTestFile())
	end script
end script
 

script |deleteLineWithSubstring tests|
	property parent : TestSet(me)

	on setUp()
		TopLevel's __createTestFile() 
	end setUp
	on tearDown()
		TopLevel's __deleteTestFile()
	end tearDown 

	script |Substring not found|
		property parent : UnitTest(me)
		TopLevel's __writeTextFile("This is a paradise
")
		sutScript's deleteLineWithSubstring(testFile, "unicorn")
		assertEqual(textUtil's multiline("This is a paradise
"), TopLevel's __readTestFile()) 
	end script

	script |Substring found|
		property parent : UnitTest(me) 
		TopLevel's __writeTextFile("This file
has a bug
is perfect
")
		sutScript's deleteLineWithSubstring(testFile, "bug")
		assertEqual(textUtil's multiline("This file
is perfect
"), TopLevel's __readTestFile()) 
	end script

	script |Substring found multiple times|
		property parent : UnitTest(me)
		TopLevel's __writeTextFile("This file
has a bugs here
is perfect
and another bug here
")
		sutScript's deleteLineWithSubstring(testFile, "bug")
		assertEqual(textUtil's multiline("This file
is perfect
"), TopLevel's __readTestFile()) 
	end script
end script 


script |_quotePath tests|
	property parent : TestSet(me)
	
	script |User path is ignored|
		property parent : UnitTest(me)
		-- assertEqual("/Users/" & std's getUsername() & "/Projects", sutScript's _quotePath("~/Projects"))
		assertEqual("~/Projects", sutScript's _quotePath("~/Projects"))
	end script

	script |Non User path is quoted|
		property parent : UnitTest(me)
		assertEqual("'/Users/cloud/Script Libraries'", sutScript's _quotePath("/Users/cloud/Script Libraries"))
	end script
end script


script |deleteFile tests|
	property parent : TestSet(me)

	script |File not found|
		property parent : UnitTest(me)
		notOk(sutScript's deleteFile("~/unicorn.txt"))
	end script

	script |File found|
		property parent : UnitTest(me)
		TopLevel's __createTestFile()
		ok(sutScript's deleteFile(TopLevel's testFile))
		notOk(TopLevel's __existTestFile())
	end script
end script


script |quoteFilePath tests|
	property parent : TestSet(me)

	script |Missing value| 
		property parent : UnitTest(me)
		assertMissing(sutScript's quoteFilePath(missing value))
	end script

	script |tilde-relative Path|
		property parent : UnitTest(me)
		assertEqual("~/Projects", sutScript's quoteFilePath("~/Projects"))
	end script

	script |non tilde-relative Path|
		property parent : UnitTest(me)
		assertEqual("'/Users/Spaced Path'", sutScript's quoteFilePath("/Users/Spaced Path"))
	end script 
end script


script |convertPathToTilde tests|
	property parent : TestSet(me)

	script |Missing value| 
		property parent : UnitTest(me)
		assertMissing(sutScript's convertPathToTilde(missing value))
	end script

	script |User Path|
		property parent : UnitTest(me)
		assertEqual("~/Projects", sutScript's convertPathToTilde("/Users/" & std's getUsername() & "/Projects"))
	end script

	script |Non-User Path|
		property parent : UnitTest(me)
		assertEqual("/Applications", sutScript's convertPathToTilde("/Applications"))
	end script

	script |Tilde-relative Path|
		property parent : UnitTest(me)
		assertEqual("~/Desktop", sutScript's convertPathToTilde("~/Desktop"))
	end script
end script


script |containsText tests|
	property parent : TestSet(me)

	on setUp()
		TopLevel's __createTestFile()
	end setUp
	on tearDown()
		TopLevel's __deleteTestFile()
	end tearDown

	script |Substring not found|
		property parent : UnitTest(me)
		TopLevel's __writeTextFile("This is a paradise
")
		notOk(sutScript's containsText(testFile, "unicorn"))
	end script

	script |Substring found|
		property parent : UnitTest(me)
		TopLevel's __writeTextFile("This is a paradise
")
		ok(sutScript's containsText(testFile, "paradise"))
	end script

	script |Substring found - Spaced Substring|
		property parent : UnitTest(me)
		TopLevel's __writeTextFile("This is a paradise
")
		ok(sutScript's containsText(testFile, "a paradise"))
	end script
end script

script |insertBeforeEmptyLine tests|
	property parent : TestSet(me)
	property input : "Lorem Ipsum.
Same paragraph

2nd para.
"

	on setUp()
		TopLevel's __createTestFile()
	end setUp
	on tearDown()
		TopLevel's __deleteTestFile()
	end tearDown

	script |Substring not found|
		property parent : UnitTest(me)
		TopLevel's __writeTextFile(input) 
		ok(sutScript's insertBeforeEmptyLine(testFile, "unicorn", "kindness"))
		assertEqual(textUtil's multiline(input), TopLevel's __readTestFile())
	end script

	script |Substring found|
		property parent : UnitTest(me)
		TopLevel's __writeTextFile(input)
		ok(sutScript's insertBeforeEmptyLine(testFile, "Lorem", "kindness"))
		assertEqual(textUtil's multiline("Lorem Ipsum.
Same paragraph
kindness

2nd para.
"), TopLevel's __readTestFile())
	end script  

	script |Substring found - text to insert has dollar sign|
		property parent : UnitTest(me)
		TopLevel's __writeTextFile(input)
		ok(sutScript's insertBeforeEmptyLine(testFile, "Lorem", "Train-$Course"))
		assertEqual(textUtil's multiline("Lorem Ipsum.
Same paragraph
Train-$Course

2nd para.
"), TopLevel's __readTestFile())
	end script
end script


(* !Do not use quoted form, they fail because of the tilde form. *)
on __writeTextFile(textToWrite)
	do shell script "echo '" & textToWrite & "' >> " & testFile
end __writeTextFile  

 
on __existTestFile() 
	"true" is equal to do shell script "test -f " & testFile & " && echo true || echo false" 
end __writeTextFile


on __readTestFile()   
	script RetryableRead
		do shell script "cat " & testFile 
	end script	
	retry's exec on result for 15 by 0.5
end __readTestFile


(*
	Battle ground here.  Added retry and delay to improve success rate.
*)
on __createTestFile() 
	script WaitedCreate
		do shell script "touch " & testFile 
		delay 0.1    
		if __existTestFile() then return true    
	end script
	retry's exec on result for 30 by 0.5
end __createTestFile


on __deleteTestFile()
	script WaitedDelete
		do shell script "rm " & testFile
		delay 0.1
		if not __existTestFile() then return true
	end script
	retry's exec on result for 15 by 0.5
end __deleteTestFile