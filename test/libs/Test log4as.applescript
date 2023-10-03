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

property parent : script "com.lifepillar/ASUnit"

---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "log4as" -- The name of the script to be tested
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use loggerFactory : script "core/logger-factory"
use xmlUtilLib : script "core/test/xml-util"

property logger : missing value 
 
property TopLevel : me
property suite : makeTestSuite(suitename)
property plist : "log4as-test" -- The name of the temporary plist for testing.
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
		try
			tell application "Finder"
				set deploymentPath to ((path to library folder from user domain) as text) & "Script Libraries:core:"
			end tell
			
			set sutScript to load script (deploymentPath & scriptName & ".scpt") as alias
		end try
		assertInstanceOf(script, sutScript)
	end script
end script


script |log4as.isPrintable tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 32
	property originalPlistName : missing value
	
	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
	end setUp
	on tearDown()
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		xmlUtil's __createTestPlist()
		xmlUtil's __insertXml("categories", "<dict/>")
		set originalPlistName to plistName of sutScript
		set plistName of sutScript to TopLevel's plist
	end beforeClass
	on afterClass()
		xmlUtil's __deleteTestPlist()
		set plistName of sutScript to originalPlistName
	end afterClass 
	
	script |registered - on DEBUG doing debug()|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("categories.log4as\\.core-test-debug", "string", "DEBUG")
		set sut to sutScript's new()
		ok(sut's isPrintable("core-test-debug", debug of sutScript's level))
		xmlUtil's __deleteValue("categories.core-test-debug")
	end script

	script |registered - on DEBUG doing info()|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("categories.log4as\\.core-test-debug", "string", "DEBUG")
		set sut to sutScript's new()
		ok(sut's isPrintable("core-test-debug", info of sutScript's level))
		xmlUtil's __deleteValue("categories.core-test-debug")
	end script

	script |registered - on DEBUG doing warn()|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("categories.log4as\\.core-test-debug", "string", "DEBUG")
		set sut to sutScript's new()
		ok(sut's isPrintable("core-test-debug", warn of sutScript's level))
		xmlUtil's __deleteValue("categories.core-test-debug")
	end script

	script |registered - on DEBUG doing fatal()|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("categories.log4as\\.core-test-debug", "string", "DEBUG")
		set sut to sutScript's new()
		ok(sut's isPrintable("core-test-debug", ERR of sutScript's level))
		xmlUtil's __deleteValue("categories.core-test-debug")
	end script

	script |registered - on WARN doing debug()|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("categories.log4as\\.core-test-warn", "string", "WARN")
		set sut to sutScript's new()
		notOk(sut's isPrintable("core-test-warn", debug of sutScript's level))
		xmlUtil's __deleteValue("categories.core-test-warn")
	end script

	script |registered - on WARN doing info()|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("categories.log4as\\.core-test-warn", "string", "WARN")
		set sut to sutScript's new()
		notOk(sut's isPrintable("core-test-warn", info of sutScript's level))
		xmlUtil's __deleteValue("categories.core-test-warn")
	end script

	script |registered - on WARN doing warn()|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("categories.log4as\\.core-test-warn", "string", "WARN")
		set sut to sutScript's new()
		ok(sut's isPrintable("core-test-warn", warn of sutScript's level))
		xmlUtil's __deleteValue("categories.core-test-warn")
	end script

	script |registered - on WARN doing fatal()|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("categories.log4as\\.core-test-warn", "string", "WARN")
		set sut to sutScript's new()
		ok(sut's isPrintable("core-test-warn", ERR of sutScript's level))
		xmlUtil's __deleteValue("categories.core-test-warn")
	end script	

	script |registered - on ERR doing debug()|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("categories.log4as\\.core-test-error", "string", "ERR")
		set sut to sutScript's new()
		notOk(sut's isPrintable("core-test-error", debug of sutScript's level))
		xmlUtil's __deleteValue("categories.core-test-error")
	end script

	script |registered - on ERR doing info()|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("categories.log4as\\.core-test-error", "string", "ERR")
		set sut to sutScript's new()
		notOk(sut's isPrintable("core-test-error", info of sutScript's level))
		xmlUtil's __deleteValue("categories.core-test-error")
	end script

	script |registered - on ERR doing warn()|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("categories.log4as\\.core-test-error", "string", "ERR")
		set sut to sutScript's new()
		notOk(sut's isPrintable("core-test-error", warn of sutScript's level))
		xmlUtil's __deleteValue("categories.core-test-error")
	end script

	script |registered - on ERR doing fatal()|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("categories.log4as\\.core-test-error", "string", "ERR")
		set sut to sutScript's new()
		ok(sut's isPrintable("core-test-error", ERR of sutScript's level))
		xmlUtil's __deleteValue("categories.core-test-error")
	end script

	script |registered - on OFF doing debug()|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("categories.log4as\\.core-test-error", "string", "OFF")
		set sut to sutScript's new()
		notOk(sut's isPrintable("core-test-error", debug of sutScript's level))
		xmlUtil's __deleteValue("categories.core-test-error")
	end script

	script |registered - on OFF doing info()|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("categories.log4as\\.core-test-error", "string", "OFF")
		set sut to sutScript's new()
		notOk(sut's isPrintable("core-test-error", info of sutScript's level))
		xmlUtil's __deleteValue("categories.core-test-error")
	end script

	script |registered - on OFF doing warn()|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("categories.log4as\\.core-test-error", "string", "OFF")
		set sut to sutScript's new()
		notOk(sut's isPrintable("core-test-error", warn of sutScript's level))
		xmlUtil's __deleteValue("categories.core-test-error")
	end script

	script |registered - on OFF doing fatal()|
		property parent : UnitTest(me)
		xmlUtil's __writeValue("categories.log4as\\.core-test-error", "string", "OFF")
		set sut to sutScript's new()
		notOk(sut's isPrintable("core-test-error", OFF of sutScript's level))
		xmlUtil's __deleteValue("categories.core-test-error")
	end script	


	script |unregistered - on DEBUG doing debug()|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set defaultLevel of sut to debug of sutScript's level
		ok(sut's isPrintable("unicorn", debug of sutScript's level))
	end script

	script |unregistered - on DEBUG doing info()|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set defaultLevel of sut to info of sutScript's level
		ok(sut's isPrintable("unicorn", info of sutScript's level))
	end script

	script |unregistered - on DEBUG doing warn()|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set defaultLevel of sut to warn of sutScript's level
		ok(sut's isPrintable("unicorn", warn of sutScript's level))
	end script

	script |unregistered - on DEBUG doing fatal()|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set defaultLevel of sut to ERR of sutScript's level
		ok(sut's isPrintable("unicorn", ERR of sutScript's level))
	end script


	script |unregistered - on INFO, doing debug()|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set defaultLevel of sut to info of sutScript's level
		notOk(sut's isPrintable("unicorn", debug of sutScript's level))
	end script

	script |unregistered - on INFO, doing info()|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set defaultLevel of sut to info of sutScript's level
		ok(sut's isPrintable("unicorn", info of sutScript's level))
	end script

	script |unregistered - on INFO, doing warn()|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set defaultLevel of sut to info of sutScript's level
		ok(sut's isPrintable("unicorn", warn of sutScript's level))
	end script

	script |unregistered - on INFO, doing fatal()|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set defaultLevel of sut to info of sutScript's level
		ok(sut's isPrintable("unicorn", ERR of sutScript's level))
	end script


	script |unregistered - on WARN, doing debug()|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set defaultLevel of sut to warn of sutScript's level
		notOk(sut's isPrintable("unicorn", debug of sutScript's level))
	end script

	script |unregistered - on WARN, doing info()|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set defaultLevel of sut to warn of sutScript's level
		notOk(sut's isPrintable("unicorn", info of sutScript's level))
	end script

	script |unregistered - on WARN, doing warn()|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set defaultLevel of sut to warn of sutScript's level
		ok(sut's isPrintable("unicorn", warn of sutScript's level))
	end script

	script |unregistered - on WARN, doing fatal()|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set defaultLevel of sut to warn of sutScript's level
		ok(sut's isPrintable("unicorn", ERR of sutScript's level))
	end script


	script |unregistered - on ERROR, doing debug()|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set defaultLevel of sut to ERR of sutScript's level
		notOk(sut's isPrintable("unicorn", debug of sutScript's level))
	end script

	script |unregistered - on ERROR, doing info()|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set defaultLevel of sut to ERR of sutScript's level
		notOk(sut's isPrintable("unicorn", info of sutScript's level))
	end script

	script |unregistered - on ERROR, doing warn()|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set defaultLevel of sut to ERR of sutScript's level
		notOk(sut's isPrintable("unicorn", warn of sutScript's level))
	end script

	script |unregistered - on ERROR, doing fatal()|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set defaultLevel of sut to ERR of sutScript's level
		ok(sut's isPrintable("unicorn", ERR of sutScript's level))
	end script


	script |unregistered - on OFF, doing debug()|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set defaultLevel of sut to OFF of sutScript's level
		notOk(sut's isPrintable("unicorn", debug of sutScript's level))
	end script

	script |unregistered - on OFF, doing info()|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set defaultLevel of sut to OFF of sutScript's level
		notOk(sut's isPrintable("unicorn", info of sutScript's level))
	end script

	script |unregistered - on OFF, doing warn()|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set defaultLevel of sut to OFF of sutScript's level
		notOk(sut's isPrintable("unicorn", warn of sutScript's level))
	end script

	script |unregistered - on OFF, doing fatal()|
		property parent : UnitTest(me)
		set sut to sutScript's new()
		set defaultLevel of sut to OFF of sutScript's level
		notOk(sut's isPrintable("unicorn", ERR of sutScript's level))
	end script
end script

