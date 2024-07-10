(*
	use tcache : script "core/timed-cache-plist"

	@Build:
		make install-timed-cache

	@Plists:
		config.plist
		 	Timed Cache List - Can't find the reference for this - June 30, 2023 11:17 AM
		timed-cache.plist - Contains the cached values.

	@Unit Test
		Test timed-cache-plist
*)

use scripting additions

use listUtil : script "core/list"
use loggerFactory : script "core/logger-factory"

use plutilLib : script "core/plutil"

use spotScript : script "core/spot-test"

property logger : missing value
(* Set a default cache name. *)
property cacheName : "timed-cache"
-- property cache : missing value


if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		First
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()

	if caseIndex is 0 then
		return
	end if

	set sut to new(0)
	if caseIndex is 1 then
		logger's infof("Retrieve non existing value: {}", sut's getValue("Unicorn"))
		logger's infof("Delete non existing value: {}", sut's deleteKey("Unicorn"))
		sut's setValue("Present", true)

	else if caseIndex is 2 then

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new(pExpirySeconds)
	set plutil to plutilLib's new()
	if not plutil's plistExists(cacheName) then
		plutil's createNewPList(cacheName)
	end if
	set localCache to plutil's new(cacheName)

	script TimedCacheInstance
		property expirySeconds : pExpirySeconds
		property cache : localCache

		(* @return missing value if the content has expired, so client can reset it again. *)
		on getValue(mapKey)
			set lastRegisteredSeconds to _getRegisteredSeconds(mapKey)
			if lastRegisteredSeconds is missing value then return missing value

			set currentSeconds to do shell script "date +%s"
			set elapsed to (currentSeconds - lastRegisteredSeconds)
			if elapsed is greater than expirySeconds then
				deleteKey(mapKey)
				return missing value
			end if

			cache's getValue(mapKey)
		end getValue

		on setValue(mapKey, newValue)
			cache's setValue(mapKey, newValue)
			set currentSeconds to (do shell script "date +%s") as real
			cache's setValue(_epochTimestampKey(mapKey), currentSeconds)
			cache's setValue(_timestampKey(mapKey), current date)
		end setValue


		on deleteKey(mapKey)
			if mapKey is missing value then return missing value

			cache's deleteKey(mapKey)
			cache's deleteKey(_epochTimestampKey(mapKey))
			cache's deleteKey(_timestampKey(mapKey))
		end deleteKey


		on _getRegisteredSeconds(mapKey)
			if mapKey is missing value then return missing value

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
