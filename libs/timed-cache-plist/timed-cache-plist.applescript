(*
	use tcache : script "timed-cache-plist"

	@Build:
		make install-timed-cache

	@Plists:
		config.plist
		 	Timed Cache List - Can't find the reference for this - June 30, 2023 11:17 AM
		timed-cache.plist - Contains the cached values.
*)

use scripting additions

use listUtil : script "list"
use dt : script "date-time"
use loggerFactory : script "logger-factory"

use plutilLib : script "plutil"

use spotScript : script "spot-test"
use testLib : script "test"

property logger : missing value
property cache : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me, "timed-cache-plist")
	set thisCaseId to "timed-cache-plist-spotCheck"
	logger's start()
	
	set test to testLib's new()
	set integTest to test's new()
	set cases to listUtil's splitByLine("
		Integration Testing
	")
	set spotClass to spotScript's new()
	set spot to spotClass's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set spotKey to "Spot Timed Key"
	if caseIndex is 1 then
		tell integTest
			newScenario("Retrieve non-expired value")
			set sut to my new(2)
			sut's setValue(spotKey, "Not expired")
			assertEqual("Not expired", sut's getValue(spotKey), "Retrieve non-expired value")
			
			newScenario("Retrieve expired value")
			logger's info("Sleeping...")
			delay 3
			assertMissingValue(sut's getValue(spotKey), "Retrieve expired value")
			
			done()
		end tell
		
	else if caseIndex is 2 then
		set sut to new(2)
		sut's setValue(spotKey, "Will expire")
		log sut's getValue(spotKey)
		log cache's getValue(spotKey)
		
		done()
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new(pExpirySeconds)
	set plutil to plutilLib's new()
	set cacheName to "timed-cache"
	if not plutil's plistExists(cacheName) then
		plutil's createNewPList(cacheName)
	end if
	set cache to plutil's new(cacheName)
	
	script TimedCacheInstance
		property expirySeconds : pExpirySeconds
		
		(* @return missing value if the content has expired, so client can reset it again. *)
		on getValue(mapKey)
			set lastRegisteredSeconds to _getRegisteredSeconds(mapKey)
			if lastRegisteredSeconds is missing value then return missing value
			
			set currentSeconds to do shell script "date +%s"
			set elapsed to (currentSeconds - lastRegisteredSeconds)
			if elapsed is greater than expirySeconds then return missing value
			
			cache's getValue(mapKey)
		end getValue
		
		on setValue(mapKey, newValue)
			cache's setValue(mapKey, newValue)
			set currentSeconds to do shell script "date +%s"
			cache's setValue(_epochTimestampKey(mapKey), currentSeconds)
			cache's setValue(_timestampKey(mapKey), current date)
		end setValue
		
		
		on deleteKey(mapKey)
			cache's deleteKey(mapKey)
			cache's deleteKey(_epochTimestampKey(mapKey))
			cache's deleteKey(_timestampKey(mapKey))
		end deleteKey
		
		
		on _getRegisteredSeconds(mapKey)
			cache's getValue(_epochTimestampKey(mapKey))
		end _getRegisteredSeconds
		
		on _epochTimestampKey(mapKey)
			mapKey & "-ets"
		end _epochTimestampKey
		
		on _timestampKey(mapKey)
			mapKey & "-ts"
		end _timestampKey
		
	end script
end new
