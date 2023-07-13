(*
	@Build:
		make compile-lib SOURCE=core/date-time

	@Last Modified: 2023-07-13 21:07:07
*)
use framework "Foundation"

use scripting additions

use script "Core Text Utilities"

use loggerFactory : script "logger-factory"
use textUtil : script "string"
use regex : script "regex"
use listUtil : script "list"
use spotScript : script "spot-test"
use testLib : script "test"

property logger : missing value
property timeBufferMin : 2

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	
	logger's start()
	
	set cases to listUtil's splitByLine("
		Run unit tests
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
	
	if caseIndex is 1 then
		unitTest()
		
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


on extractTimeFromDateTimeText(dateTimeString)
	set hhMMssAmPm to regex's firstMatchInString("\\d{1,2}:\\d{2}:\\d{2}\\s[AP]M$", dateTimeString)
	
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to ":"
	set hhMMssAmPmColonTokens to every text item of hhMMssAmPm
	set AppleScript's text item delimiters to oldDelimiters
	
	item 1 of hhMMssAmPmColonTokens & ":" & item 2 of hhMMssAmPmColonTokens & " " & text -2 thru -1 of hhMMssAmPm
end extractTimeFromDateTimeText


(*
	@returns the next date rounded up by 30 minutes. e.g. 7:30, 8:00,...
*)
on next30MinuteSlot(pDateTime as date)
	set timeString to time string of pDateTime
	-- logger's debugf("timeString: {}", timeString)
	
	set dayAdjust to 0
	
	set {hh, mi, ss, amPm} to words of timeString
	
	if mi + timeBufferMin is less than 30 then
		set mi to 30
	else
		set hh to (hh as integer) + 1
		if hh < 10 then set hh to "0" & hh
		set mi to "00"
		set amPm to "AM"
		if hh is equal to 12 and amPm is "AM" then set hh to "00"
	end if
	
	set calcTime to format {"{}:{}:00 {}", {hh, mi, amPm}}
	if hh is equal to "00" and mi is equal to "00" then set dayAdjust to 1 * days
	
	set dateTimeString to (date string of pDateTime) & " " & calcTime
	
	(date dateTimeString) + dayAdjust
end next30MinuteSlot

on nextHourSlot(pDateTime as date)
	set timeString to time string of pDateTime
	set dayAdjust to 0
	
	set {hh, mi, ss, amPm} to words of timeString
	
	if mi + timeBufferMin is greater than or equal to 60 then
		set hh to (hh as integer) + 1
	end if
	
	set hh to (hh as integer) + 1
	if hh < 10 then set hh to "0" & hh
	set mi to "00"
	set amPm to "AM"
	if hh is equal to 12 and amPm is "AM" then set hh to "00"
	
	set calcTime to format {"{}:{}:00 {}", {hh, mi, amPm}}
	if hh is equal to "00" and mi is equal to "00" then set dayAdjust to 1 * days
	
	set dateTimeString to (date string of pDateTime) & " " & calcTime
	(date dateTimeString) + dayAdjust
end nextHourSlot


(*
	@returns date and time in the format MMdd-HHmm
*)
on nowForScreenShot()
	set now to current date
	set dateString to short date string of now
	
	set myMonth to (first word of dateString) as integer
	if myMonth is less than 10 then set myMonth to "0" & myMonth
	
	set myDom to (second word of dateString) as integer
	if myDom is less than 10 then set myDom to "0" & myDom
	
	set timeString to time string of now
	
	set myHour to (first word of timeString) as integer
	if myHour is less than 10 then set myHour to "0" & myHour
	
	set myMin to (second word of timeString) as integer
	if myMin is less than 10 then set myMin to "0" & myMin
	
	format {"{}{}-{}{}", {myMonth, myDom, myHour, myMin}}
end nowForScreenShot

on todayMinusDays(numOfDays)
	today() - numOfDays * days
end todayMinusDays

on isWorkHour()
	set timeString to time string of (current date)
	_isWorkTime(timeString)
end isWorkHour

on nextWorkTime()
	set timeString to time string of (current date)
	_nextWorkTime(timeString)
end nextWorkTime

on isWeekday()
	not isWeekend()
end isWeekday


on isWeekend()
	set WEEKEND to {Saturday, Sunday}
	WEEKEND contains (weekday of (current date))
end isWeekend


on isMorning()
	set sutTime to time string of (current date)
	set timeTokens to textUtil's split(sutTime, ":")
	if {"AM", "PM"} contains the last word of sutTime then
		last word of sutTime is "AM"
	else -- 24H
		first item of timeTokens is less than 12
	end if
end isMorning


on isArvo()
	not isMorning()
