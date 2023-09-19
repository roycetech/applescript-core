(*
	@Build:
		make compile-lib SOURCE=core/date-time

	@Last Modified: 2023-09-18 22:33:40
*)
use framework "Foundation"

use scripting additions

use script "core/Text Utilities"
use std : script "core/std"

use textUtil : script "core/string"
use listUtil : script "core/list"
use regex : script "core/regex"

use loggerFactory : script "core/logger-factory"

use spotScript : script "core/spot-test"

property logger : missing value
property timeBufferMin : 2

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: is24H
		File Prefix
		Now for ScreenShot
		Date Yesterday SQL
		Manual: Zulu Date
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()
	if caseIndex is 1 then
		logger's infof("is24H: {}", sut's is24H())

	else if caseIndex is 2 then
		log formatYyyyMmDd(current date)

	else if caseIndex is 3 then
		log nowForScreenShot()

	else if caseIndex is 4 then
		log formatDateSQL(yesterday())

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

			@returns time in the format: HH:mm:mi [AP]M
		*)
		on extractTimeFromDateTimeText(appleScriptDateTimeString)
			set passedDate to date appleScriptDateTimeString
			time string of passedDate
		end extractTimeFromDateTimeText




		on isWeekday()
			not isWeekend()
		end isWeekday


		on isWeekend()
			weekendDays contains (weekday of today())
		end isWeekend


		on isMorning()
			set sutTime to time string of today()
			set timeTokens to textUtil's split(sutTime, ":")
			if {"AM", "PM"} contains the last word of sutTime then
				last word of sutTime is "AM"
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
			set currentMonth to month of pDate as integer
			if currentMonth is less than 10 then set currentMonth to "0" & currentMonth

			set currentDom to day of pDate as integer
			if currentDom is less than 10 then set currentDom to "0" & currentDom

			set currentYear to year of pDate as integer

			listUtil's join({currentYear, currentMonth, currentDom}, delimiter)
		end formatYyyyMmDd


		on formatYyyyMmDdHHmi(pDate as date)
			set currentHours to hours of pDate as integer
			if currentHours is less than 10 then set currentHours to "0" & currentHours

			set currentMinutes to minutes of pDate as integer
			if currentMinutes is less than 10 then set currentMinutes to "0" & currentMinutes

			listUtil's join({formatYyyyMmDd(pDate, ""), currentHours, currentMinutes}, "")
		end formatYyyyMmDdHHmi


		on formatYyyyDdMm(pDate as date, delimiter)
			set currentMonth to month of pDate as integer
			if currentMonth is less than 10 then set currentMonth to "0" & currentMonth

			set currentDom to day of pDate as integer
			if currentDom is less than 10 then set currentDom to "0" & currentDom

			set currentYear to year of pDate as integer

			listUtil's join({currentYear, currentDom, currentMonth}, delimiter)
		end formatYyyyDdMm


		on formatMmDdYyyy(pDate as date, delimiter)
			set currentMonth to month of pDate as integer
			if currentMonth is less than 10 then set currentMonth to "0" & currentMonth

			set currentDom to day of pDate as integer
			if currentDom is less than 10 then set currentDom to "0" & currentDom

			set currentYear to year of pDate as integer

			listUtil's join({currentMonth, currentDom, currentYear}, delimiter)
		end formatMmDdYyyy



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
			dateFormatter's setDateFormat:"yyyy-MM-dd'T'HH:mm:ssZ"
			set dateObject to dateFormatter's dateFromString:zuluDateText

			set localTimeZone to current application's NSTimeZone's localTimeZone()
			dateFormatter's setTimeZone:localTimeZone
			set localDate to dateFormatter's stringFromDate:dateObject

			set {datePart, timePart} to textUtil's split(localDate as text, "T")
			set tzOffset to do shell script "date +'%z' | cut -c 2,3"
			set timePart to textUtil's replace(timePart, "+" & tzOffset & "00", "")
			set dateTokens to textUtil's split(datePart, "-")
			set {hourPart, minutePart, secondPart} to textUtil's split(timePart, ":")

			set amPm to "AM"
			if hourPart is greater than or equal to 12 then
				set amPm to "PM"
				set hourPart to hourPart - 12
			end if

			set parsableDate to 2nd item of dateTokens & "-" & 3rd item of dateTokens & "-" & first item of dateTokens & " " & hourPart & ":" & minutePart & ":" & secondPart & " " & amPm
			date parsableDate
		end fromZuluDateText
	end script
end new

