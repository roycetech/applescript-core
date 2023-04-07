global std, config, dt
global CACHE

(*
	set tcache to std's import("timed-cache-plist")

	@Install:
		make install-timed-cache

	@References:
		* config.plist - Timed Cache List
		* timed-cache.plist
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "timed-cache-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	set integTest to std's import("unit-test")'s new()
	set cases to listUtil's splitByLine("
		Integration Testing
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
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
		
		done()
		
		set sut to new(2)
		sut's setValue(spotKey, "Will expire")
		log sut's getValue(spotKey)
		log CACHE's getValue(spotKey)
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new(pExpirySeconds)
	script TimedCacheInstance
		property expirySeconds : pExpirySeconds
		
		(* @return missing value if the content has expired, so client can reset it again. *)
		on getValue(mapKey)
			set lastRegisteredSeconds to _getRegisteredSeconds(mapKey)
			if lastRegisteredSeconds is missing value then return missing value
			
			set currentSeconds to do shell script "date +%s"
			set elapsed to (currentSeconds - lastRegisteredSeconds)
			if elapsed is greater than expirySeconds then return missing value
			
			CACHE's getValue(mapKey)
		end getValue
		
		on setValue(mapKey, newValue)
			CACHE's setValue(mapKey, newValue)
			set currentSeconds to do shell script "date +%s"
			CACHE's setValue(_epochTimestampKey(mapKey), currentSeconds)
			CACHE's setValue(_timestampKey(mapKey), current date)
		end setValue
		
		
		on deleteKey(mapKey)
			CACHE's deleteKey(mapKey)
			CACHE's deleteKey(_epochTimestampKey(mapKey))
			CACHE's deleteKey(_timestampKey(mapKey))
		end deleteKey
		
		
		on _getRegisteredSeconds(mapKey)
			CACHE's getValue(_epochTimestampKey(mapKey))
		end _getRegisteredSeconds
		
		on _epochTimestampKey(mapKey)
			mapKey & "-ets"
		end _epochTimestampKey
		
		on _timestampKey(mapKey)
			mapKey & "-ts"
		end _timestampKey
		
	end script
end new

-- Private Codes below =======================================================


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("timed-cache-plist")
	set dt to std's import("date-time")
	
	set plutil to std's import("plutil")'s new()
	set cacheName to "timed-cache"
	if not plutil's plistExists(cacheName) then
		plutil's createNewPList(cacheName)
	end if
	
	set CACHE to plutil's new(cacheName)
end init
