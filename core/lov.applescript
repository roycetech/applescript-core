global std, LOV_PLIST, listUtil

(*
	Allows you to manage a list of values.
	
	@Plists:
		lov.plist
		
	@Installation Example:
		$ ./scripts/plist-array-append.sh "spot-lov" "option 1" ~/applescript-core/lov.plist
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "#extensionLessName#-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Manual: Basic
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
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


-- Private Codes below =======================================================


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("lov")
	set plutil to std's import("plutil")'s new()
	set LOV_PLIST to plutil's new("lov")
	set listUtil to std's import("list")
end init
