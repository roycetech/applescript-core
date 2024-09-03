(*!
	@header
	@abstract
		A template for unit testing.
	@discussion
		Copy this template in the folder containing the script to be tested and customize it as follows:
	
		1) Provide a description for this test suite and the name of the script to be tested.
		2) Write tests :)

	@charset macintosh
	@Created: August 31, 2023 10:17 AM
*)
use AppleScript
use scripting additions

property parent : script "com.lifepillar/ASUnit"

---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "date-time" -- The name of the script to be tested
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use loggerFactory : script "core/logger-factory"
use usrLib : script "core/user"

property logger : missing value

property TopLevel : me
property suite : makeTestSuite(suitename)

loggerFactory's inject(me)
autorun(suite)

---------------------------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------------------------

-- Don't change this test case if you are testing an external script
-- in the same folder as this test script! We load the script in a test case, because
-- this will work when all the tests in the current folder are run together using loadTestsFromFolder().
-- Besides, this will make sure that we are using the latest version of the script
-- to be tested even if we do not recompile this test script.
script |Load script - date-time|
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


script |today tests|
	property parent : TestSet(me)
	property sut : missing value
	
	on setUp()
		set sut to sutScript's new()
	end setUp
	on tearDown()
	end tearDown
	
	script |Basic|
		property parent : UnitTest(me)
		
		assertEqual(TopLevel's __shellYear("+0d"), year of sut's today())
		assertEqual(TopLevel's __shellMonth("+0d"), month of sut's today() as integer)
		assertEqual(TopLevel's __shellDay("+0d"), day of sut's today())
	end script
end script


script |yesterday tests|
	property parent : TestSet(me)
	property sut : missing value
	
	on setUp()
		set sut to sutScript's new()
	end setUp
	on tearDown()
	end tearDown
	
	script |Basic|
		property parent : UnitTest(me)
		
		assertEqual(TopLevel's __shellYear("-1d"), year of sut's yesterday())
		assertEqual(TopLevel's __shellMonth("-1d"), month of sut's yesterday() as integer)
		assertEqual(TopLevel's __shellDay("-1d"), day of sut's yesterday())
	end script
end script


script |tomorrow tests|
	property parent : TestSet(me)
	property sut : missing value
	
	on setUp()
		set sut to sutScript's new()
	end setUp
	on tearDown()
	end tearDown
	
	script |Basic|
		property parent : UnitTest(me)
		
		assertEqual(TopLevel's __shellYear("+1d"), year of sut's tomorrow())
		assertEqual(TopLevel's __shellMonth("+1d"), month of sut's tomorrow() as integer)
		assertEqual(TopLevel's __shellDay("+1d"), day of sut's tomorrow())
	end script
end script


script |todayMinusDays tests|
	property parent : TestSet(me)
	property sut : missing value
	
	on setUp()
		set sut to sutScript's new()
	end setUp
	on tearDown()
	end tearDown
	
	script |Zero|
		property parent : UnitTest(me)
		
		assertEqual(TopLevel's __shellYear("+0d"), year of sut's todayMinusDays(0))
		assertEqual(TopLevel's __shellMonth("+0d"), month of sut's todayMinusDays(0) as integer)
		assertEqual(TopLevel's __shellDay("+0d"), day of sut's todayMinusDays(0))
	end script

	script |-3 Days|
		property parent : UnitTest(me)
		
		assertEqual(TopLevel's __shellYear("-3d"), year of sut's todayMinusDays(3))
		assertEqual(TopLevel's __shellMonth("-3d"), month of sut's todayMinusDays(3) as integer)
		assertEqual(TopLevel's __shellDay("-3d"), day of sut's todayMinusDays(3))
	end script
end script


script |extractTimeFromDateTimeText tests|
	property parent : TestSet(me) 
	property sut : missing value

	property DateTime12HExampleAM : "Thursday, August 31, 2023 at 11:49:39 AM"
	property DateTime12HExamplePM : "Thursday, August 31, 2023 at 1:49:39 PM"
	property DateTime24HExampleAM : "Thursday, August 31, 2023 at 11:46:34"
	property DateTime24HExamplePM : "Thursday, August 31, 2023 at 13:46:34"
	
	on setUp()
		set sut to sutScript's new()
	end setUp
	on tearDown() 
	end tearDown 

	script |12 hour, morning|
		property parent : UnitTest(me)
		set actual to sut's extractTimeFromDateTimeText(DateTime12HExampleAM)
		ok(actual starts with "11:49:39 AM") 
	end script

	script |12 hour, afternoon|
		property parent : UnitTest(me)
		set actual to sut's extractTimeFromDateTimeText(DateTime12HExamplePM)
		ok(actual starts with "1:49:39 PM")
	end script

	-- Discontinued, deprecated this handler.
