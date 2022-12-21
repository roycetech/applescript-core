global std
global countDaily, countKeys, countTotal

(*
	Compile:
		make compile-lib SOURCE=libs/counter-plist/counter
		
	WARNING: This script is crappy, do not remove the init() on every handler 
	because it triggers a weird error where reference to countTotal is lost 
	despite being a globally declared variable.
*)
-- global countDaily, countDailyList, countKeys, countTotal, countDates

(*
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

use script "Core Text Utilities"
use scripting additions

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

to spotCheck()
	init()
	set thisCaseId to "counter-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	set cases to listUtil's splitByLine("
		Total
		Increment
		Clear
	")
	
	set spotLib to std's import("spot")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sutKey to thisCaseId
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		increment(thisCaseId)
		
	else if caseIndex is 3 then
		clear(thisCaseId)
		
	end if
	
	logger's debugf("Test Key: {}", sutKey)
	logger's infof("totalAll: {}", totalAll(sutKey))
	logger's infof("totalToday: {}", totalToday(sutKey))
	logger's infof("hasRunToday: {}", hasRunToday(sutKey))
	logger's infof("hasNotRunToday: {}", hasNotRunToday(sutKey))
	
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


to totalToday(theKey as text)
	set todayDate to _formatDate(short date string of (current date))
	set keyToday to format {"{}-{}", {theKey, todayDate}}
	
	set theCount to countDaily's getInt(keyToday)
	if theCount is missing value then return 0
	
	theCount
end totalToday

(**)
to increment(theKey as text)
	init()
	set todayDate to _formatDate(short date string of (current date))
	
	-- set todayList to countDailyList's getValue(todayDate)
	-- if todayList is missing value then set todayList to {}
	-- if todayList does not contain theKey then set end of todayList to theKey
	-- countDailyList's setValue(todayDate, todayList)
	
	-- set allDates to countDates's getValue("All Dates")
	-- if allDates is missing value then set allDates to {}
	-- if allDates does not contain todayDate then set end of allDates to todayDate
	-- countDates's setValue("All Dates", allDates)
	
	set keyCount to countTotal's getInt(theKey)
	if keyCount is missing value then set keyCount to 0
	set keyCount to keyCount + 1
	countTotal's setValue(theKey, keyCount)
	
	set keyToday to format {"{}-{}", {theKey, todayDate}}
	set keyTodayCount to countDaily's getInt(keyToday)
	if keyTodayCount is missing value then set keyTodayCount to 0
	set keyTodayCount to keyTodayCount + 1
	countDaily's setValue(keyToday, keyTodayCount)
end increment

(*  *)
to totalAll(theKey as text)
	init()
	set theCount to countTotal's getInt(theKey)
	if theCount is missing value then return 0
	
	theCount
end totalAll

(* 
	Useful if you want lets say to do something every nth run. 
	
	@nth - a positive integer.	
	@return boolean.	
*)
to isNthRun(theKey as text, nth as integer)
	init()
	assertThat of std given condition:nth is greater than 0, messageOnFail:format {"The nth:{} must be a positive integer", nth}
	
	set totalCount to countTotal's getInt(theKey)
	if the totalCount is missing value then return false
	
	totalCount mod nth is 0
end isNthRun


to clear(theKey)
	init()
	set todayDate to _formatDate(short date string of (current date))
	set keyToday to format {"{}-{}", {theKey, todayDate}}
	countTotal's setValue(theKey, 0)
	countDaily's setValue(keyToday, 0)
end clear

(* TODO: *)
to clearRun(theKey)
	-- _setValue(theKey, missing value)
end clearRun

to hasRun(theKey)
	totalAll(theKey) is greater than 0
end hasRun

to hasRunToday(theKey as text)
	totalToday(theKey) is greater than 0
end hasRunToday

to hasNotRunToday(theKey as text)
	hasRunToday(theKey) is false
end hasNotRunToday

(* @scriptName - e.g. "Arrange Windows" *)
to hasScriptRunToday(scriptName as text)
	set keyToday to format {"Running: [{}.applescript]", my _stripExtension(scriptName)}
	
	totalToday(keyToday) is greater than 0
end hasScriptRunToday

(* @scriptName - e.g. "Arrange Windows" *)
to totalScriptRunToday(scriptName as text)
	set keyToday to format {"Running: [{}.applescript]", my _stripExtension(scriptName)}
	
	totalToday(keyToday)
end totalScriptRunToday


-- Private Codes below ======================================================
(* Default format date to yyyyMMdd. Will break by year 3000, i'll be long dead by then and this script buried in archive or deleted. *)
to _formatDate(dateString)
	"20" & last word of dateString & "/" & first word of dateString & "/" & second word of dateString
end _formatDate

to _stripExtension(scriptName)
	if scriptName ends with ".applescript" then set scriptName to text 1 thru ((length of scriptName) - (length of ".applescript")) of scriptName
	scriptName
end _stripExtension


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("counter")
	set plutil to std's import("plutil")'s new()
	
	set countDailyName to "counter-daily"
	if not plutil's plistExists(countDailyName) then
		plutil's createNewPList(countDailyName)
	end if
	set countDaily to plutil's new(countDailyName)
	
	set countKeysName to "counter-all-keys"
	if not plutil's plistExists(countKeysName) then
		plutil's createNewPList(countKeysName)
	end if
	set countKeys to plutil's new(countKeysName)
	
	set countTotalName to "counter-total"
	if not plutil's plistExists(countTotalName) then
		plutil's createNewPList(countTotalName)
	end if
	set countTotal to plutil's new(countTotalName)
end init