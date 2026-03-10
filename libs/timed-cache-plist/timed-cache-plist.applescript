(*
	@Example:
		use timedCacheLib : script "core/timed-cache-plist"
		set timedCache to timedCacheLib's new(2)

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh libs/timed-cache-plist/timed-cache-plist

	@Unit Test
		Test timed-cache-plist

	@Change Logs:
		Tue, Mar 03, 2026, at 10:50:53 AM - Fix breakage.
		Sun, Jan 11, 2026, at 03:36:29 PM - Switched to using shell script because setValue of plutil is storing the local time instead of UTC.
*)

use scripting additions


use loggerFactory : script "core/logger-factory"

use plutilLib : script "core/plutil"

property logger : missing value

(* Set a default cache name, that will contain the expiring cached values. *)
property PLIST_TIMED_CACHE : "timed-cache"

property SUFFIX_EPOCH_TIMESTAMP : "-ets"
property SUFFIX_TIMESTAMP : "-ts"

property DATE_FORMAT_PARAMETER : "%Y-%m-%dT%H:%M:%SZ"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		First
		Manual: Set Value
		Manual: _getRegisteredSeconds
	")

	set spotScript to script "core/spot-test"
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
		sut's setValue("spot-key", "spot-value")

	else if caseIndex is 3 then
		logger's infof("Invocation 1 result: {}", sut's _getRegisteredSeconds(missing value))
		logger's infof("Invocation 2 result: {}", sut's _getRegisteredSeconds("Unicorn"))
		logger's infof("Invocation 3 result: {}", sut's _getRegisteredSeconds(""))

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new(pExpirySeconds)
	set plutil to plutilLib's new()
	if not plutil's plistExists(PLIST_TIMED_CACHE) then
		plutil's createNewPList(PLIST_TIMED_CACHE)
	end if
	set localCache to plutil's new(PLIST_TIMED_CACHE)

	script TimedCacheInstance
		property expirySeconds : pExpirySeconds
		property cache : localCache

		(*
			Improves reliability by adding some delay after running the shell
			command. Explore use of verification instead in the future.
		*)
		property writeCooldown : 0.1

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

			try
				return cache's getValue(mapKey)
			end try

			missing value
		end getValue


		on setValue(mapKey, newValue)
			cache's setValue(mapKey, newValue)
			set currentSeconds to (do shell script "date +%s") as real
			cache's setValue(_epochTimestampKey(mapKey), currentSeconds)
			-- cache's setValue(_timestampKey(mapKey), current date)  -- TO FIX, it is not being stored as UTC date.

			-- set shellCommand to "plutil -replace " & _timestampKey(mapKey) & " -date \"$(date -u +'%Y-%m-%dT%H:%M:%SZ')\" ~/applescript-core/" & PLIST_TIMED_CACHE & ".plist"
			set quotedKey to cache's _quotePlistKey(_timestampKey(mapKey))
			set shellCommand to "plutil -replace " & quotedKey & " -date \"$(date -u +'" & DATE_FORMAT_PARAMETER & "')\" ~/applescript-core/" & PLIST_TIMED_CACHE & ".plist"

			do shell script shellCommand
			delay writeCooldown
		end setValue


		on deleteKey(mapKey)
			if mapKey is missing value then return missing value

			cache's deleteKey(mapKey)
			cache's deleteKey(_epochTimestampKey(mapKey))
			cache's deleteKey(_timestampKey(mapKey))
			delay writeCooldown  -- Fix intermittent error where the key is still read from the plist.
		end deleteKey


		on _getRegisteredSeconds(mapKey)
			if mapKey is missing value then return missing value

			set epochTsKey to _epochTimestampKey(mapKey)
			-- logger's debugf("_getRegisteredSeconds: epochTsKey: {}", epochTsKey)
			cache's getValue(epochTsKey)
		end _getRegisteredSeconds

		on _epochTimestampKey(mapKey)
			mapKey & SUFFIX_EPOCH_TIMESTAMP
		end _epochTimestampKey

		on _timestampKey(mapKey)
			-- localCache's _quotePlistKey(mapKey & "-ts")
			mapKey & SUFFIX_TIMESTAMP
		end _timestampKey
	end script
end new
