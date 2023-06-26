(*
	@Plists:
		log4as
			defaultLevel
			printToConsole
			categories

	WARNINGs: 
		Do not use logger here, circular dependency to self is not good.
		Keys in the plist are case-sensitive!
		
	@TODO:
		Use unit testing.
*)

use listUtil : script "list"

use plutilLib : script "plutil"
use mapLib : script "map"

use spotScript : script "spot-test"

use testLib : script "test"

property plutil : plutilLib's new()
property test : testLib's new()

(* *)
property level : {info:1, debug:2, warn:3, ERR:4, OFF:5}
property defaultLevel : info of level
property LOG4AS_CONFIG : missing value

(* ASDictionary. Populated from log4as.plist, categories.*)
property classesLevel : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

(*
	Note: Bad idea to use logger here for spot checking.
*)
on spotCheck()
	set thisCaseId to "log4as-spotCheck"
	-- logger's start()
	
	set cases to listUtil's splitByLine("
		Integration Test
		Manual: Config Info
		Manual: Is Printable (un/registered, less, equal, greater, OFF)
	")
	
	set useBasicLogging of spotScript to true
	set spotClass to spotScript's new()
	set spot to spotClass's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		return
	end if
	
	set sut to new()
	if caseIndex is 1 then
		integrationTest()
		
	else if caseIndex is 2 then
		log "Default Level: " & LOG4AS_CONFIG's getValue("defaultLevel")
		log "Print to console: " & LOG4AS_CONFIG's getValue("printToConsole")
		log "Write to file: " & LOG4AS_CONFIG's getValue("writeToFile")
		set categories to LOG4AS_CONFIG's getValue("categories")
		if categories is missing value then
			log "no categories"
		else
			log "categories:"
			log LOG4AS_CONFIG's getValue("categories")'s toString()
		end if
		
	else if caseIndex is 3 then
		(* Matched, Manually create appropriate entry in log4as.plist *)
		
		log "Is 'log4as' Printable on info? : " & sut's isPrintable("log4as", info of level)
		log "Is log4as.log4as Printable on debug: " & sut's isPrintable("log4as", debug of level)
		log "Is log4as.log4as Printable on warn: " & sut's isPrintable("log4as", warn of level)
		log "Is log4as.log4as Printable on ERR: " & sut's isPrintable("log4as", ERR of level)
		log "Is 'log4as' Printable on OFF? : " & sut's isPrintable("log4as", OFF of level)
		
		log "---"
		(* Unmatched, make sure there is no matching entry in log4as.plist *)
		set defaultLevel of sut to info of level
		set defaultLevel of sut to debug of level
		set defaultLevel of sut to warn of level
		set defaultLevel of sut to ERR of level
		set defaultLevel of sut to OFF of level
		
		log "Default level: " & sut's defaultLevel
		
		log "Will info() print on " & sut's defaultLevel & ": " & sut's isPrintable("$absent", info of level)
		log "Will debug() print on " & sut's defaultLevel & ": " & sut's isPrintable("$absent", debug of level)
		log "Will warn() print on " & sut's defaultLevel & ": " & sut's isPrintable("$absent", warn of level)
		log "Will fatal() print on " & sut's defaultLevel & ": " & sut's isPrintable("$absent", ERR of level)
	end if
	
	spot's finish()
end spotCheck

(*  *)
on new()
	if my LOG4AS_CONFIG is missing value then loadPlist()
	
	script Log4asInstance
		on isPrintable(moduleName, targetLogLevel)
			if targetLogLevel is equal to OFF of level then return false
			
			repeat with nextClassLevel in my classesLevel's getKeys()
				set nextClassKey to text 8 thru -1 of nextClassLevel
				if moduleName starts with nextClassKey then
					set nextClassLevel to my classesLevel's getValue(nextClassLevel)
					set subjectLevelInt to _textToInt(nextClassLevel)
					-- log "matched moduleName: " & moduleName & ", nextClassLevel: " & nextClassLevel & ", target's value: " & subjectLevelInt
					
					return targetLogLevel is less than or equal to the subjectLevelInt and subjectLevelInt is not equal to the OFF of level
				end if
			end repeat
			
			-- when moduleName is not found in the plist.
			if my defaultLevel is equal to OFF of level then return false
			
			
			-- log "targetLogLevel: " & targetLogLevel & ", default level: " & my defaultLevel
			targetLogLevel is greater than or equal to my defaultLevel
		end isPrintable
	end script
end new


-- Private Codes below =======================================================


(* Can be called outside to reload the plist. *)
on loadPlist()
	set my LOG4AS_CONFIG to plutil's new("log4as")
	initDefaultLevel()
	
	set classLevel to mapLib's new()
	set my classesLevel to LOG4AS_CONFIG's getValue("categories")
	
	if my classesLevel is not missing value then
		repeat with nextKey in my classesLevel's getKeys()
			-- log "next classes level: " & nextKey
		end repeat
	end if
end loadPlist


on initDefaultLevel()
	set defaultLevelConfig to LOG4AS_CONFIG's getValueWithDefault("defaultLevel", "INFO")
	set my defaultLevel to _textToInt(defaultLevelConfig)
end initDefaultLevel


on _textToInt(logLevel)
	if logLevel is "INFO" then return info of level
	if logLevel is "DEBUG" then return debug of level
	if logLevel is "WARN" then return warn of level
	if logLevel is "ERR" then return ERR of level
	if logLevel is "OFF" then return OFF of level
end _textToInt

on integrationTest()
	set sut to new() -- will load the plist, but we'll override those with test.	
	set ut to test's new()
	tell ut
		newMethod("isPrintable - unregistered")
		set defaultLevel of sut to info of my level
		assertTrue(sut's isPrintable("$absent", info of level), "info() on INFO")
		assertTrue(sut's isPrintable("$absent", debug of level), "debug() on INFO")
		assertTrue(sut's isPrintable("$absent", warn of level), "warn() on INFO")
		assertTrue(sut's isPrintable("$absent", ERR of level), "fatal() on INFO")
		set defaultLevel of sut to debug of level
		assertFalse(sut's isPrintable("$absent", info of level), "info() on DEBUG")
		assertTrue(sut's isPrintable("$absent", debug of level), "debug() on DEBUG")
		assertTrue(sut's isPrintable("$absent", warn of level), "warn() on DEBUG")
		assertTrue(sut's isPrintable("$absent", ERR of level), "fatal() on DEBUG")
		
		log name of its logger
		
		done()
	end tell
end integrationTest
