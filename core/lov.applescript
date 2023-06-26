(*
	Allows you to manage a list of values.
	
	@Plists:
		lov.plist
		
	@Installation Example:
		$ ./scripts/plist-array-append.sh "spot-lov" "option 1" ~/applescript-core/lov.plist
*)

use listUtil : script "list"

use loggerLib : script "logger"
use plutilLib : script "plutil"

use spotScript : script "spot-test"

property logger : loggerLib's new("")
property plutil : plutilLib's new()
property LOV_PLIST : plutil's new("lov")

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	set thisCaseId to "#extensionLessName#-spotCheck"
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: Basic
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new("spot-lov")
	if caseIndex is 1 then
		set lov to sut's getLov()
		repeat with nextValue in lov
			logger's infof("nextValue: {}", nextValue)
		end repeat
		
		logger's infof("next of XXX: {}", sut's getNextValue("xxx"))
		logger's infof("next of Option 1: {}", sut's getNextValue("Option 1"))
		logger's infof("next of Option 2: {}", sut's getNextValue("Option 2"))
		logger's infof("Is Binary: {}", sut's isBinary())
		
	else if caseIndex is 2 then
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new(lovName)
	script LovInstance
		property _lovName : lovName
		property _lov : LOV_PLIST's getValue(lovName)
		
		on getLov()
			_lov
		end getLov
		
		on getNextValue(currentValue)
			if _lov is missing value or (count of _lov) is 0 then return missing value
			
			set nextIndex to 1
			set currentIndex to listUtil's indexOf(_lov, currentValue)
			try
				return item (currentIndex + 1) of _lov
			end try
			
			item 1 of _lov
		end getNextValue
		
		on isBinary()
			(count of _lov) is 2
		end isBinary
	end script
end new
