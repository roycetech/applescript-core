(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh libs/counter-plist/dec-counter-daily

	@Created: Thu, Oct 16, 2025 at 01:58:11 PM
	@Last Modified: 2025-10-17 06:35:20
	@Change Logs:
*)
use scripting additions
use script "core/Text Utilities"

use loggerFactory : script "core/logger-factory"

use plutilLib : script "core/plutil"

property logger : missing value

property plutil : missing value

property countDailySuffix : "-daily"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Increment Daily
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
	logger's infof("totalToday: {}", sut's totalToday(sutKey))
	logger's infof("hasRunToday: {}", sut's hasRunToday(sutKey))
	logger's infof("hasNotRunToday: {}", sut's hasNotRunToday(sutKey))


	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's incrementDaily(sutKey)

	else if caseIndex is 3 then

	else

	end if

	logger's info("After run -------------------------------")
	logger's infof("totalToday: {}", sut's totalToday(sutKey))
	logger's infof("hasRunToday: {}", sut's hasRunToday(sutKey))
	logger's infof("hasNotRunToday: {}", sut's hasNotRunToday(sutKey))

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set plutil to plutilLib's new()

	set countDailyName to _createPlistIfMissing(mainScript's plistName & countDailySuffix)

	script CounterDailyDecorator
		property parent : mainScript
		property countDaily : plutil's new(countDailyName)

		(* @returns the incremented value for the current day. *)
		on incrementDaily(theKey)
			parent's increment(theKey)

			set todayDate to _formatDate(short date string of (current date))
			set keyToday to format {"{}-{}", {theKey, todayDate}}
			set keyTodayCount to countDaily's getInt(keyToday)
			if keyTodayCount is missing value then set keyTodayCount to 0
			set keyTodayCount to keyTodayCount + 1
			countDaily's setValue(keyToday, keyTodayCount)
			keyTodayCount
		end incrementDaily


		on totalToday(theKey)
			if theKey is missing value then return false

			set todayDate to _formatDate(short date string of (current date))
			set keyToday to format {"{}-{}", {theKey, todayDate}}

			set theCount to countDaily's getInt(keyToday)
			if theCount is missing value then return 0
			if my useDoubleDigits and theCount is less than 10 then return "0" & theCount

			theCount
		end totalToday


		on hasRunToday(theKey)
			if theKey is missing value then return false

			totalToday(theKey) is greater than 0
		end hasRunToday

		on hasNotRunToday(theKey as text)
			hasRunToday(theKey) is false
		end hasNotRunToday


		(* @scriptName - e.g. "Arrange Windows" *)
		on hasScriptRunToday(scriptName)
			if theKey is missing value then return false
			set keyToday to format {"Running: [{}.applescript]", my _stripExtension(scriptName)}

			totalToday(keyToday) is greater than 0
		end hasScriptRunToday

		(* @scriptName - e.g. "Arrange Windows" *)
		on totalScriptRunToday(scriptName)
			if theKey is missing value then return false
			set keyToday to format {"Running: [{}.applescript]", my _stripExtension(scriptName)}

			totalToday(keyToday)
		end totalScriptRunToday


		-- Private Codes below ======================================================
		(* Default format date to yyyyMMdd. Will break by year 3000, i'll be long dead by then and this script buried in archive or deleted. *)
		on _formatDate(dateString)
			"20" & last word of dateString & "/" & first word of dateString & "/" & second word of dateString
		end _formatDate


		on _stripExtension(scriptName)
			if scriptName ends with ".applescript" then set scriptName to text 1 thru ((length of scriptName) - (length of ".applescript")) of scriptName
			scriptName
		end _stripExtension
	end script
end decorate


(*
	WET 3/3: counter.applescript
	@returns the plistName, for convenience.
*)
on _createPlistIfMissing(plistName)
	if plutil's plistExists(plistName) then return plistName

	plutil's createNewPList(plistName)
	plistName
end _createPlistIfMissing
