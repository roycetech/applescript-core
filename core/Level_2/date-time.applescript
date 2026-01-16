(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/Level_2/date-time

	@Last Modified: 2026-01-15 20:44:42
*)
use framework "Foundation"

use scripting additions
use script "core/Text Utilities"

use std : script "core/std"
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP:
		Manual: is24H
		File Prefix
		Now for ScreenShot
		Date Yesterday SQL

		Manual: Zulu Date
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()

	logger's infof("Current day of week: ", sut's getCurrentDayOfWeek())

	logger's infof("is24H: {}", sut's is24H())
	logger's infof("Current hour 24: {}", sut's getCurrentHour24())
	logger's infof("Current minutes: {}", sut's getCurrentMinutes())

	logger's infof("formatYyyyMmDd: {}", sut's formatYyyyMmDd(current date, missing value))
	logger's infof("formatYyyyDdMm: {}", sut's formatYyyyDdMm(current date, missing value))
	logger's infof("formatDdMmYyyy: {}", sut's formatDdMmYyyy(current date, missing value))
	logger's infof("formatMmDdYyyy: {}", sut's formatMmDdYyyy(current date, "/"))

	logger's infof("formatYyyyMmDdHHmi: {}", sut's formatYyyyMmDdHHmi(current date))
	logger's infof("formatYyyyMmDdHHmiWithSeparator: {}", sut's formatYyyyMmDdHHmiWithSeparator(current date, "-"))

	if caseIndex is 1 then

	else if caseIndex is 2 then

	else if caseIndex is 3 then
		-- log nowForScreenShot()

	else if caseIndex is 4 then
		log sut's formatDateSQL(yesterday())

	else if caseIndex is 5 then
		logger's infof("Result: {}", fromZuluDateText("2023-02-26T13:07:38Z"))

	end if

	spot's finish()
	logger's finish()
end spotCheck


