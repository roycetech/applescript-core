(*!
	@header
	@abstract
		A template for unit testing.
	@discussion
		Copy this template in the folder containing the script to be tested and customize it as follows:
	
		1) Provide a description for this test suite and the name of the script to be tested.
		2) Write tests :)

	@WARNING:
		This will close all Terminal tabs.

	@Known Issues: 

	@charset macintosh
	@Created: Tuesday, May 21, 2024 at 10:07:02 AM
*)
use AppleScript
use scripting additions

property parent : script "com.lifepillar/ASUnit"
---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "terminal" -- The name of the script to be tested
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use std : script "core/std"
use textUtil : script "core/string"
use loggerFactory : script "core/logger-factory"
use dockLib : script "core/dock"
use terminalUtilLib : script "core/test/terminal-util"

property logger : missing value
property terminalUtil : missing value
property dock : missing value

property TAB_NAME_MISSING : "Unicorn"
property TAB_NAME_PRESENT : "existing"
property TAB_NAME_SUB : "case@local@tab"
property TAB_NAME_SUB_ENDING : "local@tab"
property TAB_NAME_SUB_MID : "@local@"

property TopLevel : me
property suite : makeTestSuite(suitename)

loggerFactory's inject(me)
set terminalUtil to terminalUtilLib's new()
set dock to dockLib's new()
autorun(suite)

---------------------------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------------------------

-- Don't change this test case if you are testing an external script
-- in the same folder as this test script! We load the script in a test case, because
-- this will work when all the tests in the current folder are run together using loadTestsFromFolder().
-- Besides, this will make sure that we are using the latest version of the script
-- to be tested even if we do not recompile this test script.
script |Load script - terminal|
	property parent : TestSet(me)
	script |Loading the script|
		property parent : unitTest(me)
		try
			tell application "Finder"
				set deploymentPath to ((path to library folder from user domain) as text) & "Script Libraries:core:"
			end tell
			set sutScript to load script (deploymentPath & scriptName & ".scpt") as alias
			set terminalUtil to terminalUtilLib's new()
			set dock to dockLib's new()
		end try
		assertInstanceOf(script, sutScript)
	end script
end script

(*
	newWindow
*)
 
script |findTabWithTitle tests|
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
		set sut to sutScript's new()
	end beforeClass
	on afterClass()
		terminalTab's closeTab()
	end afterClass
	on afterSuite()
		if terminalTab is not missing value then -- Noise reduction
			terminalTab's closeTab()
		end if
		TopLevel's terminalUtil's quitTerminal()
	end afterSuite
	
	script |Single Window - Not Found|
		property parent : unitTest(me)
		assertMissing(sut's findTabWithTitle(TopLevel's TAB_NAME_MISSING))
	end script 
	
	script |Single Window - Found|
		property parent : unitTest(me)
		refuteMissing(sut's findTabWithTitle(TopLevel's terminalUtil's TEST_TAB_NAME))
	end script
	
	script |Tabbed - Not Found| 
		property parent : UnitTest(me) 
		set localTab to terminalTab's newTab(TopLevel's TAB_NAME_SUB)
		assertMissing(sut's findTabWithTitle(TopLevel's TAB_NAME_MISSING)) 
		localTab's closeTab()
	end script

	script |Tabbed Focused - Found| 
		property parent : UnitTest(me) 
		set localTab to terminalTab's newTab(TopLevel's TAB_NAME_SUB)
		refuteMissing(sut's findTabWithTitle(TopLevel's TAB_NAME_SUB))
		localTab's closeTab() 
	end script 

	script |Tabbed Unfocused - Found|  
		property parent : UnitTest(me) 
		set localTab to terminalTab's newTab(TopLevel's TAB_NAME_SUB)
		refuteMissing(sut's findTabWithTitle(TopLevel's terminalUtil's TEST_TAB_NAME))
		localTab's closeTab()
	end script
	
	script |Without window| 
		property parent : UnitTest(me) 
		terminalTab's closeTab()
		TopLevel's terminalUtil's waitWindowCount(0)
		assertMissing(sut's findTabWithTitle(terminalUtil's TEST_TAB_NAME))
	end script
	
	script |Not Running| 
		property parent : UnitTest(me)  
		TopLevel's terminalUtil's quitTerminal() 
		assertMissing(sut's findTabWithTitle(terminalUtil's TEST_TAB_NAME))
	end script
	
	-- script |afterSuite|
	-- 	property parent : unitTest(me)
	-- 	ok(true) -- dummy test to trigger the afterSuite.
	-- end script
end script


