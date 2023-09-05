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

use spotScript : script "core/spot-test"

property logger : missing value
property CLI : "/usr/libexec/PlistBuddy"
property TZ_OFFSET : (do shell script "date +'%z' | cut -c 2,3") as integer

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Test

		Manual: Add a key-value pair (existing, non-existing, root not/found)
		Manual: Delete a root key (existing, non-existing)
		Manual: Delete a key-value pair
		Manual: Get Keys

		Manual: Get Value
		Manual: Set Date Value
		Manual: Get Date
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
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
			logger's info("Printing all keys:")
			repeat with nextKey in keys
				logger's infof("Next Key: {}", nextKey)
			end repeat
		end if

		set rootKeys to sut's getRootKeys()
		if the number of items in rootKeys is 0 then
			logger's info("The plist doesn't have any items")
		else
			logger's info("Printing root keys:")
			repeat with nextKey in rootKeys
				logger's infof("Next Key: {}", nextKey)
			end repeat
		end if

	else if caseIndex is 5 then
		logger's infof("Handler result: {}", sut's getValue("_README"))

	else if caseIndex is 7 then
		sut's addDictionaryKeyValue("categories", "spot", current date)

	else if caseIndex is 8 then
		log sut's getDate("User Date")
	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new(pPlistName)
	loggerFactory's injectBasic(me)

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
			if keyNameOrList is missing value then return missing value

			if class of keyNameOrList is text then
				set keyNameList to {keyNameOrList}
			else
				set keyNameList to keyNameOrList
			end if

			set builtKeyName to _buildKeyNameFromList(keyNameList)

			-- set escapedKey to _escapeKey(keyName)
			-- logger's debugf("keynameBuilder: {}", keynameBuilder)

			set command to format {"{} -c \"Print ':{}'\"  {}", {CLI, builtKeyName, quotedPlistPosixPath}}
			-- logger's debugf("command: {}", command)

			try
				return do shell script command
			end try

			missing value
		end getValue

		on hasValue(keyNameOrList)
			getValue(keyNameOrList) is not missing value
		end hasValue


		on getDate(keyName)
			-- log getValue(keyName)
			_zuluToLocalDate(getValue(keyName))
		end getDate

		(*
			WARNING: tilde character is used as separator, this will break if it
			is used in any of the keys.

			@returns list of all keys including nested keys.
		*)
		on getKeys()
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


		(* TODO: Add proper tests. *)
		on getRootKeys()
			set command to format {"{} -c \"Print\" {} \\
				| grep '^    .* =' \\
				| grep -v '        ' \\
				| grep -oE '^[[:space:]]{4}.*' \\
				| awk -F= '{print $1}' \\
				| awk '{$1=$1};1' \\
			 	| paste -s -d~ -", {CLI, quotedPlistPosixPath}}

			try
				set csv to do shell script command
				if csv is "" then return {}

				return textUtil's split(csv, "~")
			on error the errorMessage number the errorNumber
				logger's warn(errorMessage)
			end try

			{}
		end getRootKeys


		(*
			@returns:
				boolean
				integer
				real
				string
				date
				data
				array
				dictionary

			@WARNING: Not suitable for checking scalar data type.
		*)
		on getElementType(keyNameOrList)
			if keyNameOrList is missing value then return missing value

			set valueText to getValue(keyNameOrList)
			if valueText is missing value then return missing value
			if valueText starts with "Dict" then return "dictionary"
			if valueText starts with "Array {" then return "array"

			"string"
		end getElementType

		(*
			@keyName - use the PListBuddy key format.
		*)
		on getDictionaryKeys(keyName)
			-- set keysPattern to "^\\s*[^[:space:]]+\\s*="
			set escapedKeyName to _escapeKey(keyName)
			set keysPattern to "^.*?="
			set command to format {"{} -c \"Print :'{}'\" {} | grep -E '{}' | awk -F= '{print $1}' | awk '{$1=$1};1' | paste -s -d~ -", {CLI, escapedKeyName, quotedPlistPosixPath, keysPattern}}
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


		on setValue(keyNameOrList, newValue)
			if class of keyNameOrList is text then
				set keyNameList to {keyNameOrList}
			else
				set keyNameList to keyNameOrList
			end if

			set keyName to _buildKeyNameFromList(keyNameList)
			set settableValue to _quoteAsNeeded(newValue)
			logger's debugf("settableValue: {}", settableValue)
			set command to format {"{} -c \"Set ':{}'  {}\"  {}", {CLI, keyName, settableValue, quotedPlistPosixPath}}

			try
				return do shell script command
			end try

			missing value
		end setValue


		(*
			@returns true if delete is successful, false if any errors encountered like:
				- when the element was not found.
				- when the entry already exists.
		*)
		on addDictionaryKeyValue(rootKey, subKey, keyValue)
			set settableValue to _quoteAsNeeded(keyValue)
			set dataType to _getType(keyValue)
			set command to format {"{} -c \"Add ':{}:{}' {} {}\" {}", {CLI, rootKey, subKey, dataType, settableValue, quotedPlistPosixPath}}
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


		on _buildKeyNameFromList(keyNameList)
			set keynameBuilder to "" -- May be a bad idea to use the string-builder library.
			repeat with nextKeyName in keyNameList
				if keynameBuilder is not "" then
					set keynameBuilder to keynameBuilder & ":"
				end if

				set keynameBuilder to keynameBuilder & _escapeKey(nextKeyName)
			end repeat
			keynameBuilder
		end _buildKeyNameFromList


		on _quoteAsNeeded(someValue)
			set dataType to _getType(someValue)
			if {"string"} contains dataType then
				return quoted form of someValue

			else if dataType is "date" then
				error "Date is not supported! Couldn't figure out the proper command for PlistBuddy!"
				"2023-07-17T12:34:56Z" -- Needs to be in this format.
				return "'" & _formatPlistDate(someValue) & "'"
			end if

			someValue
		end _quoteAsNeeded

		(*
			This escaping is likely incomplete but it supports what I need for now. Will update when I get more bandwidth in the future.
		*)
		on _escapeKey(keyName)
			if regex's matches("^\\d", keyName) then
				"_" & keyName
			else
				keyName
			end if

			set escapedKey to result
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


		on _zuluToLocalDate(zuluDateText)
			if zuluDateText is missing value then return missing value

			set dateTimeTokens to textUtil's split(zuluDateText, "T", "string")
			set datePart to first item of dateTimeTokens
			set timePart to last item of dateTimeTokens
			set {yearPart, monthPart, dom} to words of datePart

			set dom to last word of datePart
			set nextDayFlag to false
			set timezoneOffset to TZ_OFFSET
			set hourPart to (first word of timePart as integer) + timezoneOffset -- PH local timezone
			set amPm to "AM"

			set hourInt to (hourPart as integer) mod 24
			if hourInt is greater than 11 and hourInt is less than 23 then
				set amPm to "PM"
			end if

			if hourInt is less than TZ_OFFSET and hourInt is not 0 then set dom to dom + 1 -- Problem on new year
			set hourPart to hourPart mod 12
			set parsableFormat to monthPart & "/" & dom & "/" & yearPart & " " & hourPart & text 3 thru -2 of timePart & " " & amPm

			date parsableFormat
		end _zuluToLocalDate
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
		assertEqual("A.P. ", sut's getValue("/aP\\b/"), "Regular Expression key")
		assertEqual(" and one third", sut's getValue("/\\.6{3,}7?/"), "Regular Expression key 2")
		assertMissingValue(sut's getValue("categoriesx"), "Not Found")
		assertEqual("DEBUG", sut's getValue({"categories", "log4as.test"}), "Nested Key")
		assertMissingValue(sut's getValue("categories:log4as.unicorn"), "Nested key not found")
		assertEqual("https://github.com/cflint/CFLint/blob/master/RULES.md", sut's getValue({"mobile-bss", "Code: CFML Lint"}), "Key with colon") -- tracing.

		done()
	end tell
end integrationTest
