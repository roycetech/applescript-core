(*!
	@header
	@abstract
		A template for unit testing.
	@discussion
		Copy this template in the folder containing the script to be tested and customize it as follows:
	
		1) Provide a description for this test suite and the name of the script to be tested.
		2) Write tests :)

	@Testing Notes:
		* Prefer to clean up the terminal manually after test cases that needs them.
			* This is because having them on tear down is an expensive operation with little benefit.

	@charset macintosh
	@Created: Friday, May 24, 2024 at 11:14:07 AM
*)
use AppleScript
use scripting additions

property parent : script "com.lifepillar/ASUnit"
---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "dec-terminal-prompt-omz" -- The name of the script to be tested
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use std : script "core/std"
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use terminalUtilLib : script "core/test/terminal-util"
use usrLib : script "core/user"

property logger : missing value
property terminalUtil : missing value

property TopLevel : me
property suite : makeTestSuite(suitename)
property DEFAULT_HOME_PROMPT : "➜  ~"

loggerFactory's inject(me)
set terminalUtil to terminalUtilLib's new()
set useCommandPasting of terminalUtil to true
autorun(suite)

---------------------------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------------------------

script |Start Suite - dec-terminal-prompt-omz|
	property parent : TestSet(me)
	script |Prepare Suite|
		property parent : UnitTest(me)
		set dockLib to script "core/dock"
		set dock to dockLib's new()
		if running of application "Terminal" then
			log "Closing Terminal windows and quitting the app"
			tell application "Terminal"
				if (count of windows) is not 0 then
					close windows
					delay 1
				end if	
			end tell
			dock's triggerAppMenu("Terminal", "Quit")
			delay 1
		end if
	end script
end script 


