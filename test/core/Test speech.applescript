(*!
	@header
	@abstract
		A template for unit testing.
	@discussion
		Copy this template in the folder containing the script to be tested and customize it as follows:
	
		1) Provide a description for this test suite and the name of the script to be tested.
		2) Write tests :)

	@Known Issues:
		September 23, 2023 1:07 PM - Crashes with strange errors. Fixed by randomly placing a "say" statement somewhere in this script file.

	@charset macintosh
	@Created: 2023
*)
use AppleScript
use scripting additions

property parent : script "com.lifepillar/ASUnit"

---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "speech" -- The name of the script to be tested
property plist : "speech-test"
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use xmlUtilLib : script "core/test/xml-util"
use usrLib : script "core/user"

property TopLevel : me
property suite : makeTestSuite(suitename)
property xmlUtil : missing value

set xmlUtil to xmlUtilLib's newPlist(plist)
autorun(suite)

---------------------------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------------------------

-- Don't change this test case if you are testing an external script
-- in the same folder as this test script! We load the script in a test case, because
-- this will work when all the tests in the current folder are run together using loadTestsFromFolder().
-- Besides, this will make sure that we are using the latest version of the script
-- to be tested even if we do not recompile this test script.
script |Load script - speech|
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
			set xmlUtil to xmlUtilLib's newPlist(plist)
		end try
		assertInstanceOf(script, sutScript)
	end script
end script

script |speak tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	
	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
	end setUp
	on tearDown()
		if my name is "afterClass" then
			afterClass()
		end if
		
	end tearDown
	on beforeClass()
		xmlUtil's __createTestPlist()
		set sut to sutScript's newWithLocale(plist)
	end beforeClass
	
	on afterClass()
		-- xmlUtil's __deleteTestPlist()
	end afterClass
	
	script |Unknown|
		property parent : UnitTest(me)
		set sut to TopLevel's __newSut(missing value)
		assertEqual("Unicorn", sut's speak("Unicorn"))
	end script
	
	
	script |Dashing 4 digits|
		property parent : UnitTest(me)
		script Lambda
			xmlUtil's __writeValue("_1234", "string", "12-34")
		end script
		set sut to TopLevel's __newSut(Lambda)
		-- set sut to sutScript's newWithLocale(plist)
		-- set _userInMeetingStub of sut to true
		assertEqual("12-34", sut's speak("1234"))
		delay 0.1 -- Fixes crushing error.
		xmlUtil's __deleteValue("_1234")
	end script
	
	script |Digits as integer|
		property parent : UnitTest(me)
		script Lambda
			xmlUtil's __writeValue("_1234", "integer", 1234)
		end script
		set sut to TopLevel's __newSut(Lambda)
		assertEqual("1234", sut's speak(1234))
		delay 0.1 -- Fixes crushing error.
		-- Expect that speech correctly pronounces it as one thousand, two hundred, thirty four.
		xmlUtil's __deleteValue("_1234")
	end script
	
	script |Unregistered digits|
		property parent : UnitTest(me)
		set sut to TopLevel's __newSut(missing value)
		assertEqual("0000", sut's speak("0000"))
	end script
	
	script |Exact Text Match|
		property parent : UnitTest(me)
		script Lambda
			xmlUtil's __writeValue("QA", "string", "Q-A")
		end script
		set sut to TopLevel's __newSut(Lambda)
		assertEqual("Q-A", sut's speak("QA"))
	end script
	
	script |Partial Text Match|
		property parent : UnitTest(me)
		script Lambda
			xmlUtil's __writeValue("se", "string", "S-E")
		end script
		set sut to TopLevel's __newSut(Lambda)
		assertEqual("Test S-E spoken", sut's speak("Test se spoken"))
	end script
	
	(* Unable to test.
	script |Not synchronized doesn't wait for speech to complete|
		property parent : UnitTest(me)
		set sut to TopLevel's __newSut(missing value)
		set startTime to time of (current date)
		sut's speak("Internationalization")
		set endTime to time of (current date)
		log endTime - startTime
		ok(endTime - startTime < 2)
	end script

	script |Synchronized waits for speech to complete|
		property parent : UnitTest(me)
		set sut to TopLevel's __newSut(missing value)
		set synchronous of sut to true
		set startTime to time of (current date)
		sut's speak("Internationalization")
		set endTime to time of (current date)
		log endTime - startTime
		ok(endTime - startTime > 2)
	end script
	*)
	
	script |afterClass|
		property parent : UnitTest(me)
		ok(true)
	end script
end script

(*
script |speech.speakSynchronously tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 2
	
	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
	end setUp
	on tearDown()
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		xmlUtil's __createTestPlist()
		set sut to sutScript's newWithLocale(plist)
	end beforeClass
	on afterClass()
		xmlUtil's __deleteTestPlist()
	end afterClass
	
	script |Restores the original state to async|
		property parent : UnitTest(me)
		set sut to TopLevel's __newSut(missing value)
		sut's speakSynchronously("one")
		notOk(synchronous of sut)
	end script
	
	script |Restores the original state to synchronous|
		property parent : UnitTest(me)
		set sut to TopLevel's __newSut(missing value)
		set synchronous of sut to true
		sut's speakSynchronously("two")
		ok(synchronous of sut)
	end script
end script
*)

on __newSut(Lambda)
	if Lambda is not missing value then run script Lambda
	
	-- log plist
	set sut to sutScript's newWithLocale(plist)
	-- set _userInMeetingStub of sut to true -- Can't use this, because translation happens only when UNSILENCED.
	sut
end __newSut