end script


script |Default Weekday Tests|
	property parent : TestSet(me)
	property sut : missing value

	on setUp()
		set sut to sutScript's new()
		set adate to current date
		tell adate  -- Tuesday
			set its year to 2023
			set its month to 1
			set its day to 31 
		end tell
		set _today of sut to adate
	end setUp
	on tearDown()
		set _today of sut to missing value
	end tearDown
	
	script |isWeekDay|
		property parent : UnitTest(me)
		ok(sut's isWeekDay())
	end script

	script |isWeekEnd|
		property parent : UnitTest(me)
		notOk(sut's isWeekend())
	end script
end script


script |Default Weekend Tests|
	property parent : TestSet(me)
	property sut : missing value

	on setUp()
		set sut to sutScript's new()
		set adate to current date
		tell adate  -- Sunday
			set its year to 2023
			set its month to 1
			set its day to 29 
		end tell
		set _today of sut to adate
	end setUp
	on tearDown()
		set _today of sut to missing value
	end tearDown
	
	script |isWeekDay|
		property parent : UnitTest(me)
		notOk(sut's isWeekDay())
	end script

	script |isWeekend|
		property parent : UnitTest(me)
		ok(sut's isWeekend())
	end script
end script


script |Weekend on Friday and Saturday, Weekday Tests|
	property parent : TestSet(me)
	property sut : missing value

	on setUp()
		set sut to sutScript's new()
		set adate to current date
		tell adate  -- Tuesday
			set its year to 2023
			set its month to 1
			set its day to 31 
		end tell
		set _today of sut to adate
		set weekendDays of sut to {Friday, Saturday}
	end setUp
	on tearDown()
		set _today of sut to missing value
	end tearDown
	
	script |isWeekDay|
		property parent : UnitTest(me)
		ok(sut's isWeekDay())
	end script

	script |isWeekEnd|
		property parent : UnitTest(me)
		notOk(sut's isWeekend())
	end script
end script


script |Weekend on Friday and Saturday, Weekend Tests|
	property parent : TestSet(me)
	property sut : missing value

	on setUp()
		set sut to sutScript's new()
		set adate to current date
		tell adate  -- Friday
			set its year to 2023
			set its month to 1
			set its day to 27 
		end tell
		set _today of sut to adate
		set weekendDays of sut to {Friday, Saturday}
	end setUp
	on tearDown()
		set _today of sut to missing value
	end tearDown
	
	script |isWeekDay|
		property parent : UnitTest(me)
		notOk(sut's isWeekDay())
	end script

	script |isWeekEnd|
		property parent : UnitTest(me)
		ok(sut's isWeekend())
	end script
end script


script |Morning tests|
	property parent : TestSet(me)
	property sut : missing value

	on setUp()
		set sut to sutScript's new()
		set adate to current date
		tell adate  -- Friday
			set its year to 2023
			set its month to 1
			set its day to 27 
			set its hours to 2 
		end tell
		set _today of sut to adate
	end setUp
	on tearDown()
		set _today of sut to missing value 
	end tearDown  

	script |isMorning| 
		property parent : UnitTest(me) 
		ok(sut's isMorning())
	end script

	script |isArvo|
		property parent : UnitTest(me) 
		notOk(sut's isArvo()) 
	end script
end script


script |Arvo tests|
	property parent : TestSet(me)
	property sut : missing value

	on setUp()
		set sut to sutScript's new()
		set adate to current date
		tell adate  -- Friday
			set its year to 2023
			set its month to 1
			set its day to 27 
			set its hours to 14 
		end tell
		set _today of sut to adate
	end setUp
	on tearDown()
		set _today of sut to missing value
	end tearDown

	script |isMorning|
		property parent : UnitTest(me)
		notOk(sut's isMorning())
	end script

	script |isArvo|
		property parent : UnitTest(me)
		ok(sut's isArvo())
	end script
end script


script |formatYyyyMmDd tests|
	property parent : TestSet(me)
	property sut : missing value

	on setUp()
		set sut to sutScript's new()
	end setUp
	on tearDown()
	end tearDown

	script |Without delimiter|
		property parent : UnitTest(me)
		assertEqual("20211004", sut's formatYyyyMmDd(date "Monday, October 4, 2021 at 8:00:00 AM", missing value))
	end script

	script |With / delimiter|
		property parent : UnitTest(me)
		assertEqual("2021/10/04", sut's formatYyyyMmDd(date "Monday, October 4, 2021 at 8:00:00 AM", "/"))
	end script
end script


script |formatYyyyMmDdHHmi tests|
	property parent : TestSet(me)
	property sut : missing value

	on setUp()
		set sut to sutScript's new()
	end setUp
	on tearDown()
	end tearDown

	script |Without delimiter|
		property parent : UnitTest(me)
		assertEqual("202110040800", sut's formatYyyyMmDdHHmi(date "Monday, October 4, 2021 at 8:00:00 AM"))
	end script
end script


script |formatYyyyDdMm tests|
	property parent : TestSet(me)
	property sut : missing value

	on setUp()
		set sut to sutScript's new()
	end setUp
	on tearDown()
	end tearDown

	script |Without delimiter|
		property parent : UnitTest(me)
		assertEqual("20210410", sut's formatYyyyDdMm(date "Monday, October 4, 2021 at 8:00:00 AM", ""))
	end script

	script |With delimiter|
		property parent : UnitTest(me)
		assertEqual("2021-04-10", sut's formatYyyyDdMm(date "Monday, October 4, 2021 at 8:00:00 AM", "-"))
	end script
end script


script |formatMmDdYyyy tests|
	property parent : TestSet(me)
	property sut : missing value

	on setUp()
		set sut to sutScript's new()
	end setUp
	on tearDown()
	end tearDown

	script |Without delimiter|
		property parent : UnitTest(me)
		assertEqual("10042021", sut's formatMmDdYyyy(date "Monday, October 4, 2021 at 8:00:00 AM", ""))
	end script

	script |With delimiter|
		property parent : UnitTest(me)
		assertEqual("10-04-2021", sut's formatMmDdYyyy(date "Monday, October 4, 2021 at 8:00:00 AM", "-"))
	end script
end script


script |formatYyMmDd tests|
	property parent : TestSet(me)
	property sut : missing value

	on setUp()
		set sut to sutScript's new()
	end setUp
	on tearDown()
	end tearDown

	script |Basic|
		property parent : UnitTest(me)
		assertEqual("211004", sut's formatYyMmDd(date "Monday, October 4, 2021 at 8:00:00 AM", "-"))
	end script
end script


script |formatDateSQL tests|
	property parent : TestSet(me)
	property sut : missing value

	on setUp()
		set sut to sutScript's new()
	end setUp
	on tearDown()
	end tearDown

	script |Basic|
		property parent : UnitTest(me)
		assertEqual("2021-10-04", sut's formatDateSQL(date "Monday, October 4, 2021 at 8:00:00 AM", "-"))
	end script
end script


script |getDatesTime tests|
	property parent : TestSet(me)
	property sut : missing value

	on setUp()
		set sut to sutScript's new()
	end setUp
	on tearDown()
	end tearDown

	script |Basic|
		property parent : UnitTest(me)
		assertEqual(28800, sut's getDatesTime(date "Monday, October 4, 2021 at 8:00:00 AM"))
		assertEqual(28801, sut's getDatesTime(date "Monday, October 4, 2021 at 8:00:01 AM"))
	end script
end script


script |fromZuluDateText tests|
	property parent : TestSet(me)
	property sut : missing value

	on setUp()
		set sut to sutScript's new()
	end setUp
	on tearDown()
	end tearDown

	script |Missing Value|
		property parent : UnitTest(me)
		assertMissing(sut's fromZuluDateText(missing value))
	end script

	script |Happy Case|
		property parent : UnitTest(me)
		set timezoneOffset to (do shell script "date +'%z' | cut -c 2,3") as integer
		set expected to current date
		tell expected  -- Friday
			set its year to 2023
			set its month to 08
			set its day to 29 
			set its hours to 7 + timezoneOffset
			set its minutes to 31 
			set its seconds to 42
		end tell

		assertEqual(expected, sut's fromZuluDateText("2023-08-29T07:31:42Z"))
	end script
end script


on __shellYear(offsetText)
	(do shell script "date -v" & offsetText & " +%Y") as integer
end __currentYear


on __shellMonth(offsetText)
	(do shell script "date -v" & offsetText & " +%m") as integer
end __shellMonth


on __shellDay(offsetText)
	(do shell script "date -v" & offsetText & " +%d") as integer
end __shellDay