-- Don't change this test case if you are testing an external script
-- in the same folder as this test script! We load the script in a test case, because
-- this will work when all the tests in the current folder are run together using loadTestsFromFolder().
-- Besides, this will make sure that we are using the latest version of the script
-- to be tested even if we do not recompile this test script.
script |Load script - dec-terminal-prompt-omz|
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
			set terminalUtil to terminalUtilLib's new()
			set useCommandPasting of terminalUtil to true
		end try
		assertInstanceOf(script, sutScript) 
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
		-- TopLevel's terminalUtil's cdHome()  -- This is already the default behavior for the testing tab.
		ok(sut's isShellPrompt())
	end script

	script |With lingering command| 
		property parent : UnitTest(me)
		TopLevel's terminalUtil's typeCommand("extra")
		notOk(sut's isShellPrompt())
		TopLevel's terminalUtil's clearScreenAndCommands()
	end script

	script |Running command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's pasteCommand("tail -f ~/applescript-core/logs/applescript-core.log")
		TopLevel's terminalUtil's typeCommand(return)
		notOk(sut's isShellPrompt())
		TopLevel's terminalUtil's clearScreenAndCommands()
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
		assertEqual(TopLevel's DEFAULT_HOME_PROMPT, sut's getPrompt())
	end script

	script |Home dir with Command| 
		property parent : UnitTest(me)
		TopLevel's terminalUtil's typeCommand("linger")
		assertEqual(TopLevel's DEFAULT_HOME_PROMPT, sut's getPrompt()) 
		TopLevel's terminalUtil's clearScreenAndCommands()
	end script 

	script |Project dir without Command| 
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdAppleScriptProject()
		delay 1  -- Band-aid.
		assertEqual("➜  applescript-core git:(main) ✗", sut's getPrompt())
	end script 

	script |Project dir with Command| 
		property parent : UnitTest(me)
		-- TopLevel's terminalUtil's cdAppleScriptProject()
		TopLevel's terminalUtil's typeCommand("linger")
		assertEqual("➜  applescript-core git:(main) ✗", sut's getPrompt())
		TopLevel's terminalUtil's clearScreenAndCommands()
	end script
 
	script |Non-shell| 
		property parent : UnitTest(me)
		TopLevel's terminalUtil's pasteCommand("tail -f ~/applescript-core/logs/applescript-core.log")
		TopLevel's terminalUtil's typeCommand(return)
		assertMissing(sut's getPrompt())
		TopLevel's terminalUtil's clearScreenAndCommands()
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
		-- TopLevel's terminalUtil's clearScreenAndCommands()
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
 		assertEqual("➜  applescript-core git:(main) ✗", sut's getPromptText())
	end script 

	script |Home dir with Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's typeCommand("linger")
		assertEqual("➜  applescript-core git:(main) ✗ linger", sut's getPromptText())
		TopLevel's terminalUtil's clearScreenAndCommands()
	end script 

	script |Project dir without Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdAppleScriptProject()
		assertEqual("➜  applescript-core git:(main) ✗", sut's getPromptText())
	end script

	script |Project dir with Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's typeCommand("linger")
		assertEqual("➜  applescript-core git:(main) ✗ linger", sut's getPromptText())
		TopLevel's terminalUtil's clearScreenAndCommands()
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
		if my name is "afterClass" then afterClass()
		if my name is "afterSuite" then afterSuite()
	end tearDown

	on beforeClass()
		set terminalTab to TopLevel's terminalUtil's getTestingTab()
		set sut to sutScript's decorate(terminalTab)
		TopLevel's terminalUtil's cdHome() 
		TopLevel's terminalUtil's clearScreen()
	end beforeClass
	on afterClass()
	end afterClass
	on afterSuite()
		terminalTab's closeTab() 
		TopLevel's terminalUtil's quitTerminal()
	end afterClass

	script |With lingering command| 
		property parent : UnitTest(me)
		TopLevel's terminalUtil's typeCommand("linger") 
		assertEqual("linger", sut's getLastCommand())
	end script

	script |Home dir without Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdHome() 
		TopLevel's terminalUtil's clearScreen()
		assertMissing(sut's getLastCommand())
	end script

	script |Project dir without Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdAppleScriptProject()
		TopLevel's terminalUtil's clearScreen()
		assertMissing(sut's getLastCommand())
	end script

	script |Non-User dir without Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdScriptLibrary()
		TopLevel's terminalUtil's clearScreen()
		assertMissing(sut's getLastCommand())
	end script

	script |With previously executed and lingering command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's typeCommand("cd" & return)
		TopLevel's terminalUtil's typeCommand("ls" & return)
		assertEqual("ls", sut's getLastCommand())
	end script

	script |With previously executed cd command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's typeCommand("cd" & return)
		assertEqual("cd", sut's getLastCommand())
	end script

	script |With previously executed cd directory command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdScriptLibrary()
		assertEqual("cd ~/Library/Script\\ Libraries", sut's getLastCommand())
	end script

	script |afterSuite|
		property parent : UnitTest(me)
		ok(true)  -- dummy test to trigger the afterSuite.
	end script
end script


script |getLingeringCommand tests|
	property parent : TestSet(me)
	property executedTestCases : 0 
	property terminalTab : missing value
	property sut : missing value
	
	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
	end setUp
	on tearDown()
		if my name is "afterClass" then afterClass()
		if my name is "afterSuite" then afterSuite()
	end tearDown

	on beforeClass()
		set terminalTab to TopLevel's terminalUtil's getTestingTab()
		set sut to sutScript's decorate(terminalTab)
		TopLevel's terminalUtil's cdHome() 
		TopLevel's terminalUtil's clearScreen()
	end beforeClass
	on afterClass()
	end afterClass
	on afterSuite()
		terminalTab's closeTab() 
		TopLevel's terminalUtil's quitTerminal()
	end afterClass

	script |With running process| 
		property parent : UnitTest(me)
		TopLevel's terminalUtil's typeCommand("sleep 10" & return)
		assertMissing(sut's getLingeringCommand())
	end script

	script |With lingering command| 
		property parent : UnitTest(me)
		TopLevel's terminalUtil's typeCommand("linger") 
		assertEqual("linger", sut's getLingeringCommand())
	end script

	-- script |Home dir without Command|
	-- 	property parent : UnitTest(me)
	-- 	TopLevel's terminalUtil's cdHome() 
	-- 	TopLevel's terminalUtil's clearScreen()
	-- 	assertMissing(sut's getLingeringCommand())
	-- end script

	-- script |Project dir without Command|
	-- 	property parent : UnitTest(me)
	-- 	TopLevel's terminalUtil's cdAppleScriptProject()
	-- 	TopLevel's terminalUtil's clearScreen()
	-- 	assertMissing(sut's getLingeringCommand())
	-- end script

	-- script |Non-User dir without Command|
	-- 	property parent : UnitTest(me)
	-- 	TopLevel's terminalUtil's cdScriptLibrary()
	-- 	TopLevel's terminalUtil's clearScreen()
	-- 	assertMissing(sut's getLingeringCommand())
	-- end script

	-- script |With previously executed and lingering command|
	-- 	property parent : UnitTest(me)
	-- 	TopLevel's terminalUtil's typeCommand("cd" & return)
	-- 	TopLevel's terminalUtil's typeCommand("ls" & return)
	-- 	assertEqual("ls", sut's getLingeringCommand())
	-- end script

	-- script |With previously executed cd command|
	-- 	property parent : UnitTest(me)
	-- 	TopLevel's terminalUtil's typeCommand("cd" & return)
	-- 	assertEqual("cd", sut's getLingeringCommand())
	-- end script

	-- script |With previously executed cd directory command|
	-- 	property parent : UnitTest(me)
	-- 	TopLevel's terminalUtil's cdScriptLibrary()
	-- 	assertEqual("cd ~/Library/Script\\ Libraries", sut's getLingeringCommand())
	-- end script

	script |afterSuite|
		property parent : UnitTest(me)
		ok(true)  -- dummy test to trigger the afterSuite.
	end script
end script