on new()
	script DateTimeInstance
		property weekendDays : {Saturday, Sunday}

		-- For test-ability only.
		property _today : missing value


		on getCurrentDayOfWeek()
			weekday of today() as text
		end getCurrentDayOfWeek


		on getCurrentHour24()
			hours of today()
		end getCurrentHour24

		on getCurrentMinutes()
			minutes of today()
		end getCurrentMinutes


		on today()
			std's nvl(_today, current date)
		end today


		on todayMinusDays(numOfDays)
			today() - numOfDays * days
		end todayMinusDays


		(*
			@Deprecated. To be replaced with ISO date extractor.

			This is used by meeter. Implementation is not robust, redesign.

			@appleScriptDateTimeString - locale-specific AppleScript representation of
			the date and time string.

			@Known Issues:
				macOS Sonoma introduced a unicode space before the AM/PM.

			@returns time in the format: HH:mm:mi [AP]M
		*)
		on extractTimeFromDateTimeText(appleScriptDateTimeString)
			set passedDate to date appleScriptDateTimeString
			time string of passedDate
			_cleanTimeString(result)
		end extractTimeFromDateTimeText

		(*
			This is a workaround on macOS Sonoma introduced a unicode space before the AM/PM.
		*)
		on cleanTimeString(timeString)
			textUtil's removeUnicode(timeString as text)
			textUtil's replace(result, "PM", " PM")
			textUtil's replace(result, "AM", " AM")
		end cleanTimeString

		(*
			@Deprecated: Use cleanTimeString
		*)
		on _cleanTimeString(timeString)
			cleanTimeString(timeString)
		end _cleanTimeString

		on isWeekday()
			not isWeekend()
		end isWeekday


		on isWeekend()
			weekendDays contains (weekday of today())
		end isWeekend


		on isMorning()
			set sutTime to time string of today()
			set timeTokens to textUtil's split(_cleanTimeString(sutTime), ":")
			set apPmValue to last word of last item of timeTokens
			if {"AM", "PM"} contains the apPmValue then
				apPmValue is "AM"
			else -- 24H
				first item of timeTokens is less than 12
			end if
		end isMorning


		(* Checks the current time settings if it is using the 24-hour format. *)
		on is24H()
			set currentTimeText to time string of today()
			repeat with nextIndicator in {"AM", "PM"}
				if currentTimeText contains nextIndicator then return false

			end repeat
			true
		end is24H

		on isArvo()
			not isMorning()
		end isArvo


		on yesterday()
			(current date) - 1 * days
		end yesterday


		on tomorrow()
			(current date) + 1 * days
		end tomorrow


		on formatYyyyMmDd(pDate as date, delimiter)
			set calDelimiter to delimiter
			if delimiter is missing value then set calDelimiter to ""

			set currentMonth to month of pDate as integer
			if currentMonth is less than 10 then set currentMonth to "0" & currentMonth

			set currentDom to day of pDate as integer
			if currentDom is less than 10 then set currentDom to "0" & currentDom

			set currentYear to year of pDate as integer

			textUtil's join({currentYear, currentMonth, currentDom}, calDelimiter)
		end formatYyyyMmDd


		on formatYyyyMmDdHHmi(pDate as date)
			formatYyyyMmDdHHmiWithSeparator(pDate, "")
		end formatYyyyMmDdHHmi


		on formatYyyyMmDd_HHmi(pDate as date)
			formatYyyyMmDdHHmiWithSeparator(pDate, "_")
		end formatYyyyMmDd_HHmi


		on formatYyyyMmDdHHmiWithSeparator(pDate as date, separator)
			set calcSeparator to separator
			if separator is missing value then set calcSeparator to ""

			set currentHours to hours of pDate as integer
			if currentHours is less than 10 then set currentHours to "0" & currentHours

			set currentMinutes to minutes of pDate as integer
			if currentMinutes is less than 10 then set currentMinutes to "0" & currentMinutes

			textUtil's join({formatYyyyMmDd(pDate, "") & calcSeparator, currentHours, currentMinutes}, "")
		end formatYyyyMmDdHHmiWithSeparator


		on formatYyyyDdMm(pDate as date, delimiter)
			set currentMonth to month of pDate as integer
			if currentMonth is less than 10 then set currentMonth to "0" & currentMonth

			set currentDom to day of pDate as integer
			if currentDom is less than 10 then set currentDom to "0" & currentDom

			set currentYear to year of pDate as integer

			textUtil's join({currentYear, currentDom, currentMonth}, delimiter)
		end formatYyyyDdMm


		on formatMmDdYyyy(pDate as date, delimiter)
			set currentMonth to month of pDate as integer
			if currentMonth is less than 10 then set currentMonth to "0" & currentMonth

			set currentDom to day of pDate as integer
			if currentDom is less than 10 then set currentDom to "0" & currentDom

			set currentYear to year of pDate as integer

			textUtil's join({currentMonth, currentDom, currentYear}, delimiter)
		end formatMmDdYyyy


		on formatDdMmYyyy(pDate as date, delimiter)
			set currentMonth to month of pDate as integer
			if currentMonth is less than 10 then set currentMonth to "0" & currentMonth

			set currentDom to day of pDate as integer
			if currentDom is less than 10 then set currentDom to "0" & currentDom

			set currentYear to year of pDate as integer

			textUtil's join({currentDom, currentMonth, currentYear}, delimiter)
		end formatDdMmYyyy


		on formatYyMmDd(pDate as date)
			text 3 thru -1 of formatYyyyMmDd(pDate, "")
		end formatYyMmDd


		on formatDateSQL(pDate as date)
			formatYyyyMmDd(pDate, "-")
		end formatDateSQL


		(*
			FROM MacScripter.net
			e.g. getDatesTime(current date)
		*)
		on getDatesTime(theDate)
			time of (theDate) as integer
		end getDatesTime


		on fromZuluDateText(zuluDateText)
			if zuluDateText is missing value then return missing value

			set dateFormatter to current application's NSDateFormatter's new()
			dateFormatter's setLocale:(current application's NSLocale's localeWithLocaleIdentifier:"en_US_POSIX")
			dateFormatter's setDateFormat:"yyyy-MM-dd'T'HH:mm:ssX"

			-- Parse as UTC
			dateFormatter's setTimeZone:(current application's NSTimeZone's timeZoneWithAbbreviation:"UTC")
			set dateObject to dateFormatter's dateFromString:zuluDateText
			if dateObject is missing value then return missing value

			-- Convert to AppleScript date (local time automatically)
			return dateObject as date
		end fromZuluDateText
	end script
end new
