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
use omz : script "core/oh-my-zsh"

use loggerFactory : script "core/logger-factory"

use terminalUtilLib : script "core/test/terminal-util"
use usrLib : script "core/user"

property logger : missing value

property terminalUtil : missing value

property TopLevel : me
property suite : makeTestSuite(suitename)
property DEFAULT_HOME_PROMPT : omz's ARROW & "  ~"
property DEFAULT_TAIL_COMMAND : "tail -f ~/applescript-core/logs/applescript-core.log"
property DEFAULT_PROJECT_PROMPT_CLEAN : omz's ARROW & "  applescript-core git:(main)"
property DEFAULT_PROJECT_PROMPT_DIRTY : DEFAULT_PROJECT_PROMPT_CLEAN & " " & omz's GIT_X
(* Either clean or dirty. Usually dirty due to active development. *)
property DEFAULT_PROJECT_PROMPT_CURRENT : DEFAULT_PROJECT_PROMPT_DIRTY

loggerFactory's inject(me)
set terminalUtil to terminalUtilLib's new()
set useCommandPasting of terminalUtil to true
set autoFocusWindow of terminalUtil to true
autorun(suite)

---------------------------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------------------------

-- script |Start Suite - dec-terminal-prompt-omz|
-- 	property parent : TestSet(me)
-- 	script |Prepare Suite|
-- 		property parent : UnitTest(me)
-- 		set dockLib to script "core/dock"
-- 		set dock to dockLib's new()
-- 		if running of application "Terminal" then
-- 			log "Closing Terminal windows and quitting the app"
-- 			tell application "Terminal"
-- 				if (count of windows) is not 0 then
-- 					close windows
-- 					delay 1
-- 				end if	
-- 			end tell
-- 			dock's triggerAppMenu("Terminal", "Quit")
-- 			delay 1
-- 		end if
-- 	end script
-- end script 


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
		end try
		assertInstanceOf(script, sutScript)
	end script
end script