end isArvo


on today()
	current date
end today


on yesterday()
	(current date) - 1 * days
end yesterday

on tomorrow()
	(current date) + 1 * days
end tomorrow

on nextWorkHour()
	
end nextWorkHour


on formatYyyyMmDd(pDate as date, delimiter)
	set dateString to short date string of pDate
	
	set myMonth to (first word of dateString) as integer
	if myMonth is less than 10 then set myMonth to "0" & myMonth
	
	set myDom to (second word of dateString) as integer
	if myDom is less than 10 then set myDom to "0" & myDom
	
	listUtil's join({"20" & last word of dateString, myMonth, myDom}, delimiter)
end formatYyyyMmDd


on formatYyyyMmDdHHmi(pDate as date)
	set dateString to short date string of pDate
	
	set myMonth to (first word of dateString) as integer
	if myMonth is less than 10 then set myMonth to "0" & myMonth
	
	set myDom to (second word of dateString) as integer
	if myDom is less than 10 then set myDom to "0" & myDom
	
	listUtil's join({"20" & last word of dateString, myMonth, myDom}, delimiter)
end formatYyyyMmDdHHmi


on formatYyyyDdMm(pDate as date, delimiter)
	set dateString to short date string of pDate
	
	set myMonth to (first word of dateString) as integer
	if myMonth is less than 10 then set myMonth to "0" & myMonth
	
	set myDom to (second word of dateString) as integer
	if myDom is less than 10 then set myDom to "0" & myDom
	
	listUtil's join({"20" & last word of dateString, myDom, myMonth}, delimiter)
end formatYyyyDdMm


on formatMmDdYyyy(pDate as date, delimiter)
	set dateString to short date string of pDate
	
	set myMonth to (first word of dateString) as integer
	if myMonth is less than 10 then set myMonth to "0" & myMonth
	
	set myDom to (second word of dateString) as integer
	if myDom is less than 10 then set myDom to "0" & myDom
	
	listUtil's join({myMonth, myDom, "20" & last word of dateString}, delimiter)
end formatMmDdYyyy



on formatYyMmDd(pDate as date)
	text 3 thru -1 of formatYyyyMmDd(pDate, "")
end formatYyMmDd


on formatDateSQL(pDate as date)
	set dateString to short date string of pDate
	
	set myMonth to (first word of dateString) as integer
	if myMonth is less than 10 then set myMonth to "0" & myMonth
	
	set myDom to (second word of dateString) as integer
	if myDom is less than 10 then set myDom to "0" & myDom
	
	format {"20{}-{}-{}", {last word of dateString, myMonth, myDom}}
end formatDateSQL


(*
	FROM MacScripter.net
	e.g. getDatesTime(current date)
*)
on getDatesTime(theDate)
	time of (theDate) as integer
end getDatesTime


on fromZuluDateText(zuluDateText)
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
	set {hourPart, minPart, secsPart} to textUtil's split(timePart, ":")
	
	set amPm to "AM"
	if hourPart is greater than or equal to 12 then
		set amPm to "PM"
		set hourPart to hourPart - 12
	end if
	
	set parsableDate to 2nd item of dateTokens & "-" & 3rd item of dateTokens & "-" & first item of dateTokens & " " & hourPart & ":" & minPart & " " & amPm
	date parsableDate
end fromZuluDateText


-- Private Codes below =======================================================

(* Find the next work time by 5 minute increments. *)
on _nextWorkTime(timeString as text)
	set givenDate to date timeString
	set nextWorkTime to givenDate
	
	repeat
		set timeString to time string of nextWorkTime
		if _isWorkTime(timeString) then return nextWorkTime
		set nextWorkTime to nextWorkTime + 5 * minutes
	end repeat
end _nextWorkTime

(* @return true when 7 - 9pm *)
on _isWorkTime(timeString as text)
	set hour to first word of timeString as integer
	if timeString ends with "M" then -- A/PM is present
		if timeString ends with "AM" then
			return hour is greater than or equal to 7 and hour is not equal to 12
		end if
		return hour is less than 9
	end if
	
	hour is greater than or equal to 7 and hour is less than 21
end _isWorkTime


