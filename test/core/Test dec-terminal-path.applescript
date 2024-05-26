(*!
	@header
	@abstract
		A template for unit testing.
	@discussion
		Copy this template in the folder containing the script to be tested and customize it as follows:
	
		1) Provide a description for this test suite and the name of the script to be tested.
		2) Write tests :)

	@Known Issues:

	@charset macintosh
	@Created: Thursday, May 16, 2024 at 3:45:36 PM
*)
use AppleScript
use scripting additions


property parent : script "com.lifepillar/ASUnit"
---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "dec-terminal-path" -- The name of the script to be tested
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use std : script "core/std"
use loggerFactory : script "core/logger-factory"
use terminalUtilLib : script "core/test/terminal-util"

property logger : missing value
property terminalUtil : missing value

property TopLevel : me
property suite : makeTestSuite(suitename)

loggerFactory's inject(me)
set terminalUtil to terminalUtilLib's new() 
autorun(suite)

---------------------------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------------------------

-- Don't change this test case if you are testing an external script
-- in the same folder as this test script! We load the script in a test case, because
-- this will work when all the tests in the current folder are run together using loadTestsFromFolder().
-- Besides, this will make sure that we are using the latest version of the script
-- to be tested even if we do not recompile this test script.
script |Load script - dec-terminal-path|
	property parent : TestSet(me)
	script |Loading the script|
		property parent : UnitTest(me)
		try
			tell application "Finder"
				set deploymentPath to ((path to library folder from user domain) as text) & "Script Libraries:core:"
			end tell
			
			set sutScript to load script (deploymentPath & scriptName & ".scpt") as alias
			set terminalUtil to terminalUtilLib's new()
		end try
		assertInstanceOf(script, sutScript) 
	end script
end script 


script |getDirectoryName tests|
	property parent : TestSet(me)
	property executedTestCases : 0 
	property terminalTab : missing value
	
	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()		
	end setUp
	on tearDown()
		TopLevel's terminalUtil's clearScreenAndCommands()
		if my name is "afterClass" then 
			afterClass()
		end if		
	end tearDown

	on beforeClass()
		set terminalTab to TopLevel's terminalUtil's getTestingTab()
	end beforeClass

	on afterClass()
	end afterClass
	
	script |User path|
		property parent : UnitTest(me)
		set sut to sutScript's decorate(terminalTab)
		TopLevel's terminalUtil's cdHome()
		assertEqual(std's getUsername(), sut's getDirectoryName())
	end script

	script |Spaced Path|
		property parent : UnitTest(me)
		set sut to sutScript's decorate(terminalTab)
		TopLevel's terminalUtil's cdScriptLibrary()
		assertEqual("Script Libraries", sut's getDirectoryName())
	end script
end script


script |getPosixPath tests| 
	property parent : TestSet(me)
	property executedTestCases : 0 
	property terminalTab : missing value
	property sut : missing value
	
	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()		
	end setUp
	on tearDown()
		TopLevel's terminalUtil's clearScreenAndCommands()
		if my name is "afterClass" then 
			afterClass()
		end if		
	end tearDown

	on beforeClass()
		set terminalTab to TopLevel's terminalUtil's getTestingTab()
		set sut to sutScript's decorate(terminalTab)
	end beforeClass
	on afterClass()
	end afterClass
	
	script |Home path|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdHome()
		assertEqual("/Users/" & std's getUsername(), sut's getPosixPath())
	end script

	script |User Subdir|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdScriptLibrary()
		assertEqual("/Users/" & std's getUsername() & "/Library/Script Libraries", sut's getPosixPath())
	end script

	script |Non-User|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdNonUser()
		assertEqual("/usr/lib", sut's getPosixPath())
	end script
end script


script |isUserPath tests|
	property parent : TestSet(me)
	property executedTestCases : 0 
	property terminalTab : missing value
	
	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()		
	end setUp
	on tearDown()
		TopLevel's terminalUtil's clearScreenAndCommands()
		if my name is "afterClass" then 
			afterClass()
		end if		
	end tearDown

	on beforeClass()
		set terminalTab to TopLevel's terminalUtil's getTestingTab()
	end beforeClass
	on afterClass()
	end afterClass
	
	script |Home path|
		property parent : UnitTest(me)
		set sut to sutScript's decorate(terminalTab)
		TopLevel's terminalUtil's cdHome()
		ok(sut's isUserPath())
	end script

	script |User Subdir|
		property parent : UnitTest(me)
		set sut to sutScript's decorate(terminalTab)
		TopLevel's terminalUtil's cdScriptLibrary()
		ok(sut's isUserPath())
	end script

	script |Non-User|
		property parent : UnitTest(me)
		set sut to sutScript's decorate(terminalTab)
		TopLevel's terminalUtil's cdNonUser()
		notOk(sut's isUserPath())
	end script
end script


script |isAtHomePath tests|
	property parent : TestSet(me)
	property executedTestCases : 0 
	property terminalTab : missing value
	
	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()		
	end setUp
	on tearDown()
		TopLevel's terminalUtil's clearScreenAndCommands()
		if my name is "afterClass" then 
			afterClass()
		end if		
	end tearDown

	on beforeClass()
		set terminalTab to TopLevel's terminalUtil's getTestingTab()
	end beforeClass
	on afterClass()
	end afterClass
	
	script |Home path|
		property parent : UnitTest(me)
		set sut to sutScript's decorate(terminalTab)
		TopLevel's terminalUtil's cdHome()
		ok(sut's isAtHomePath())
	end script

	script |User Subdir|
		property parent : UnitTest(me)
		set sut to sutScript's decorate(terminalTab)
		TopLevel's terminalUtil's cdScriptLibrary()
		notOk(sut's isAtHomePath())
	end script

	script |Non-User|
		property parent : UnitTest(me)
		set sut to sutScript's decorate(terminalTab)
		TopLevel's terminalUtil's cdNonUser()
		notOk(sut's isAtHomePath())
	end script
end script


script |getHomeRelativePath tests|
	property parent : TestSet(me)
	property executedTestCases : 0 
	property terminalTab : missing value
	
	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()		
	end setUp
	on tearDown()
		TopLevel's terminalUtil's clearScreenAndCommands()
		if my name is "afterSuite" then 
			afterSuite()
		end if		
	end tearDown

	on beforeClass()
		set terminalTab to TopLevel's terminalUtil's getTestingTab()
	end beforeClass
	on afterClass()
	end afterClass
	on afterSuite()
		terminalTab's closeTab()
	end afterClass
	
	script |Home path|
		property parent : UnitTest(me)
		set sut to sutScript's decorate(terminalTab)
		TopLevel's terminalUtil's cdHome()
		assertEqual("", sut's getHomeRelativePath())
	end script

	script |User Subdir|
		property parent : UnitTest(me)
		set sut to sutScript's decorate(terminalTab)
		TopLevel's terminalUtil's cdScriptLibrary()
		assertEqual("Library/Script Libraries", sut's getHomeRelativePath())
	end script

	script |Non-User|
		property parent : UnitTest(me)
		set sut to sutScript's decorate(terminalTab)
		TopLevel's terminalUtil's cdNonUser()
		assertMissing(sut's getHomeRelativePath())
	end script

	script |afterSuite|
		property parent : UnitTest(me)
		ok(true)  -- dummy test to trigger the afterSuite.
	end script	
end script
