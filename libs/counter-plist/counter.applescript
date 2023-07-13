(*
	Compile:
		make compile-lib SOURCE=libs/counter-plist/counter
		
	WARNING: This script is crappy, do not remove the init() on every handler 
	because it triggers a weird error where reference to countTotal is lost 
	despite being a globally declared variable.
*)

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
		
	TODO: Should we refactor this to use instances? June 22, 2023 3:04 PM
*)

if not plutil's plistExists(countDailyName) then
	plutil's createNewPList(countDailyName)
end if

if not plutil's plistExists(countKeysName) then
	plutil's createNewPList(countKeysName)
end if

if not plutil's plistExists(countTotalName) then
	plutil's createNewPList(countTotalName)
end if

use script "Core Text Utilities"
use scripting additions

use listUtil : script "list"

use loggerLib : script "logger"
use plutilLib : script "plutil"

use spotScript : script "spot-test"

property logger : loggerLib's new("counter")
property plutil : plutilLib's new()

property countDailyName : "counter-daily"
property countKeysName : "counter-all-keys"
property countTotalName : "counter-total"

property countDaily : plutil's new(countDailyName)
property countKeys : plutil's new(countKeysName)
property countTotal : plutil's new(countTotalName)

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	logger's start()
	
	set cases to listUtil's splitByLine("
		Total
		Increment
		Clear
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
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


on totalToday(theKey)
	set todayDate to _formatDate(short date string of (current date))
	set keyToday to format {"{}-{}", {theKey, todayDate}}
	
	set theCount to countDaily's getInt(keyToday)
	if theCount is missing value then return 0
	
	theCount
end totalToday

(**)
on increment(theKey)
	set todayDate to _formatDate(short date string of (current date))
	
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
on totalAll(theKey)
	set theCount to countTotal's getInt(theKey)
	if theCount is missing value then return 0
	
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
	countDaily's setValue(keyToday, 0)
end clear


(* TODO: *)
on clearRun(theKey)
	-- _setValue(theKey, missing value)
end clearRun

on hasRun(theKey)
	totalAll(theKey) is greater than 0
end hasRun

on hasRunToday(theKey as text)
	totalToday(theKey) is greater than 0
end hasRunToday

on hasNotRunToday(theKey as text)
	hasRunToday(theKey) is false
end hasNotRunToday

(* @scriptName - e.g. "Arrange Windows" *)
on hasScriptRunToday(scriptName as text)
	set keyToday to format {"Running: [{}.applescript]", my _stripExtension(scriptName)}
	
	totalToday(keyToday) is greater than 0
end hasScriptRunToday

(* @scriptName - e.g. "Arrange Windows" *)
on totalScriptRunToday(scriptName as text)
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
