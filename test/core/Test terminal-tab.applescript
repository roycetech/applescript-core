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
	@Created: Friday, May 17, 2024 at 3:26:46 PM
*)
use AppleScript
use scripting additions

property parent : script "com.lifepillar/ASUnit"
---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "terminal-tab" -- The name of the script to be tested
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

property TopLevel : me
property suite : makeTestSuite(suitename)

property TAB_NAME_TEST_CASE : "test@case@tab"
property TITLE_NEW_WINDOW : "new-window-title"
property TITLE_NEW_TAB : "new-tab-title"

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
script |Load script - terminal-tab|
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


script |clearLingeringCommand tests|
	property parent : TestSet(me)
	property executedTestCases : 0 
	property terminalTab : missing value
	
	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()		
	end setUp
	on tearDown()
		if my name is "afterClass" then afterClass()
		-- if my name is "afterSuite" then afterSuite() 
	end tearDown
 
	on beforeClass()
		set terminalTab to TopLevel's terminalUtil's getTestingTab()
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

	script |None| 
		property parent : UnitTest(me)
		set beforeTrimmedContent to TopLevel's terminalUtil's getTrimmedContent()
		terminalTab's clearLingeringCommand()
		delay 1
		assertEqual(beforeTrimmedContent, TopLevel's terminalUtil's getTrimmedContent())		
	end script

	script |With Lingering Command| 
		property parent : UnitTest(me)
		set initialTrimmedContent to TopLevel's terminalUtil's getTrimmedContent()
		set someCommand to "typed text"
		TopLevel's terminalUtil's typeCommand(someCommand)
		set typedTrimmedContent to TopLevel's terminalUtil's getTrimmedContent()
		terminalTab's clearLingeringCommand()
		delay 1
		set clearedTrimmedContent to TopLevel's terminalUtil's getTrimmedContent()
		ok(typedTrimmedContent ends with someCommand)		
		assertEqual(initialTrimmedContent, clearedTrimmedContent)
	end script

	-- script |afterSuite|
	-- 	property parent : unitTest(me)
	-- 	ok(true) -- dummy test to trigger the afterSuite.
	-- end script
end script

