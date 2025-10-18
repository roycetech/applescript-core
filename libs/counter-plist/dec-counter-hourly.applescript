(*
	@Purpose:

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh libs/counter-plist/dec-counter-hourly

	@Created: Fri, Oct 10, 2025 at 08:11:21 AM
	@Last Modified: 2025-10-17 15:04:44
	@Change Logs:
*)
use scripting additions
use script "core/Text Utilities"

use loggerFactory : script "core/logger-factory"

use plutilLib : script "core/plutil"

property logger : missing value

property plutil : missing value

property countHourlySuffix : "-hourly"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Increment this hour
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	-- activate application ""
	set sutLib to script "core/counter"
	set sutPlist to "spot-counter"
	set sut to sutLib's new(sutPlist)
	set sut to decorate(sut)

	set sutKey to "spot-key"

	logger's debugf("Test Key: {}", sutKey)

	logger's info("Before run -------------------------------")
	logger's infof("totalAll: {}", sut's totalAll(sutKey))
	logger's infof("totalThisHour: {}", sut's totalThisHour(sutKey))
	logger's infof("hasRunThisHour: {}", sut's hasRunThisHour(sutKey))
	logger's infof("hasNotRunThisHour: {}", sut's hasNotRunThisHour(sutKey))

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's incrementThisHour(sutKey)

	else if caseIndex is 3 then

	else

	end if

	logger's info("After run -------------------------------")
	logger's infof("totalThisHour: {}", sut's totalThisHour(sutKey))
	logger's infof("hasRunThisHour: {}", sut's hasRunThisHour(sutKey))
	logger's infof("hasNotRunThisHour: {}", sut's hasNotRunThisHour(sutKey))

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set plutil to plutilLib's new()

	set countHourlyName to _createPlistIfMissing(mainScript's plistName & countHourlySuffix)

	script CounterHourlyDecorator
		property parent : mainScript
		property countHourly : plutil's new(countHourlyName)

		(* @returns the incremented value for the current hour. *)
		on incrementThisHour(theKey)
			if theKey is missing value then return missing value

			parent's increment(theKey)

			set todayDate to _formatDate(short date string of (current date))
			set todayHour to todayDate & "_" & _extractHour(time string of (current date))
			set keyThisHour to format {"{}-{}", {theKey, todayHour}}
			set keyThisHourCount to countHourly's getInt(keyThisHour)
			if keyThisHourCount is missing value then set keyThisHourCount to 0
			set keyThisHourCount to keyThisHourCount + 1
			countHourly's setValue(keyThisHour, keyThisHourCount)
			keyThisHourCount
		end incrementThisHour


		on totalThisHour(theKey)
			if theKey is missing value then return missing value

			set currentDate to current date
			set todayDate to parent's _formatDate(short date string of currentDate)
			set todayHour to todayDate & "_" & _extractHour(time string of currentDate)
			-- logger's debugf("todayHour: {}", todayHour)

			set keyThisHour to format {"{}-{}", {theKey, todayHour}}
			logger's debugf("keyThisHour: {}", keyThisHour)

			set theCount to countHourly's getInt(keyThisHour)
			if theCount is missing value then return 0
			if my useDoubleDigits and theCount is less than 10 then return "0" & theCount

			theCount
		end totalThisHour


		on hasRunThisHour(theKey)
			totalThisHour(theKey) is greater than 0
		end hasRunThisHour


		on hasNotRunThisHour(theKey)
			hasRunThisHour(theKey) is false
		end hasNotRunThisHour


		(*
			TODO: Test/implement for 12/24 hour settings.
			Cases:
				12h -
		*)
		on _extractHour(timeString)
			if timeString is missing value then return missing value

			set amPm to text -2 thru -1 of timeString
			set timeHour to the first word of timeString
			if timeHour as integer is less than 10 then return "0" & timeHour & amPm

			timeHour & amPm
		end _extractHour
	end script
end decorate


(*
	WET 2/3: counter.applescript
	@returns the plistName, for convenience.
*)
on _createPlistIfMissing(plistName)
	if plutil's plistExists(plistName) then return plistName

	plutil's createNewPList(plistName)
	plistName
end _createPlistIfMissing