script |findTabWithNameContaining tests|
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
		set sut to sutScript's new()
	end beforeClass
	on afterClass()
		terminalTab's closeTab()
	end afterClass
	on afterSuite()
		if terminalTab is not missing value then -- Noise reduction
			terminalTab's closeTab()
		end if
		TopLevel's terminalUtil's quitTerminal()
	end afterSuite
	
	script |Single Window - Not Found|
		property parent : unitTest(me)
		assertMissing(sut's findTabWithNameContaining(TopLevel's TAB_NAME_MISSING))
	end script 
	
	script |Single Window - Found|
		property parent : unitTest(me)
		refuteMissing(sut's findTabWithNameContaining(TopLevel's terminalUtil's TEST_TAB_MID_WORD))
	end script
	
	script |Tabbed - Not Found| 
		property parent : UnitTest(me) 
		set localTab to terminalTab's newTab(TopLevel's TAB_NAME_SUB)
		assertMissing(sut's findTabWithNameContaining(TopLevel's TAB_NAME_MISSING)) 
		localTab's closeTab()
	end script

	script |Tabbed Focused - Found| 
		property parent : UnitTest(me) 
		set localTab to terminalTab's newTab(TopLevel's TAB_NAME_SUB)
		refuteMissing(sut's findTabWithNameContaining(TopLevel's TAB_NAME_SUB_MID))
		localTab's closeTab() 
	end script

	script |Tabbed Unfocused - Found|  
		property parent : UnitTest(me) 
		set localTab to terminalTab's newTab(TopLevel's TAB_NAME_SUB)
		refuteMissing(sut's findTabWithNameContaining(TopLevel's terminalUtil's TEST_TAB_MID_WORD))
		localTab's closeTab()
	end script
	
	script |Without window| 
		property parent : UnitTest(me) 
		terminalTab's closeTab()
		TopLevel's terminalUtil's waitWindowCount(0)
		assertMissing(sut's findTabWithNameContaining(terminalUtil's TEST_TAB_MID_WORD))
	end script
	
	script |Not Running| 
		property parent : UnitTest(me)  
		TopLevel's terminalUtil's quitTerminal() 
		assertMissing(sut's findTabWithNameContaining(terminalUtil's TEST_TAB_MID_WORD))
	end script	
end script


script |findTabEndingWith tests|
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
		set sut to sutScript's new()
	end beforeClass
	on afterClass()
		terminalTab's closeTab()
	end afterClass
	on afterSuite()
		if terminalTab is not missing value then -- Noise reduction
			terminalTab's closeTab()
		end if
		TopLevel's terminalUtil's quitTerminal()
	end afterSuite
	
	script |Single Window - Not Found|
		property parent : unitTest(me)
		assertMissing(sut's findTabEndingWith(TopLevel's TAB_NAME_MISSING))
	end script
	
	script |Single Window - Found|
		property parent : unitTest(me)
		refuteMissing(sut's findTabEndingWith(TopLevel's terminalUtil's TEST_TAB_ENDING_WORD))
	end script
	
	script |Tabbed - Not Found| 
		property parent : UnitTest(me) 
		set localTab to terminalTab's newTab(TopLevel's TAB_NAME_SUB)
		assertMissing(sut's findTabEndingWith(TopLevel's TAB_NAME_MISSING)) 
		localTab's closeTab()
	end script

	script |Tabbed Focused - Found| 
		property parent : UnitTest(me) 
		set localTab to terminalTab's newTab(TopLevel's TAB_NAME_SUB)
		refuteMissing(sut's findTabEndingWith(TopLevel's TAB_NAME_SUB_ENDING))
		localTab's closeTab() 
	end script

	script |Tabbed Unfocused - Found|  
		property parent : UnitTest(me) 
		set localTab to terminalTab's newTab(TopLevel's TAB_NAME_SUB)
		refuteMissing(sut's findTabEndingWith(TopLevel's terminalUtil's TEST_TAB_ENDING_WORD))
		localTab's closeTab()
	end script
	
	script |Without window| 
		property parent : UnitTest(me) 
		terminalTab's closeTab()
		TopLevel's terminalUtil's waitWindowCount(0)
		assertMissing(sut's findTabEndingWith(terminalUtil's TEST_TAB_ENDING_WORD))
	end script
	
	script |Not Running| 
		property parent : UnitTest(me)  
		TopLevel's terminalUtil's quitTerminal() 
		assertMissing(sut's findTabEndingWith(terminalUtil's TEST_TAB_ENDING_WORD))
	end script	
end script


script |hasTabBar tests|
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
		set sut to sutScript's new()
	end beforeClass
	on afterClass()
		terminalTab's closeTab() 
	end afterClass
	on afterSuite()
		if terminalTab is not missing value then -- Noise reduction
			terminalTab's closeTab()
		end if
		TopLevel's terminalUtil's quitTerminal()
	end afterSuite 

	script |Single Window| 
		property parent : UnitTest(me) 
		notOk(sut's hasTabBar())
	end script

	script |Tabbed| 
		property parent : UnitTest(me) 
		set localTab to terminalTab's newTab("local")
		ok(sut's hasTabBar())
		localTab's closeTab()
	end script

	script |Without window| 
		property parent : UnitTest(me) 
		terminalTab's closeTab()
		TopLevel's terminalUtil's waitWindowCount(0)
		notOk(sut's hasTabBar())
	end script

	script |Not Running| 
		property parent : UnitTest(me)  
		TopLevel's terminalUtil's quitTerminal() 
		notOk(sut's hasTabBar())
	end script
end script


script |getFrontTab tests|
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
		set sut to sutScript's new()
	end beforeClass
	on afterClass()
		terminalTab's closeTab() 
	end afterClass
	on afterSuite()
		if terminalTab is not missing value then -- Noise reduction
			terminalTab's closeTab()
		end if
		TopLevel's terminalUtil's quitTerminal()
	end afterSuite 

	script |Normal case| 
		property parent : UnitTest(me) 
		refuteMissing(sut's getFrontTab())
	end script

	script |Without window| 
		property parent : UnitTest(me) 
		terminalTab's closeTab()
		TopLevel's terminalUtil's waitWindowCount(0)
		assertMissing(sut's getFrontTab())
	end script

	script |Not Running| 
		property parent : UnitTest(me)  
		TopLevel's terminalUtil's quitTerminal() 
		assertMissing(sut's getFrontTab())
	end script

	-- script |afterSuite|
	-- 	property parent : unitTest(me)
	-- 	ok(true) -- dummy test to trigger the afterSuite.
	-- end script
end script
