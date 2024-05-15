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
	@Last Modified: September 3, 2023 10:29 AM
*)
use AppleScript
use scripting additions

use listUtil : script "core/list"

property parent : script "com.lifepillar/ASUnit"
property xmlUtil : missing value
property commonKey : "unit-test"
---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "lov" -- The name of the script to be tested
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use loggerFactory : script "core/logger-factory"
use xmlUtilLib : script "core/test/xml-util"

property logger : missing value

property TopLevel : me
property suite : makeTestSuite(suitename)
property plist : "lov-test"

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
script |Load script - lov|
	property parent : TestSet(me)
	script |Loading the script|
		property parent : UnitTest(me)
		try
			tell application "Finder"
				set deploymentPath to ((path to library folder from user domain) as text) & "Script Libraries:core:"
			end tell
			
			set sutScript to load script (deploymentPath & scriptName & ".scpt") as alias
			set TopLevel's xmlUtil to xmlUtilLib's newPlist(plist)
		end try
		assertInstanceOf(script, sutScript)
	end script
end script
 

script |hasValue tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 2
	property sut : missing value
 
	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
		set sut to sutScript's new(TopLevel's commonKey)
	end setUp
	on tearDown() 
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		xmlUtil's __createTestPlist()
	end beforeClass
	on afterClass()
		xmlUtil's __deleteTestPlist()
	end afterClass
	
	script |No value|
		property parent : UnitTest(me)
		notOk(sut's hasValue("unicorn"))
	end script	

	script |Has Value|
		property parent : UnitTest(me)
		xmlUtil's __insertXml(commonKey, "<array>
			<string>Unit 1</string>
			<string>Unit 2</string>
		</array>") 
		sut's _setLovPlist(plist, commonKey)
		ok(sut's hasValue("Unit 2"))
		xmlUtil's __deleteValue(commonKey)
	end script	
end script
 

script |isBinary tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 2
	property sut : missing value
 
	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
		set sut to sutScript's new(TopLevel's commonKey)
	end setUp
	on tearDown() 
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		xmlUtil's __createTestPlist()
	end beforeClass
	on afterClass()
		xmlUtil's __deleteTestPlist()
	end afterClass
	
	script |2 items|
		property parent : UnitTest(me)
		xmlUtil's __insertXml(commonKey, "<array>
			<string>Unit 1</string>
			<string>Unit 2</string>
		</array>") 
		sut's _setLovPlist(plist, commonKey)
		ok(sut's isBinary())
		xmlUtil's __deleteValue(commonKey)
	end script	

	script |3 items|
		property parent : UnitTest(me)
		xmlUtil's __insertXml(commonKey, "<array>
			<string>Unit 1</string>
			<string>Unit 2</string>
			<string>Unit 3</string>
		</array>") 
		sut's _setLovPlist(plist, commonKey)
		notOk(sut's isBinary())
		xmlUtil's __deleteValue(commonKey)
	end script
end script


script |getNextValue tests|
	property parent : TestSet(me)
	property executedTestCases : 0
	property totalTestCases : 4
	property sut : missing value
 
	on setUp()
		set executedTestCases to executedTestCases + 1
		if executedTestCases is 1 then beforeClass()
		set sut to sutScript's new(TopLevel's commonKey)
	end setUp
	on tearDown() 
		if executedTestCases is equal to the totalTestCases then afterClass()
	end tearDown
	on beforeClass()
		xmlUtil's __createTestPlist()
	end beforeClass
	on afterClass()
		xmlUtil's __deleteTestPlist()
	end afterClass
	
	script |Missing Key|
		property parent : UnitTest(me)
		xmlUtil's __insertXml(commonKey, "<array>
			<string>Unit 1</string>
			<string>Unit 2</string>
		</array>") 
		sut's _setLovPlist(plist, commonKey)
		assertEqual("Unit 1", sut's getNextValue(missing value))
		xmlUtil's __deleteValue(commonKey)
	end script	

	script |Non existing|
		property parent : UnitTest(me)
		xmlUtil's __insertXml(commonKey, "<array>
			<string>Unit 1</string>
			<string>Unit 2</string>
			<string>Unit 3</string>
		</array>")  
		sut's _setLovPlist(plist, commonKey)
		assertEqual("Unit 1", sut's getNextValue("Unicorn"))
		xmlUtil's __deleteValue(commonKey)
	end script

	script |First Item|
		property parent : UnitTest(me)
		xmlUtil's __insertXml(commonKey, "<array>
			<string>Unit 1</string>
			<string>Unit 2</string>
			<string>Unit 3</string> 
		</array>")  
		sut's _setLovPlist(plist, commonKey)
		assertEqual("Unit 2", sut's getNextValue("Unit 1"))
		xmlUtil's __deleteValue(commonKey)
	end script

	script |Last Item|
		property parent : UnitTest(me)
		xmlUtil's __insertXml(commonKey, "<array>
			<string>Unit 1</string>
			<string>Unit 2</string>
			<string>Unit 3</string> 
		</array>")  
		sut's _setLovPlist(plist, commonKey)
		assertEqual("Unit 1", sut's getNextValue("Unit 3"))
		xmlUtil's __deleteValue(commonKey)
	end script
end script
