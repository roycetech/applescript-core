global std, regex

use script "Core Text Utilities"
use scripting additions

property initialized : false
property logger : missing value
property CLI : "/usr/libexec/PlistBuddy"

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "plist-buddy-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Manual: Delete add a key-value pair (existing, non-existing, root not/found)
		Manual: Delete a root key (existing, non-existing)
		Manual: Delete a key-value pair
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new("plist-spot")
	if caseIndex is 1 then
		logger's infof("Handler result: {}", sut's addDictionaryKeyValue("added", "add subkey", "add subvalue"))
		
	else if caseIndex is 2 then
		logger's infof("Handler result: {}", sut's deleteRootKey("snone"))
		
	else if caseIndex is 3 then
		logger's infof("Handler result: {}", sut's deleteDictionaryKeyValue("spot", "second"))
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new(pPlistName)
	set AS_CORE_PATH to "/Users/" & std's getUsername() & "/applescript-core/"
	set localPlistPosixPath to AS_CORE_PATH & pPlistName & ".plist"
	try
		if regex's matches("^(?:[a-zA-Z0-9_-]+/)*[a-zA-Z0-9_-]+$", pPlistName) is false then
			error "Invalid PList Name: " & pPlistName
		end if
	end try -- undefined when used with system library.
	
	set calcPlistFilename to format {"~/applescript-core/{}.plist", {pPlistName}}
	
	script PlistBuddyInstance
		property plistFilename : calcPlistFilename
		property plistName : pPlistName
		property quotedPlistPosixPath : quoted form of localPlistPosixPath
		
		(*
			@returns true if delete is successful, false if any errors encountered like when the element was not found.
		*)
		on addDictionaryKeyValue(rootKey, subKey, keyValue)
			set dataType to _getType(keyValue)
			set command to format {"{} -c \"Add ':{}:{}' {} {}\" {}", {CLI, rootKey, subKey, dataType, quoted form of keyValue, quotedPlistPosixPath}}
			logger's debugf("command: {}", command)
			
			try
				do shell script command
				return true
			on error the errorMessage number the errorNumber
				logger's warn(errorMessage)
			end try
			
			false
		end addDictionaryKeyValue
		
		
		(*
			@returns true if delete is successful, false if any errors encountered like when the element was not found.
		*)
		on deleteRootKey(rootKey)
			set command to format {"{} -c \"Delete :{}\" {}", {CLI, rootKey, quotedPlistPosixPath}}
			logger's debugf("command: {}", command)
			try
				do shell script command
				return true
			end try
			
			false
		end deleteRootKey
		
		
		(*
			@returns true if delete is successful, false if any errors encountered like when the element was not found.
		*)
		on deleteDictionaryKeyValue(rootKey, subKey)
			set command to format {"{} -c \"Delete :{}:{}\" {}", {CLI, rootKey, subKey, quotedPlistPosixPath}}
			logger's debugf("command: {}", command)
			
			try
				do shell script command
				return true
			end try
			
			false
		end deleteDictionaryKeyValue
		
		
		on _getType(dataToSave)
			if class of dataToSave is text then return "string"
			if class of dataToSave is list then return "array"
			if class of dataToSave is record then return "dict"
			if class of dataToSave is boolean then return "bool"
			if class of dataToSave is real then return "real"
			if class of dataToSave is integer then return "integer"
			if class of dataToSave is date then return "date"
			-- no mapping for "data"
			
			missing value
		end _getType
		
	end script
end new


-- Private Codes below =======================================================

(*
	Handler grouped by hundredths.
	Put the case you are debugging at the top, and move to correct place once verified.
*)
on unitTest()
	set actual101 to matched("amazing", "maz")
	set case101 to "Case 101: Found"
	std's assert(true, actual101, case101)
end unitTest


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("plist-buddy")
	set regex to std's import("regex")
end init
