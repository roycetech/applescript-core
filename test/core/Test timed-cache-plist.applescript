(*!
	@header
	@abstract
		A template for unit testing.
	@discussion
		Copy this template in the folder containing the script to be tested and customize it as follows:
	
		1) Provide a description for this test suite and the name of the script to be tested.
		2) Write tests :)

	@charset macintosh
	@Created: August 31, 2023 7:09 PM
*)
use AppleScript
use scripting additions
use textUtil : script "core/string"

property parent : script "com.lifepillar/ASUnit"

---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "timed-cache-plist" -- The name of the script to be tested
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use loggerFactory : script "core/logger-factory"
use xmlUtilLib : script "core/test/xml-util"
use usrLib : script "core/user"

property logger : missing value

property TopLevel : me
property suite : makeTestSuite(suitename) 
property plist : "timed-cache-plist-test" -- The name of the temporary plist for testing.
property xmlUtil : missing value

loggerFactory's inject(me)
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
script |Load script|
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
			-- Need to be here when run from the loader, otherwise it needs to 
			-- be initialized before the autorun in the TopLevel scope.
			set xmlUtil to xmlUtilLib's newPlist(plist)
		end try 
		assertInstanceOf(script, sutScript)
	end script
end script


script |_timestampKey tests|
	property parent : TestSet(me)

	script |Basic case|
		property parent : UnitTest(me)
		set sut to sutScript's new(0)
		assertEqual("test-ts", sut's _timestampKey("test"))
	end script
end script


script |_epochTimestampKey tests|
	property parent : TestSet(me)
	property executedTestCases : 0

	script |Basic case|
		property parent : UnitTest(me)
		set sut to sutScript's new(0)
		assertEqual("test-ets", sut's _epochTimestampKey("test"))
	end script
end script


script |_getRegisteredSeconds tests|
	property parent : TestSet(me)

	script |#beforeClass|
		property parent : UnitTest(me)
		TopLevel's xmlUtil's __createTestPlist()  
		set cacheName of sutScript to TopLevel's plist
	end script	

	script |Missing Value key|
		property parent : UnitTest(me)
		set sut to sutScript's new(0)
		assertMissing(sut's _getRegisteredSeconds(missing value))
	end script

	script |Not Found|
		property parent : UnitTest(me)
		set sut to sutScript's new(0)
		assertMissing(sut's _getRegisteredSeconds("Dracula"))  -- Somehow, using "Unicorn" instead of "Dracula" causes Segmentation fault: 11
	end script

	script |Found|
		property parent : UnitTest(me)
		set sut to sutScript's new(0)
		TopLevel's xmlUtil's __writeValue("string", "string", "string-value") 
		set storedSeconds to do shell script "date +%s"
		TopLevel's xmlUtil's __writeValue("string-ets", "integer", storedSeconds)
		assertEqual(0, storedSeconds - sut's _getRegisteredSeconds("string")) 
		TopLevel's xmlUtil's __deleteValue("string") 
		TopLevel's xmlUtil's __deleteValue("string-ets") 
	end script

	script |#afterClass|
		property parent : UnitTest(me)
		TopLevel's xmlUtil's __deleteTestPlist()
	end script	
end script


script |getValue tests|
	property parent : TestSet(me)

	script |#beforeClass|
		property parent : UnitTest(me)
		TopLevel's xmlUtil's __createTestPlist()  
		set cacheName of sutScript to TopLevel's plist
	end script	
	 
	script |Retrieve non-existent| 
		property parent : UnitTest(me)
		set sut to sutScript's new(0)
		assertMissing(sut's getValue("unicorn"))
	end script

	script |Retrieve existing|
		property parent : UnitTest(me) 
		set sut to sutScript's new(1000)
		TopLevel's xmlUtil's __writeValue("string", "string", "string-value") 
		TopLevel's xmlUtil's __writeValue("string-ets", "integer", do shell script "date +%s")
		assertEqual("string-value", sut's getValue("string")) 
		TopLevel's xmlUtil's __deleteValue("string") 
		TopLevel's xmlUtil's __deleteValue("string-ets") 
	end script

	script |Retrieve existing but expired|
		property parent : UnitTest(me) 
		set sut to sutScript's new(1)
		TopLevel's xmlUtil's __writeValue("string", "string", "string-value") 
		TopLevel's xmlUtil's __writeValue("string-ets", "integer", do shell script "date +%s")
		delay 2
		assertMissing(sut's getValue("string")) 
		assertEqual("", TopLevel's xmlUtil's __grepValueXml("string")) 
		assertEqual("", TopLevel's xmlUtil's __grepValueXml("string-ts")) 
		assertEqual("", TopLevel's xmlUtil's __grepValueXml("string-ets")) 
		TopLevel's xmlUtil's __deleteValue("string") 
		TopLevel's xmlUtil's __deleteValue("string-ets") 
	end script

	script |#afterClass|
		property parent : UnitTest(me)
		TopLevel's xmlUtil's __deleteTestPlist()
	end script	
end script


script |setValue tests|
	property parent : TestSet(me)

	script |#beforeClass|
		property parent : UnitTest(me)
		TopLevel's xmlUtil's __createTestPlist()  
		set cacheName of sutScript to TopLevel's plist
	end script	
	 
	script |Basic| 
		property parent : UnitTest(me)
		set sut to sutScript's new(0)		
		sut's setValue("string", "string-value")

		set currentShellIsoDate to do shell script "date -u +'%Y-%m-%dT%H:%M:%SZ'"
		set currentShellSeconds to do shell script "date +%s"
		assertEqual("<string>string-value</string>" , TopLevel's xmlUtil's __grepValueXml("string"))
		assertEqual("<date>" & currentShellIsoDate & "</date>" , TopLevel's xmlUtil's __grepValueXml("string-ts"))
		assertEqual("<real>" & currentShellSeconds & "</real>" , TopLevel's xmlUtil's __grepValueXml("string-ets"))
	end script

	script |#afterClass|
		property parent : UnitTest(me)
		TopLevel's xmlUtil's __deleteTestPlist()
	end script	
end script


script |deleteKey tests|
	property parent : TestSet(me)

	script |#beforeClass|
		property parent : UnitTest(me)
		TopLevel's xmlUtil's __createTestPlist()  
		set cacheName of sutScript to TopLevel's plist
	end script

	script |Missing Value does nothing| 
		property parent : UnitTest(me)
		set sut to sutScript's new(0) 
		TopLevel's xmlUtil's __writeValue("string", "string", "string-value") 
		TopLevel's xmlUtil's __writeValue("string-ets", "integer", do shell script "date +%s")
		set currentShellIsoDate to do shell script "date -u +'%Y-%m-%dT%H:%M:%SZ'"
		TopLevel's xmlUtil's __writeValue("string-ts", "string", currentShellIsoDate)
		sut's deleteKey(missing value)
		assertEqual(textUtil's multiline("string
string-ets
string-ts"), TopLevel's xmlUtil's __readAllKeys())
	end script

	script |Basic| 
		property parent : UnitTest(me)
		set sut to sutScript's new(0)
		TopLevel's xmlUtil's __writeValue("string", "string", "string-value") 
		TopLevel's xmlUtil's __writeValue("string-ets", "integer", do shell script "date +%s")
		set currentShellIsoDate to do shell script "date -u +'%Y-%m-%dT%H:%M:%SZ'"
		TopLevel's xmlUtil's __writeValue("string-ts", "string", currentShellIsoDate)
		sut's deleteKey("string")
		assertEqual("", TopLevel's xmlUtil's __readAllKeys())
	end script

	script |#afterClass|
		property parent : UnitTest(me)
		TopLevel's xmlUtil's __deleteTestPlist()
	end script	
end script
