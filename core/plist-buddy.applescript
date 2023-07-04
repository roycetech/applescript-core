(*
	@Build:
		make compile-lib SOURCE=core/plist-buddy
*)

use script "Core Text Utilities"
use scripting additions

use std : script "std"

use textUtil : script "string"
use listUtil : script "list"

use regex : script "regex"

use loggerFactory : script "logger-factory"

use configLib : script "config"

use spotScript : script "spot-test"

use testLib : script "test"

property logger : missing value
property CLI : "/usr/libexec/PlistBuddy"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

-- /usr/libexec/PlistBuddy -c "Print ':Code:\ CFML\ Lint'"  '/Users/rye/Projects/@amaysim-ph/applescript-core/test/fixtures/plist-buddy-test.plist'

-- /usr/libexec/PlistBuddy -c "Print ':mobile-bss\\:Code\\:\\ CFML\\ Lint'"  '/Users/rye/Projects/@amaysim-ph/applescript-core/test/fixtures/plist-buddy-test.plist'

on spotCheck()
	loggerFactory's injectBasic(me, "plist-buddy")
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
	loggerFactory's injectBasic(me, "plist-buddy")
	
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
		property quotedPlistPosixPath : quoted form of localPlistPosixPath
		
		(* Unused here but present so it can be queried when debugging. *)
		property plistName : pPlistName
		
		on getValue(keyNameOrList)
			if class of keyNameOrList is text then
				set keyNameList to {keyNameOrList}
			else
				set keyNameList to keyNameOrList
			end if
			
			set keynameBuilder to "" -- May be a bad idea to use the string-builder library.
			repeat with nextKeyName in keyNameList
				if keynameBuilder is not "" then set keynameBuilder to keynameBuilder & ":"
				set keynameBuilder to keynameBuilder & _escapeKey(nextKeyName)
			end repeat
			
			-- set escapedKey to _escapeKey(keyName)
			-- logger's debugf("keynameBuilder: {}", keynameBuilder)
			
			set command to format {"{} -c \"Print ':{}'\"  {}", {CLI, keynameBuilder, quotedPlistPosixPath}}
			-- logger's debugf("command: {}", command)
			
			try
				return do shell script command
			end try
			
			missing value
		end getValue
		
		(*
			WARNING: tilde character is used as separator, this will break if it is used in any of the keys.
		*)
		on getKeys()
			-- set keysPattern to "^\\s*[^[:space:]]+\\s*="
			set keysPattern to "^.*?="
			
			set command to format {"{} -c \"Print\" {} | grep -E '{}' | awk -F= '{print $1}' | awk '{$1=$1};1' | paste -s -d~ -", {CLI, quotedPlistPosixPath, keysPattern}}
			-- logger's debugf("command: {}", command)
			
			try
				set csv to do shell script command
				if csv is "" then return {}
				
				return textUtil's split(csv, "~")
			on error the errorMessage number the errorNumber
				logger's warn(errorMessage)
			end try
			
			{}
		end getKeys
		
		(*
			@keyName - use the PListBuddy key format.
		*)
		on getDictionaryKeys(keyName)
			-- set keysPattern to "^\\s*[^[:space:]]+\\s*="
			set keysPattern to "^.*?="
			set command to format {"{} -c \"Print :'{}'\" {} | grep -E '{}' | awk -F= '{print $1}' | awk '{$1=$1};1' | paste -s -d~ -", {CLI, keyName, quotedPlistPosixPath, keysPattern}}
			-- logger's debugf("getDictionaryKeys command: {}", command)
			
			try
				set csv to do shell script command
				if csv is "" then return {}
				
				return textUtil's split(csv, "~")
			on error the errorMessage number the errorNumber
				logger's warn(errorMessage)
			end try
			
			{}
		end getDictionaryKeys
		
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
		
		
		on keyExists(keyNameOrList)
			getValue(keyNameOrList) is not missing value
		end keyExists
		
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
			textUtil's replace(result, "\\", "\\\\\\\\") -- 4 slashes per slash.
			textUtil's replace(result, " ", "\\\\ ")
			textUtil's replace(result, ":", "\\\\:")
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
	set configSystem to configLib's new("system")
	set asProjectPath to configSystem's getValue("AppleScript Core Project Path")
	set plistFilename of sut to asProjectPath & "/test/fixtures/plist-buddy-test.plist"
	set quotedPlistPosixPath of sut to quoted form of plistFilename of sut
	
	set test to testLib's new()
	set suite to test's new()
	
	tell suite
		newMethod("getValue")
		assertHasValue(sut's getValue("categories"), "Happy Case")
		assertEqual("A.P. ", sut's getValue("/aP\\b/"), "Regular Expression key")
		assertEqual(" and one third", sut's getValue("/\\.6{3,}7?/"), "Regular Expression key 2")
		assertMissingValue(sut's getValue("categoriesx"), "Not Found")
		assertEqual("DEBUG", sut's getValue({"categories", "log4as.test"}), "Nested Key")
		assertMissingValue(sut's getValue("categories:log4as.unicorn"), "Nested key not found")
		assertEqual("https://github.com/cflint/CFLint/blob/master/RULES.md", sut's getValue({"mobile-bss", "Code: CFML Lint"}), "Key with colon") -- tracing.
		
		newMethod("keyExists")
		assertTrue(sut's keyExists("categories"), "Found")
		assertFalse(sut's keyExists("categoriesx"), "Not found")
		assertTrue(sut's keyExists({"categories", "log4as.test"}), "Nested")
		assertFalse(sut's keyExists({"categories", "log4as.unicorn"}), "Nested")
		
		newMethod("getKeys")
		assertEqual({"/aP\\b/", "categories", "log4as.test", "_README", "/\\.6{3,}7?/", "mobile-bss", "Code: CFML Lint"}, sut's getKeys(), "All Keys")
		
		newMethod("getDictionaryKeys")
		assertEqual({"log4as.test"}, sut's getDictionaryKeys("categories"), "Happy Case")
		assertEqual({}, sut's getDictionaryKeys("uncategorized"), "Not Found")
		
		done()
	end tell
end integrationTest