on unitTest()
	set test to testLib's new()
	set ut to test's new()
	
	
	(* Parameterized is too slow.
	set dataIwt to "
		false, 6:28:08 AM,  Before 7AM
		false, 6:28:08 AM,  Before 7AM
		true,  9:28:08 AM,  Past 7AM
		true,  8:28:08 PM,  Before 9PM
		false, 9:28:08 PM,  After 9PM
		false, 12:03:08 AM, Bug at midnight
		false, 6:28:08,     Before 7 24H format
		true,  7:28:08,     After 7 24H format
		true,  20:28:08,    Before 9 24H format
		false, 21:28:08,    After 9 24H format
	"
	
	tell ut
		newMethod("_isWorkTime")
		repeat with nextCase in textUtil's splitWithTrim(dataIwt, ASCII character 10)
			set tokens to textUtil's splitWithTrim(nextCase, ",")
			assertEqual(item 1 of tokens is equal to "true", my _isWorkTime(item 2 of tokens), item 3 of tokens)
		end repeat
	end tell
	*)
	
	tell ut
		newMethod("_isWorkTime")
		assertEqual(false, my _isWorkTime("6:28:08 AM"), "Before 7AM")
		assertEqual(true, my _isWorkTime("9:28:08 AM"), "Past 7AM")
		assertEqual(true, my _isWorkTime("8:28:08 PM"), "Before 9PM")
		assertEqual(false, my _isWorkTime("9:28:08 PM"), "After 9PM")
		assertEqual(false, my _isWorkTime("6:28:08"), "Before 7 24H format")
		assertEqual(true, my _isWorkTime("7:28:08"), "After 7 24H format")
		assertEqual(true, my _isWorkTime("20:28:08"), "Before 9 24H format")
		assertEqual(false, my _isWorkTime("21:28:08"), "After 9 24H format")
		assertEqual(false, my _isWorkTime("12:03:08 AM"), "Bug at midnight")
		
		newMethod("next30MinuteSlot")
		assertEqual(date "Monday, October 4, 2021 at 7:00:00 AM", my next30MinuteSlot(date "Monday, October 4, 2021 at 6:28:08 AM"), "Triggers Buffer")
		assertEqual(date "Monday, October 4, 2021 at 6:30:00 AM", my next30MinuteSlot(date "Monday, October 4, 2021 at 6:27:00 AM"), "Happy Case :00")
		assertEqual(date "Monday, October 4, 2021 at 7:00:00 AM", my next30MinuteSlot(date "Monday, October 4, 2021 at 6:30:08 AM"), "Happy Case :30")
		assertEqual(date "Tuesday, October 5, 2021 at 12:00:00 AM", my next30MinuteSlot(date "Monday, October 4, 2021 at 11:30:08 PM"), "Midnight")
		
		newMethod("nextHourSlot")
		assertEqual(date "Monday, October 4, 2021 at 8:00:00 AM", my nextHourSlot(date "Monday, October 4, 2021 at 6:58:08 AM"), "Triggers Buffer")
		assertEqual(date "Monday, October 4, 2021 at 7:00:00 AM", my nextHourSlot(date "Monday, October 4, 2021 at 6:01:08 AM"), "Happy Case")
		assertEqual(date "Tuesday, October 5, 2021 at 12:00:00 AM", my nextHourSlot(date "Monday, October 4, 2021 at 11:01:08 PM"), "Midnight")
		
		newMethod("extractTimeFromDateTimeText")
		assertEqual("1:01 PM", my extractTimeFromDateTimeText("Monday, October 4, 2021 at 1:01:08 PM"), "Single Digit Hour")
		assertEqual("11:01 PM", my extractTimeFromDateTimeText("Monday, October 4, 2021 at 11:01:08 PM"), "Basic")
		
		newMethod("formatYyyyMmDd")
		assertEqual("20211004", my formatYyyyMmDd(date "Monday, October 4, 2021 at 8:00:00 AM", missing value), "No Separator")
		assertEqual("2021/10/04", my formatYyyyMmDd(date "Monday, October 4, 2021 at 8:00:00 AM", "/"), "With Separator")
		
		newMethod("formatYyMmDd")
		assertEqual("211004", my formatYyMmDd(date "Monday, October 4, 2021 at 8:00:00 AM", missing value), "No Separator")
		
		newMethod("formatYyyyDdMm")
		assertEqual("2022/14/06", my formatYyyyDdMm(date "Tuesday, June 14, 2022 at 8:00:00 AM", "/"), "With Separator")
		
		newMethod("formatMmDdYyyy")
		assertEqual("06-14-2022", my formatMmDdYyyy(date "Tuesday, June 14, 2022 at 8:00:00 AM", "-"), "With Separator")
		
		
		done()
		
		-- TODO below:
		return
		
		log todayMinusDays(365 + 91) -- connected date
		log todayMinusDays(91) -- expirydate
		log todayMinusDays(2) -- expirycarrier
		-- log dayMinus(2 * 365 + 91)
		-- log dayMinus()
		log isWeekday()
		log isMorning()
		log isWorkHour()
		
	end tell
end unitTest
