(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh libs/counter-plist/counter

	@Usage:
		use counterLib : script "core/counter"
		set counter to counterLib's newWithPlist("plist-name") or set counter to counterLib's new()

	TODO:
		Extract daily counter.

	@Change Logs:
		Thu, Jul 17, 2025 at 08:46:42 AM - Allow double digit padding.

	PList Design:

	Each entry will need to update the following keys:
	Keys:
		1. KeyName-yyyy/MM/dd=<count>
		2. KeyName=<count>
		3. Date=<array of KeyNames>
		4. All Dates
		5. All Keys - is this useful?

	UPDATE:
		Removed logging to countDailyList because plutil is crashing due to the data size.
*)
use scripting additions
use script "core/Text Utilities"

use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"

use plutilLib : script "core/plutil"
use decoratorCounterDaily : script "core/dec-counter-daily"
use decoratorCounterHourly : script "core/dec-counter-hourly"

property logger : missing value

property plutil : missing value

property countKeysSuffix : "-all-keys"
property countTotalSuffix : "-total"
property DEFAULT_PLIST : "counter-default"

property TopLevel : me


if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Total
		Increment
		Clear
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if


	set sutPlist to "spot-counter"
	set sutKey to "spot-key"
	set sut to new(sutPlist)

	logger's debugf("Test Key: {}", sutKey)

	logger's info("Before run -------------------------------")
	logger's infof("totalAll: {}", sut's totalAll(sutKey))
	logger's infof("Integration: totalToday: {}", sut's totalToday(sutKey))
	logger's infof("Integration: totalThisHour: {}", sut's totalToday(sutKey))

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's increment(sutKey)

	else if caseIndex is 3 then
		sut's clear(sutKey)

	end if

	logger's info("After run -------------------------------")
	logger's infof("totalAll: {}", sut's totalAll(sutKey))
	logger's infof("hasRun: {}", sut's hasRun(sutKey))
	logger's infof("Integration: totalToday: {}", sut's totalToday(sutKey))
	logger's infof("Integration: totalThisHour: {}", sut's totalThisHour(sutKey))

	spot's finish()
	logger's finish()

	(*
	log hasScriptRunToday(theKey)

	log isNthRun(theKey, 4)
	log hasRun(theKey)
	log hasNotRunToday(theKey)

	log hasScriptRunToday("Arrange Windows")

	log "Count total is: " & totalAll(theKey)
	log "Count today is: " & totalToday(theKey)
*)

end spotCheck


on new()
	newWithPlist(DEFAULT_PLIST)
end newDefault


on newWithPlist(pPlistName)
	loggerFactory's inject(me)
	set plutil to plutilLib's new()

	if pPlistName is missing value then set pPlistName to DEFAULT_PLIST

	-- set countDailyName to _createPlistIfMissing(pPlistName & countDailySuffix)
	set countKeysName to _createPlistIfMissing(pPlistName & countKeysSuffix)
	set countTotalName to _createPlistIfMissing(pPlistName & countTotalSuffix)

	script CounterInstance
		property plistName : pPlistName
		-- property countDaily : plutil's new(countDailyName)
		property countKeys : plutil's new(countKeysName)
		property countTotal : plutil's new(countTotalName)
		property useDoubleDigits : false

		(* @returns the incremented value for the current day. *)
		on increment(theKey)
			-- set todayDate to _formatDate(short date string of (current date))

			set keyCount to countTotal's getInt(theKey)
			if keyCount is missing value then set keyCount to 0
			set keyCount to keyCount + 1
			countTotal's setValue(theKey, keyCount)
			keyCount

			(*
			set keyToday to format {"{}-{}", {theKey, todayDate}}
			set keyTodayCount to countDaily's getInt(keyToday)
			if keyTodayCount is missing value then set keyTodayCount to 0
			set keyTodayCount to keyTodayCount + 1
			countDaily's setValue(keyToday, keyTodayCount)
			keyTodayCount
			*)
		end increment


		(*  *)
		on totalAll(theKey)
			-- logger's debugf("theKey: {}", theKey)
			set theCount to countTotal's getInt(theKey)
			if theCount is missing value then return 0
			if useDoubleDigits and theCount is less than 10 then return "0" & theCount

			theCount
		end totalAll


		(*
			Useful if you want lets say to do something every nth run.

			@nth - a positive integer.
			@return boolean.
		*)
		on isNthRun(theKey as text, nth as integer)
			assertThat of std given condition:nth is greater than 0, messageOnFail:format {"The nth:{} must be a positive integer", nth}

			set totalCount to countTotal's getInt(theKey)
			if the totalCount is missing value then return false

			totalCount mod nth is 0
		end isNthRun


		on clear(theKey)
			set todayDate to _formatDate(short date string of (current date))
			set keyToday to format {"{}-{}", {theKey, todayDate}}
			countTotal's setValue(theKey, 0)
			-- countDaily's setValue(keyToday, 0)
		end clear


		(* TODO: *)
		on clearRun(theKey)
			-- _setValue(theKey, missing value)
		end clearRun

		on hasRun(theKey)
			totalAll(theKey) is greater than 0
		end hasRun
	end script

	decoratorCounterDaily's decorate(result)
	decoratorCounterHourly's decorate(result)
end new


(*
	WET 1/3: dec-counter-dailly.applescript, dec-counter-hourly.applescript
	@returns the plistName, for convenience.
*)
on _createPlistIfMissing(plistName)
	if plutil's plistExists(plistName) then return plistName

	plutil's createNewPList(plistName)
	plistName
end _createPlistIfMissing
