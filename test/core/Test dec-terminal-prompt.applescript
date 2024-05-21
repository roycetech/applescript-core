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
	@Created: Friday, May 17, 2024 at 3:26:46 PM
*)
use AppleScript
use scripting additions

property parent : script "com.lifepillar/ASUnit"
---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "dec-terminal-prompt" -- The name of the script to be tested
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use std : script "core/std"
use textUtil : script "core/string"

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
script |Load script - dec-terminal-prompt|
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


script |isGitDirectory tests|
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
		if my name is "afterClass" then afterClass()
		if my name is "afterSuite" then afterSuite()
	end tearDown

	on beforeClass()
		set terminalTab to TopLevel's terminalUtil's getTestingTab()
		set sut to sutScript's decorate(terminalTab)
	end beforeClass
	on afterClass()
	end afterClass
	
	script |User path|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdHome()
		notOk(sut's isGitDirectory())
	end script

	script |Non-user path|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdNonUser()
		notOk(sut's isGitDirectory())
	end script

	script |AppleScript Project path|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdAppleScriptProject()
		ok(sut's isGitDirectory())
	end script
end script


script |isShellPrompt tests|
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
		if my name is "afterClass" then afterClass()
		if my name is "afterSuite" then afterSuite()
	end tearDown

	on beforeClass()
		set terminalTab to TopLevel's terminalUtil's getTestingTab()
		set sut to sutScript's decorate(terminalTab)
	end beforeClass
	on afterClass()
	end afterClass
	on afterSuite()
		-- terminalTab's closeTab() 
	end afterClass
	
	script |Initial state|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdHome()
		ok(sut's isShellPrompt())
	end script

	script |With lingering command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's typeCommand("extra")
		notOk(sut's isShellPrompt())
	end script

	script |Running command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's typeCommand("tail -f ~/applescript-core/logs/applescript-core.log" & return)
		notOk(sut's isShellPrompt())
	end script
end script


script |getPrompt tests|
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
		if my name is "afterClass" then afterClass()
		if my name is "afterSuite" then afterSuite()
	end tearDown

	on beforeClass()
		set terminalTab to TopLevel's terminalUtil's getTestingTab()
		set sut to sutScript's decorate(terminalTab)
	end beforeClass
	on afterClass()
	end afterClass
	on afterSuite() 
		terminalTab's closeTab() 
	end afterClass
	
	script |Home dir without Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdHome()
		assertEqual(std's getUsername() & "@" & textUtil's stringBefore(host name of (system info), ".local") & " ~ %", sut's getPrompt())
	end script

	script |Home dir with Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdHome()
		TopLevel's terminalUtil's typeCommand("linger")
		assertEqual(std's getUsername() & "@" & textUtil's stringBefore(host name of (system info), ".local") & " ~ %", sut's getPrompt())
	end script

	script |Project dir without Command|
		property parent : UnitTest(me)
		delay 1  -- Bandaid.
		TopLevel's terminalUtil's cdAppleScriptProject()
		assertEqual(std's getUsername() & "@" & textUtil's stringBefore(host name of (system info), ".local") & " applescript-core %", sut's getPrompt())
	end script

	script |Project dir with Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdAppleScriptProject()
		TopLevel's terminalUtil's typeCommand("linger")
		assertEqual(std's getUsername() & "@" & textUtil's stringBefore(host name of (system info), ".local") & " applescript-core %", sut's getPrompt())
	end script

	script |Non-shell|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's typeCommand("tail -f ~/applescript-core/logs/applescript-core.log" & return)
		assertMissing(sut's getPrompt())
	end script
end script


script |getPromptText tests|
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
		if my name is "afterClass" then afterClass()
		if my name is "afterSuite" then afterSuite()
	end tearDown
 
	on beforeClass()
		set terminalTab to TopLevel's terminalUtil's getTestingTab()
		set sut to sutScript's decorate(terminalTab)
	end beforeClass
	on afterClass() 
	end afterClass
	on afterSuite() 
		terminalTab's closeTab() 
	end afterClass
	
	script |Home dir without Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdHome()
		assertEqual(std's getUsername() & "@" & textUtil's stringBefore(host name of (system info), ".local") & " ~ %", sut's getPromptText())
	end script

	script |Home dir with Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdHome()
		TopLevel's terminalUtil's typeCommand("linger")
		assertEqual(std's getUsername() & "@" & textUtil's stringBefore(host name of (system info), ".local") & " ~ % linger", sut's getPromptText())
	end script

	script |Project dir without Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdAppleScriptProject()
		assertEqual(std's getUsername() & "@" & textUtil's stringBefore(host name of (system info), ".local") & " applescript-core %", sut's getPromptText())
	end script

	script |Project dir with Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdAppleScriptProject()
		TopLevel's terminalUtil's typeCommand("linger")
		assertEqual(std's getUsername() & "@" & textUtil's stringBefore(host name of (system info), ".local") & " applescript-core % linger", sut's getPromptText())
	end script
end script


script |getLastCommand tests|
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
		if my name is "afterClass" then afterClass()
		if my name is "afterSuite" then afterSuite()
	end tearDown

	on beforeClass()
		set terminalTab to TopLevel's terminalUtil's getTestingTab()
		set sut to sutScript's decorate(terminalTab)
	end beforeClass
	on afterClass()
	end afterClass
	on afterSuite() 
		terminalTab's closeTab() 
	end afterClass
	
	script |Home dir without Command|
		property parent : UnitTest(me)
		assertMissing(sut's getLastCommand())
	end script

	script |Home dir with Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdHome()
		TopLevel's terminalUtil's typeCommand("linger")
		assertEqual("linger", sut's getLastCommand())
	end script

	script |With previously executed command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's typeCommand("cd" & return)
		TopLevel's terminalUtil's typeCommand("ls" & return)
		assertEqual("ls", sut's getLastCommand())
	end script

	script |afterSuite|
		property parent : UnitTest(me)
		ok(true)  -- dummy test to trigger the afterSuite.
	end script	
end script