script |getLingeringCommand tests|
	property parent : TestSet(me)
	property executedTestCases : 0 
	property terminalTab : missing value
	
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

	script |None| 
		property parent : UnitTest(me)
		assertMissing(terminalTab's getLingeringCommand())
	end script

	script |With Lingering Command| 
		property parent : UnitTest(me)
		set someCommand to "typed text"
		TopLevel's terminalUtil's typeCommand(someCommand)
		assertEqual(someCommand, terminalTab's getLingeringCommand())
		TopLevel's terminalUtil's clearScreenAndCommands()
	end script

	-- script |afterSuite|
	-- 	property parent : unitTest(me)
	-- 	ok(true) -- dummy test to trigger the afterSuite.
	-- end script
end script


script |scrollToTop tests|
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
	end beforeClass
	on afterClass()
		terminalTab's closeTab()
	end afterClass
	on afterSuite()
		if terminalTab is not missing value then -- Noise reduction
			log 1
			terminalTab's closeTab()
		else
			log 2
		end if
		log 3
		TopLevel's terminalUtil's quitTerminal()
	end afterSuite
	
	script |Basic| 
		property parent : UnitTest(me)
		TopLevel's terminalUtil's stretchScrollPane()		
		terminalTab's scrollToTop()
		tell application "System Events" to tell process "Terminal"
			set actual to value of scroll bar 1 of scroll area 1 of splitter group 1 of front window
		end tell
		assertEqual(0.0, actual)
	end script

	script |afterClass|
		property parent : UnitTest(me)
		ok(true)  -- dummy test to trigger the afterClass.
	end script

	-- script |afterSuite|
	-- 	property parent : unitTest(me)
	-- 	ok(true) -- dummy test to trigger the afterSuite.
	-- end script
end script


script |scrollToBottom tests|
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
	end beforeClass
	on afterClass()
		terminalTab's closeTab()
	end afterClass
	
	script |Basic| 
		property parent : UnitTest(me)
		TopLevel's terminalUtil's stretchScrollPane()
		tell application "System Events" to tell process "Terminal"
			set value of scroll bar 1 of scroll area 1 of splitter group 1 of front window to 0.0
		end tell
		terminalTab's scrollToBottom()
		tell application "System Events" to tell process "Terminal"
			set actual to value of scroll bar 1 of scroll area 1 of splitter group 1 of front window
		end tell
		assertEqual(1.0, actual)
	end script

	script |afterClass|
		property parent : UnitTest(me)
		ok(true)  -- dummy test to trigger the afterSuite.
	end script	
end script


script |newWindow tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property terminalTab : missing value
	
	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
	end setUp
	on tearDown()
		if my name is "afterClass" then afterClass()
		if my name is "afterSuite" then afterSuite()
	end tearDown
	
	(* 
		WARNING: Fails when Terminal is running and there are no windows. 
		This is the consequence of the quit command, avoid it.
	*)
	on beforeClass()
		-- log "beforeClass start"
		if running of application "Terminal" then
			tell application "System Events" to tell process "Terminal"
				set initialWindowCount to count of windows
				if initialWindowCount is not equal to 0 then
					try
						click (first button of windows whose description is "close button")
					end try
				end if
			end tell
			
			(*
			-- Below is not recommended due to side effects resulting in error.
			tell application "Terminal"
			 	quit
			end tell
			*)
		end if
		
		-- log "Getting test tab..."
		set terminalTab to TopLevel's terminalUtil's getTestingTab()
		if terminalTab is missing value then
			error "Testing Tab failed to initialize"
		else
			-- log "Testing Tab cleared for take off"
		end if
		-- log "end of beforeClass"
	end beforeClass
	on afterClass()
		if terminalTab is not missing value then -- Noise reduction
			terminalTab's closeTab()
		end if
		log "Ensuring correct windows count (should only take a few seconds)..."
		if not TopLevel's terminalUtil's waitWindowCount(0) then
			tell application "Terminal" to close windows
			error "limit reached, aborting..."
		end if
	end afterClass
	
	(*
		Manual Step: Terminal must not be running. Programmatically quitting results in errors.
	*)
	script |Terminal is not running|
		property parent : unitTest(me)
		
		set localTab to terminalTab's newWindow(missing value, TopLevel's TAB_NAME_TEST_CASE)
		tell application "System Events" to tell process "Terminal"
			set windowCount to count of windows
		end tell
		assertEqual(2, windowCount)
		tell application "System Events" to tell process "Terminal"
			set correctlyNamedWindowCount to count of (windows whose title contains TopLevel's TAB_NAME_TEST_CASE)
		end tell
		assertEqual(1, correctlyNamedWindowCount)
		localTab's closeTab()
	end script
	
	script |Terminal is running|
		property parent : unitTest(me)
		set localTab to terminalTab's newWindow(missing value, TopLevel's TAB_NAME_TEST_CASE)
		tell application "System Events" to tell process "Terminal"
			set windowCount to count of windows
		end tell
		assertEqual(2, windowCount)
		tell application "System Events" to tell process "Terminal"
			set correctlyNamedWindowCount to count of (windows whose title contains TopLevel's TAB_NAME_TEST_CASE)
		end tell
		assertEqual(1, correctlyNamedWindowCount)
		localTab's closeTab()
	end script
	
	script |afterClass|
		property parent : unitTest(me)
		ok(true) -- dummy test to trigger the afterSuite.
	end script
end script 
 

script |newTab tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property terminalTab : missing value
	property caseTab : missing value
	
	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
	end setUp
	on tearDown()
		-- if terminalTab is not missing value then terminalTab's closeTab()
		-- if caseTab is not missing value then caseTab's closeTab()
		
		-- TopLevel's terminalUtil's clearScreenAndCommands()
		if my name is "afterClass" then afterClass()
		if my name is "afterSuite" then afterSuite()
	end tearDown
	
	(* 
		WARNING: Fails when Terminal is running and there are no windows. 
		This is the consequence of the quit command, avoid it.
	*)
	on beforeClass()
		-- log "beforeClass start"
		if running of application "Terminal" then
			tell application "System Events" to tell process "Terminal"
				set initialWindowCount to count of windows
				if initialWindowCount is not equal to 0 then
					try
						click (first button of windows whose description is "close button")
					end try
				end if
			end tell
			
			(*
			-- Below is not recommended due to side effects resulting in error.
			tell application "Terminal"
			 	quit
			end tell
			*)
		end if
		
		-- log "Getting test tab..."
		set terminalTab to TopLevel's terminalUtil's getTestingTab()
		if terminalTab is missing value then
			error "Testing Tab failed to initialize"
		else
			-- log "Testing Tab cleared for take off"
		end if
		-- log "end of beforeClass"
	end beforeClass
	
	script |Terminal is running|
		property parent : unitTest(me)
		set caseTab to terminalTab's newTab(TopLevel's TAB_NAME_TEST_CASE)
		tell application "Terminal"
			set appWindowCount to count of windows
		end tell
		assertEqual(2, appWindowCount)
		tell application "System Events" to tell process "Terminal"
			set systemEventWindowCount to count of windows
		end tell
		assertEqual(1, systemEventWindowCount)
		tell application "Terminal"
			set correctlyNamedWindowCount to count of (windows whose name contains TopLevel's TAB_NAME_TEST_CASE)
		end tell
		assertEqual(1, correctlyNamedWindowCount)
		tell application "System Events" to tell process "Terminal"
			set frontWindowTitle to title of front window
		end tell
		ok(frontWindowTitle contains TopLevel's TAB_NAME_TEST_CASE)
	end script
end script


script |getProfile tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property terminalTab : missing value
	property caseTab : missing value
	
	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
	end setUp
	on tearDown()
		if my name is "afterClass" then afterClass()
		if my name is "afterSuite" then afterSuite()
	end tearDown
	
	on beforeClass()
		if running of application "Terminal" then
			tell application "System Events" to tell process "Terminal"
				set initialWindowCount to count of windows
				if initialWindowCount is not equal to 0 then
					try
						click (first button of windows whose description is "close button")
					end try
				end if
			end tell
		end if
		
		set terminalTab to TopLevel's terminalUtil's getTestingTab()
		if terminalTab is missing value then
			error "Testing Tab failed to initialize"
		end if
	end beforeClass
	on afterSuite()
		if terminalTab is not missing value then -- Noise reduction
			terminalTab's closeTab()
		end if
		do shell script "pkill Terminal" -- This is fine, "quit" is not.
	end afterSuite
	
	script |Default Profile|
		property parent : unitTest(me)
		set tabProfile to terminalTab's getProfile()

		assertEqual(TopLevel's terminalUtil's getDefaultProfile(), tabProfile)
	end script
	
	script |Other Profile|
		property parent : unitTest(me)
		tell application "Terminal"
			set current settings of selected tab of front window to settings set "Ocean"
		end tell
		set defaultProfile to terminalTab's getProfile()
		assertEqual("Ocean", defaultProfile)
	end script
end script


script |setProfile tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property terminalTab : missing value
	property caseTab : missing value
	
	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
	end setUp
	on tearDown()
		if my name is "afterClass" then afterClass()
		if my name is "afterSuite" then afterSuite()
	end tearDown
	
	on beforeClass()
		if running of application "Terminal" then
			tell application "System Events" to tell process "Terminal"
				set initialWindowCount to count of windows
				if initialWindowCount is not equal to 0 then
					try
						click (first button of windows whose description is "close button")
					end try
				end if
			end tell
		end if
		
		set terminalTab to TopLevel's terminalUtil's getTestingTab()
		if terminalTab is missing value then
			error "Testing Tab failed to initialize"
		end if
	end beforeClass
	on afterSuite()
		if terminalTab is not missing value then -- Noise reduction
			terminalTab's closeTab()
		end if
		do shell script "pkill Terminal" -- This is fine, "quit" is not.
	end afterSuite
	
	script |Basic|
		property parent : unitTest(me)
		terminalTab's setProfile("Grass")
		tell application "Terminal"
			set currentProfile to the name of current settings of selected tab of front window
		end tell
		assertEqual("Grass", currentProfile)
	end script
end script


script |focus tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property terminalTab : missing value
	property caseTab : missing value
	
	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
	end setUp
	on tearDown()
		if my name is "afterClass" then afterClass()
		if my name is "afterSuite" then afterSuite()
	end tearDown
	
	on beforeClass()
		if running of application "Terminal" then
			tell application "System Events" to tell process "Terminal"
				set initialWindowCount to count of windows
				if initialWindowCount is not equal to 0 then
					try
						click (first button of windows whose description is "close button")
					end try
				end if
			end tell
		end if
		
		set terminalTab to TopLevel's terminalUtil's getTestingTab()
		if terminalTab is missing value then
			error "Testing Tab failed to initialize"
		end if
	end beforeClass
	
	script |Another App|
		property parent : unitTest(me)
		dock's clickApp("Finder")
		tell application "System Events"
			set frontApp to first application process whose frontmost is true
			set frontAppName to name of frontApp
		end tell
		assertEqual("Finder", frontAppName)
		terminalTab's focus() -- Execute
		tell application "System Events"
			set frontApp to first application process whose frontmost is true
			set frontAppName to name of frontApp
		end tell
		assertEqual("Terminal", frontAppName)
		tell application "Finder"
			close windows
		end tell
	end script
	
	script |Another Tab|
		property parent : unitTest(me)
		set localTab to terminalTab's newTab(TopLevel's TAB_NAME_TEST_CASE)
		terminalTab's focus() -- Execute		
		ok(TopLevel's terminalUtil's getFrontWindowTitle() contains TopLevel's terminalUtil's TEST_TAB_NAME)
		localTab's closeTab()
	end script
end script


script |getWindowTitle tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property terminalTab : missing value
	
	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
	end setUp
	on tearDown()
		if my name is "afterClass" then afterClass()
		if my name is "afterSuite" then afterSuite()
	end tearDown
	
	on beforeClass()
		if running of application "Terminal" then
			tell application "System Events" to tell process "Terminal"
				set initialWindowCount to count of windows
				if initialWindowCount is not equal to 0 then
					try
						click (first button of windows whose description is "close button")
					end try
				end if
			end tell
		end if

		set terminalTab to TopLevel's terminalUtil's getTestingTab()
		if terminalTab is missing value then
			error "Testing Tab failed to initialize"
		end if
	end beforeClass
	on afterSuite()
		if terminalTab is not missing value then -- Noise reduction
			terminalTab's closeTab()
		end if
		do shell script "pkill Terminal" -- This is fine, "quit" is not.
	end afterSuite
	
	script |No tab single window|
		property parent : unitTest(me)
		assertEqual(TopLevel's terminalUtil's TEST_TAB_NAME, terminalTab's getWindowTitle()) -- Execute
	end script

	script |Multiple Tabs|
		property parent : unitTest(me)
		set caseTab to terminalTab's newTab(TopLevel's TAB_NAME_TEST_CASE)
		assertEqual(TopLevel's terminalUtil's TEST_TAB_NAME, terminalTab's getWindowTitle()) -- Execute
		assertEqual(TopLevel's TAB_NAME_TEST_CASE, caseTab's getWindowTitle())
		caseTab's closeTab()
	end script	
end script


script |getTabTitle tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property terminalTab : missing value
	
	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
	end setUp
	on tearDown()
		if my name is "afterClass" then afterClass()
		if my name is "afterSuite" then afterSuite()
	end tearDown

	on beforeClass()
		if running of application "Terminal" then
			tell application "System Events" to tell process "Terminal"
				set initialWindowCount to count of windows
				if initialWindowCount is not equal to 0 then
					try
						click (first button of windows whose description is "close button")
					end try
				end if
			end tell
		end if

		set terminalTab to TopLevel's terminalUtil's getTestingTab()
		if terminalTab is missing value then
			error "Testing Tab failed to initialize"
		end if
	end beforeClass

	script |No tab single window|
		property parent : unitTest(me)
		assertEqual("", terminalTab's getTabTitle())
	end script

	script |Multiple Tabs|
		property parent : unitTest(me)
		set caseTab to terminalTab's newTab(TopLevel's TAB_NAME_TEST_CASE)
		ok(terminalTab's getTabTitle() contains TopLevel's terminalUtil's TEST_TAB_NAME)
		ok(caseTab's getTabTitle() contains TopLevel's TAB_NAME_TEST_CASE)
		caseTab's closeTab()
	end script
end script


script |setWindowTitle tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property terminalTab : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
	end setUp
	on tearDown()
		if my name is "afterClass" then afterClass()
		if my name is "afterSuite" then afterSuite()
	end tearDown

	on beforeClass()
		if running of application "Terminal" then
			tell application "System Events" to tell process "Terminal"
				set initialWindowCount to count of windows
				if initialWindowCount is not equal to 0 then
					try
						click (first button of windows whose description is "close button")
					end try
				end if
			end tell
		end if

		set terminalTab to TopLevel's terminalUtil's getTestingTab()
		if terminalTab is missing value then
			error "Testing Tab failed to initialize"
		end if
	end beforeClass

	script |No tab single window|
		property parent : unitTest(me)
		terminalTab's setWindowTitle("new-win-title")
		tell application "Terminal"
			set customTitle to the custom title of selected tab of front window
		end tell
		assertEqual("new-win-title", customTitle)
	end script

	script |Multiple Tabs - Focused Tab|
		property parent : unitTest(me)
		set caseTab to terminalTab's newTab(TopLevel's TAB_NAME_TEST_CASE)
		caseTab's setWindowTitle(TopLevel's TITLE_NEW_WINDOW)
		tell application "Terminal"
			set customTitle to the custom title of selected tab of front window
		end tell
		assertEqual(TopLevel's TITLE_NEW_WINDOW, customTitle)
		caseTab's closeTab()
	end script

	script |Multiple Tabs - Unfocused Tab|
		property parent : unitTest(me)
		set caseTab to terminalTab's newTab(TopLevel's TAB_NAME_TEST_CASE)
		terminalTab's setWindowTitle(TopLevel's TITLE_NEW_WINDOW)
		tell application "Terminal"
			set modifiedCount to number of items in (tab of windows whose custom title is equal to TopLevel's TITLE_NEW_WINDOW)
			set unmodifiedCount to number of items in (tab of windows whose custom title is equal to TopLevel's TAB_NAME_TEST_CASE)
		end tell
		assertEqual(1, modifiedCount)
		assertEqual(1, unmodifiedCount)
		caseTab's closeTab()
	end script
end script


script |setTabTitle tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property terminalTab : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
	end setUp
	on tearDown()
		if my name is "afterClass" then afterClass()
		if my name is "afterSuite" then afterSuite()
	end tearDown

	on beforeClass()
		if running of application "Terminal" then
			tell application "System Events" to tell process "Terminal"
				set initialWindowCount to count of windows
				if initialWindowCount is not equal to 0 then
					try
						click (first button of windows whose description is "close button")
					end try
				end if
			end tell
		end if

		set terminalTab to TopLevel's terminalUtil's getTestingTab()
		if terminalTab is missing value then
			error "Testing Tab failed to initialize"
		end if
	end beforeClass

	script |No tab single window|
		property parent : unitTest(me)
		terminalTab's setTabTitle(TopLevel's TITLE_NEW_TAB)
		ok(TopLevel's terminalUtil's getFrontWindowTitle() contains TopLevel's TITLE_NEW_TAB)
	end script

	script |Multiple Tabs - Focused Tab|
		property parent : unitTest(me)
		set caseTab to terminalTab's newTab(TopLevel's TAB_NAME_TEST_CASE)
		caseTab's setTabTitle(TopLevel's TITLE_NEW_TAB)  -- Execute
		tell application "System Events" to tell process "Terminal"
			set tab2Title to title of radio button 2 of tab group "tab bar" of front window
		end tell
		assertEqual(TopLevel's TITLE_NEW_TAB, tab2Title)
		caseTab's closeTab()
	end script

	script |Multiple Tabs - Unfocused Tab|
		property parent : unitTest(me)
		set caseTab to terminalTab's newTab(TopLevel's TAB_NAME_TEST_CASE)
		terminalTab's setTabTitle(TopLevel's TITLE_NEW_TAB)
		tell application "System Events" to tell process "Terminal"
			set tab1Title to title of radio button 1 of tab group "tab bar" of front window
		end tell
		assertEqual(TopLevel's TITLE_NEW_TAB, tab1Title)
		caseTab's closeTab()
	end script
end script


(*
*)
script |closeTab tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property terminalTab : missing value

	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
	end setUp
	on tearDown()
		if my name is "afterClass" then afterClass()
		if my name is "afterSuite" then afterSuite()
	end tearDown

	on beforeClass()
		if running of application "Terminal" then
			tell application "System Events" to tell process "Terminal"
				set initialWindowCount to count of windows
				if initialWindowCount is not equal to 0 then
					try
						click (first button of windows whose description is "close button")
					end try
				end if
			end tell
		end if

		set terminalTab to TopLevel's terminalUtil's getTestingTab()
		if terminalTab is missing value then
			error "Testing Tab failed to initialize"
		end if
	end beforeClass
	on afterClass()
	end afterClass
	on afterSuite()
		if terminalTab is not missing value then -- Noise reduction
			terminalTab's closeTab()
		end if
		TopLevel's terminalUtil's quitTerminal()
	end afterSuite

	script |No tab single window|
		property parent : unitTest(me)
		ok(TopLevel's terminalUtil's waitWindowCount(1))
		terminalTab's closeTab()  -- execute
		ok(TopLevel's terminalUtil's waitWindowCount(0))
		set terminalTab to TopLevel's terminalUtil's getTestingTab()  -- reset closed tab.
	end script

	script |Multiple Tabs|
		property parent : unitTest(me)
		set caseTab to terminalTab's newTab(TopLevel's TAB_NAME_TEST_CASE)
		ok(TopLevel's terminalUtil's waitWindowCount(2))
		caseTab's closeTab()
		ok(TopLevel's terminalUtil's waitWindowCount(1))
	end script

	script |afterSuite|
		property parent : unitTest(me)
		ok(true) -- dummy test to trigger the afterSuite.
	end script
end script
