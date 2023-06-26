(*
	@Deployment:
		make compile-lib SOURCE=core/plist-buddy
*)

use script "Core Text Utilities"
use scripting additions

use std : script "std"

use textUtil : script "string"
use listUtil : script "list"
use regex : script "regex"
use loggerFactory : script "logger-factory"

use spotScript : script "spot-test"

use testLib : script "test"

property test : testLib's new()

property useBasicLogging : false
property logger : missing value
property CLI : "/usr/libexec/PlistBuddy"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	set useBasicLogging to true
	loggerFactory's inject(me, "plist-buddy")
	
	set thisCaseId to "plist-buddy-spotCheck"
	logger's start()
	
	set cases to listUtil's splitByLine("
		Integration Test

		Manual: Add a key-value pair (existing, non-existing, root not/found)
		Manual: Delete a root key (existing, non-existing)
		Manual: Delete a key-value pair
		Manual: Get Keys
		Manual: Get Value
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new("plist-spot")
	if caseIndex is 1 then
		integrationTest()
		
	else if caseIndex is 2 then
		logger's infof("Handler result: {}", sut's addDictionaryKeyValue("added", "add subkey", "add subvalue"))
		
	else if caseIndex is 3 then
		logger's infof("Handler result: {}", sut's deleteRootKey("snone"))
		
	else if caseIndex is 4 then
		logger's infof("Handler result: {}", sut's deleteDictionaryKeyValue("spot", "second"))
		
	else if caseIndex is 5 then
		set keys to sut's getKeys()
		if the number of items in keys is 0 then
			logger's info("The plist doesn't have any items")
		else
			repeat with nextKey in keys
				logger's infof("Next Key: {}", nextKey)
			end repeat
		end if
		
	else if caseIndex is 5 then
		logger's infof("Handler result: {}", sut's getValue("_README"))
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new(pPlistName)
	loggerFactory's inject(me, "plist-buddy")
	
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
		
		on getValue(keyName)
			set escapedKey to _escapeKey(keyName)
			-- logger's debugf("escapedKey: {}", escapedKey)
			
			set command to format {"{} -c \"Print :'{}'\"  {}", {CLI, escapedKey, quotedPlistPosixPath}}
			-- logger's debugf("command: {}", command)
			
			do shell script command
		end getValue
		
		(*
			WARNING: tilde character is used as separator, this will break if it is used in any of the keys.
		*)
		on getKeys()
			set command to format {"{} -c \"Print\" {} | grep -E '^\\s*[^[:space:]]+\\s*=' | awk '{print $1}' | paste -s -d~ -", {CLI, quotedPlistPosixPath}}
			-- logger's debugf("command: {}", command)
			
			try
				set csv to do shell script command
				return textUtil's split(csv, "~")
			on error the errorMessage number the errorNumber
				logger's warn(errorMessage)
			end try
			
			{}
		end getKeys
		
		
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
		
		
		(*
			This escaping is likely incomplete but it supports what I need for now. Will update when I get more bandwidth in the future.
		*)
		on _escapeKey(keyName)
			set escapedKey to keyName
			textUtil's replace(escapedKey, "\\", "\\\\\\\\")
		end _escapeKey
		
		
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


on integrationTest()
	set sut to new("plist-spot")
	
	set ut to test's new()
	tell ut
		newMethod("getValue")
		assertEqual("A.P. ", sut's getValue("/aP\\b/"), "Regular Expression key")
		assertEqual(" and one third", sut's getValue("/\\.6{3,}7?/"), "Regular Expression key 2")
	end tell
	
end integrationTest