(*
	Copy-only. From dec-terminal-path.
*)
script |getDirectoryName tests|
	property parent : TestSet(me)
	property sut : missing value
	
	script |#beforeSuite|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's closeTestingTab()
	end script
	
	script |#beforeClass|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's getTestingTab()
		set my sut to sutScript's decorate(result)
	end script
	
	script |User path|
		property parent : UnitTest(me)
		-- TopLevel's terminalUtil's cdHome()
		assertEqual(std's getUsername(), my sut's getDirectoryName())
	end script
	
	script |Spaced Path|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdScriptLibrary()
		assertEqual("Script Libraries", my sut's getDirectoryName())
	end script
end script

script |getPromptText tests|
	property parent : TestSet(me)
	property sut : missing value
	
	on tearDown()
		-- TopLevel's terminalUtil's clearScreenAndCommands()
	end tearDown
	
	script |#beforeClass|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's getTestingTab()
		set my sut to sutScript's decorate(result)
	end script
	
	script |Home directory without Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdHome()
		assertEqual(omz's ARROW & "  ~", sut's getPromptText())
	end script
	
	script |Home directory with Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's taintPrompt()
		assertEqual(omz's ARROW & "  ~ linger", sut's getPromptText())
		TopLevel's terminalUtil's clearScreenAndCommands()
	end script
	
	script |Home directory with a tail command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's runCommand(DEFAULT_TAIL_COMMAND)
		assertEqual(omz's ARROW & "  ~ " & DEFAULT_TAIL_COMMAND, sut's getPromptText())
		TopLevel's terminalUtil's controlC()
		TopLevel's terminalUtil's clearScreenAndCommands()
	end script
	
	script |Project directory without Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdAppleScriptProject()
		assertEqual(DEFAULT_PROJECT_PROMPT_CURRENT, sut's getPromptText())
	end script
	
	script |Project directory with Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's taintPrompt()
		assertEqual(DEFAULT_PROJECT_PROMPT_DIRTY & " linger", sut's getPromptText())
		TopLevel's terminalUtil's clearScreenAndCommands()
	end script
end script


script |isShellPrompt tests|
	property parent : TestSet(me)
	property sut : missing value
	
	on setUp()
		TopLevel's terminalUtil's clearScreenAndCommands()
	end setUp
	
	script |#beforeClass|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's getTestingTab()
		set my sut to sutScript's decorate(result)
		
		TopLevel's terminalUtil's clearScreenAndCommands() -- Ensure clean state
	end script
	
	script |Initial state|
		property parent : UnitTest(me)
		-- TopLevel's terminalUtil's cdHome()  -- This is already the default behavior for the testing tab.
		ok(sut's isShellPrompt())
	end script
	
	script |With a lingering command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's typeCommand("extra")
		notOk(sut's isShellPrompt())
	end script
	
	script |with a running command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's runCommand(DEFAULT_TAIL_COMMAND)
		notOk(sut's isShellPrompt())
		TopLevel's terminalUtil's controlC()
	end script
end script

script |getPrompt tests|
	property parent : TestSet(me)
	property sut : missing value
	
	on setUp()
		TopLevel's terminalUtil's clearScreenAndCommands()
	end setUp
	
	script |#beforeClass|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's getTestingTab()
		set my sut to sutScript's decorate(result)
		TopLevel's terminalUtil's cdHome() -- This is already the default behavior for the testing tab.
	end script
	
	script |Home directory without Command|
		property parent : UnitTest(me)
		assertEqual(TopLevel's DEFAULT_HOME_PROMPT, sut's getPrompt())
	end script
	
	script |Home directory with Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's taintPrompt()
		-- assertMissing(sut's getPrompt()) 
		assertEqual(TopLevel's DEFAULT_HOME_PROMPT, sut's getPrompt())
	end script
	
	script |Project directory without Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdAppleScriptProject()
		assertEqual(DEFAULT_PROJECT_PROMPT_CURRENT, sut's getPrompt())
	end script
	
	script |Project directory with Command|
		property parent : UnitTest(me)
		-- TopLevel's terminalUtil's cdAppleScriptProject()
		TopLevel's terminalUtil's taintPrompt()
		-- assertMissing(sut's getPrompt())
		assertEqual(DEFAULT_PROJECT_PROMPT_CURRENT, sut's getPrompt())
	end script
	
	script |Non-shell with Prompt Visible|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's runCommand(DEFAULT_TAIL_COMMAND)
		-- assertMissing(DEFAULT_PROJECT_PROMPT_DIRTY)
		assertEqual(DEFAULT_PROJECT_PROMPT_CURRENT, sut's getPrompt())
	end script
	
	script |Non-shell with Prompt Invisible|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's runCommand(DEFAULT_TAIL_COMMAND)
		TopLevel's terminalUtil's clearScreen()
		assertMissing(sut's getPrompt())
		TopLevel's terminalUtil's controlC()
	end script
end script

script |getLastCommand tests|
	property parent : TestSet(me)
	property sut : missing value
	
	script |#beforeClass|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's getTestingTab()
		set my sut to sutScript's decorate(result)
		TopLevel's terminalUtil's cdHome()
		TopLevel's terminalUtil's clearScreen()
	end script
		
	script |With lingering command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's taintPrompt()
		assertEqual("linger", sut's getLastCommand())
		TopLevel's terminalUtil's clearCommands()
	end script
	
	script |Home directory without Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdHome()
		TopLevel's terminalUtil's clearScreen()
		assertMissing(sut's getLastCommand())
	end script
	
	script |Project directory without Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdAppleScriptProject()
		TopLevel's terminalUtil's clearScreen()
		assertMissing(sut's getLastCommand())
	end script
	
	script |Non-User directory without Command|
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
end script

script |getLingeringCommand tests|
	property parent : TestSet(me)
	property sut : missing value
	
	script |#beforeClass|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's getTestingTab()
		set my sut to sutScript's decorate(result)
		TopLevel's terminalUtil's cdHome()
		TopLevel's terminalUtil's clearScreen()
	end script
	
	-- 	on beforeClass()
	-- 		set terminalTab to TopLevel's terminalUtil's getTestingTab()
	-- 		set sut to sutScript's decorate(terminalTab)
	-- 		TopLevel's terminalUtil's cdHome() 
	-- 		TopLevel's terminalUtil's clearScreen()
	-- 	end beforeClass
	-- 	on afterClass()
	-- 	end afterClass
	-- 	on afterSuite()
	-- 		terminalTab's closeTab() 
	-- 		TopLevel's terminalUtil's quitTerminal()
	-- 	end afterClass
	
	-- script |With running process| 
	-- 	property parent : UnitTest(me)
	-- 	TopLevel's terminalUtil's runCommand("sleep 10")
	-- 	assertMissing(sut's getLingeringCommand())
	-- end script
	
	script |With lingering command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's taintPrompt()
		assertEqual("linger", sut's getLingeringCommand())
	end script
	
	script |Home directory without Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdHome()
		TopLevel's terminalUtil's clearScreen()
		assertMissing(sut's getLingeringCommand())
	end script
	
	script |Project directory without Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdAppleScriptProject()
		TopLevel's terminalUtil's clearScreen()
		assertMissing(sut's getLingeringCommand())
	end script
	
	script |Non-User directory without Command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdScriptLibrary()
		TopLevel's terminalUtil's clearScreen()
		assertMissing(sut's getLingeringCommand())
	end script
	
	script |With previously executed and lingering command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's runCommand("cd")
		TopLevel's terminalUtil's typeCommand("ls")
		assertEqual("ls", sut's getLingeringCommand())
	end script
	
	script |With previously executed cd command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's runCommand("cd")
		assertMissing(sut's getLingeringCommand())
	end script
	
	script |With previously executed cd directory command|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's cdScriptLibrary()
		assertMissing(sut's getLingeringCommand())
	end script
	
	script |#afterSuite|
		property parent : UnitTest(me)
		TopLevel's terminalUtil's closeTestingTab()
	end script
end script
