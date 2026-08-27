(*!
	@header
	@abstract
		A template for unit testing.
	@discussion
		Copy this template in the folder containing the script to be tested and customize it as follows:
	
		1) Provide a description for this test suite and the name of the script to be tested.
		2) Write tests :)

	@Known Issues:
		August 10, 2023 1:58 PM - It's difficult to have a separate factory for testing because the 
		initialization happens at the time of instantiation. Because of this,
		we'll just back up actual config, and restore it on clean up.

	@charset macintosh
	@Created:
*)
use AppleScript
use scripting additions

use usrLib : script "core/user"

property parent : script "com.lifepillar/ASUnit"
property xmlUtil : missing value
---------------------------------------------------------------------------------------
property suitename : "The test suite description goes here"
property scriptName : "decorator" -- The name of the script to be tested
global sutScript -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

use loggerFactory : script "core/logger-factory"
use xmlUtilLib : script "core/test/xml-util"

property logger : missing value

property TopLevel : me
property suite : makeTestSuite(suitename)
property plist : "decorator-test"
property plistPath : "~/applescript-core/config-lib-factory.plist"

loggerFactory's inject(me)
set xmlUtil to xmlUtilLib's newPlist(plist)
autorun(suite)

(* #region agent log *)
on _agentLog(hypId, loc, msg, dataJson)
	try
		set ts to do shell script "python3 -c 'import time;print(int(time.time()*1000))'"
		set payload to "{\"sessionId\":\"bec719\",\"runId\":\"pre-fix\",\"hypothesisId\":\"" & hypId & "\",\"location\":\"" & loc & "\",\"message\":\"" & msg & "\",\"data\":" & dataJson & ",\"timestamp\":" & ts & "}"
		do shell script "printf '%s\\n' " & quoted form of payload & " >> '/Users/royce/Projects/@roycetech/applescript-core/.cursor/debug-bec719.log'"
	end try
end _agentLog
(* #endregion *)

---------------------------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------------------------

-- Don't change this test case if you are testing an external script
-- in the same folder as this test script! We load the script in a test case, because
-- this will work when all the tests in the current folder are run together using loadTestsFromFolder().
-- Besides, this will make sure that we are using the latest version of the script
-- to be tested even if we do not recompile this test script.
script |Load script - decorator|
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


script |getHierarchy tests|
	property parent : TestSet(me)
	property originalFactoryXml : missing value
	
	on setUp()
		set originalFactoryXml to xmlUtil's __grepValueXml("SublimeTextInstance")
		(* #region agent log *)
		set xmlLen to 0
		set xmlMissing to true
		if originalFactoryXml is not missing value then
			set xmlMissing to false
			set xmlLen to length of originalFactoryXml
		end if
		set xmlUtilPlist to xmlUtil's plist
		TopLevel's _agentLog("B", "Test decorator.applescript:setUp", "setUp factory snapshot", "{\"xmlUtilPlist\":\"" & xmlUtilPlist & "\",\"originalFactoryXmlMissing\":" & xmlMissing & ",\"originalFactoryXmlLen\":" & xmlLen & "}")
		(* #endregion *)
	end setUp
	on tearDown()
		TopLevel's xmlUtil's __writeQuotedValue("SublimeTextInstance", "xml", originalFactoryXml)
	end tearDown
	
	script |No override|
		property parent : UnitTest(me)
		script Empty
		end script
		set sut to sutScript's new(Empty)
		skip("Different behavior during suite test")
		assertEqual({"ASUnit", "Test decorator", "Empty"}, sut's _getHierarchy())
	end script
	
	script |Integration - No override|
		property parent : UnitTest(me)
		set dialogLib to script "core/dialog"
		set dialog to dialogLib's new()
		set sut to sutScript's new(dialog)
		assertEqual({"dialog", "DialogInstance"}, sut's _getHierarchy())
	end script
	
	script |Integration - Single override|
		property parent : UnitTest(me)
		set systemEventsLib to script "core/system-events"
		set systemEvents to systemEventsLib's new()
		(* #region agent log *)
		set seName to name of systemEvents
		set seParentName to "none"
		try
			set seParentName to name of (systemEvents's parent)
		end try
		set factoryType to do shell script "output=$(plutil -type 'SystemEventsInstance' ~/applescript-core/config-lib-factory.plist 2>/dev/null) || output=''; echo $output"
		set factoryCsv to do shell script "output=$(plutil -extract SystemEventsInstance xml1 ~/applescript-core/config-lib-factory.plist -o - 2>/dev/null | awk '/<string>/{gsub(/<[^>]+>/,\"\"); print}' | paste -s -d, -) || output=''; echo $output"
		set xmlUtilPlist to TopLevel's xmlUtil's plist
		TopLevel's _agentLog("A", "Test decorator.applescript:Single override", "live factory and instance names", "{\"systemEventsName\":\"" & seName & "\",\"systemEventsParentName\":\"" & seParentName & "\",\"factoryType\":\"" & factoryType & "\",\"factoryCsv\":\"" & factoryCsv & "\",\"xmlUtilPlist\":\"" & xmlUtilPlist & "\"}")
		(* #endregion *)
		set sut to sutScript's new(systemEvents)
		(* #region agent log *)
		set hierarchy to sut's _getHierarchy()
		set AppleScript's text item delimiters to ","
		set hierarchyCsv to hierarchy as text
		set AppleScript's text item delimiters to ""
		TopLevel's _agentLog("C", "Test decorator.applescript:Single override", "hierarchy after decorator wrap", "{\"hierarchy\":\"" & hierarchyCsv & "\"}")
		(* #endregion *)
		assertEqual({"system-events", "SystemEventsInstance"}, sut's _getHierarchy())
	end script
	
	script |Integration - Double override|
		property parent : UnitTest(me)
		skip("No public example yet.")
		set systemEventsLib to script "core/sublime-text"
		set systemEvents to systemEventsLib's new()
		set sut to sutScript's new(systemEvents)
		assertEqual({"sublime-text", "SublimeTextInstance", "SublimeTextWindowFocusInstance", "SublimeTextFrontFileToucher"}, sut's _getHierarchy())
	end script
end script
