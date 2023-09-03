(*
	use tcache : script "timed-cache-plist"

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

use listUtil : script "list"
use loggerFactory : script "logger-factory"

use plutilLib : script "plutil"

property logger : missing value
(* Set a default cache name. *)
property cacheName : "timed-cache"
-- property cache : missing value


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
