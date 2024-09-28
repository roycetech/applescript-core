(*
	This script works with plist files using PlistBuddy CLI.
	NOTE: So far this library is good with reading dictionary keys of a plist
	file. Further testing and development is required especially on the write
	capability of this library.

	@Project:
		applescript-core

	@Build:
		make build-lib SOURCE=core/plist-buddy

	TODO: Reduce the spot checks and move to Test plist-buddy.

	@Last Modified: 2024-09-12 18:33:30
*)

use script "core/Text Utilities"
use scripting additions

use std : script "core/std"

use textUtil : script "core/string"
use listUtil : script "core/list"

use regexPatternLib : script "core/regex-pattern"

use loggerFactory : script "core/logger-factory"

use configLib : script "core/config"

use spotScript : script "core/spot-test"

property logger : missing value
property CLI : "/usr/libexec/PlistBuddy"
property TZ_OFFSET : (do shell script "date +'%z' | cut -c 2,3") as integer

property ERROR_PLIST_KEY_MISSING_VALUE : 1000
property ERROR_PLIST_KEY_EMPTY : 1001
property ERROR_PLIST_KEY_INVALID_TYPE : 1002
property ERROR_LIST_COUNT_INVALID : 1003

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	set cases to listUtil's splitByLine("
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
		logger's infof("Handler result: {}", sut's addDictionaryKeyValue("added", "add subkey", "add subvalue"))

	else if caseIndex is 2 then
		logger's infof("Handler result: {}", sut's deleteRootKey("snone"))

	else if caseIndex is 3 then
		logger's infof("Handler result: {}", sut's deleteDictionaryKeyValue("spot", "second"))

	else if caseIndex is 4 then

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

	else if caseIndex is 6 then
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
		set regex to regexPatternLib's new("^(?:[a-zA-Z0-9_-]+/)*[a-zA-Z0-9_-]+$")
		if regex's matches(pPlistName) is false then
			error "Invalid PList Name: " & pPlistName
		end if
	end try -- undefined when used with system library.

	set calcPlistFilename to format {"~/applescript-core/{}.plist", {pPlistName}}

	script PlistBuddyInstance
		property plistFilename : calcPlistFilename
		property quotedPlistPosixPath : quoted form of localPlistPosixPath

		(* Unused here but present so it can be queried when debugging. *)
		property plistName : pPlistName

		(* Unit Tested *)
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

		(* Unit Tested *)
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
			(* Unit Tested *)
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


		(*
			(* Unit Tested *)
		*)
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
			(* Unit Tested *)
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
			(* Unit Tested *)
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


		(*
			TODO: Unit Test.  Set's existing value into the plist. For new
			values, use the #addDictionaryKeyValue.

			@keyNameOrList - key name or list of keys.
			@newValue - scalar value to set.

			@returns true on success.

			(* Partial Unit *)
		*)
		on setValue(keyNameOrList, newValue)
			_validatePlistKey(keyNameOrList)
			if class of keyNameOrList is text then
				set keyNameList to {keyNameOrList}
			else
				set keyNameList to keyNameOrList
			end if

			if newValue is missing value then
				if count of keyNameList is greater than 2 or count of keyNameList is 0 then
					error "Unsupported nesting level" number ERROR_LIST_COUNT_INVALID
				end if
				if count of keyNameList is 1 then return deleteRootKey(keyNameOrList)
				return deleteDictionaryKeyValue(item 1 of keyNameList, item 2 of keyNameList)
			end if

			set builtKeyName to _buildKeyNameFromList(keyNameList)
			set settableValue to _quoteAsNeeded(newValue)
			-- logger's debugf("settableValue: {}", settableValue)
			set command to format {"{} -c \"Set ':{}'  {}\"  {}", {CLI, builtKeyName, settableValue, quotedPlistPosixPath}}

			try
				do shell script command
				return true
			-- on error the errorMessage number the errorNumber
			-- 	log errorMessage
			end try

			false
		end setValue


		(*
			@returns true if delete is successful, false if any errors encountered like:
				- when the root element was not found.
				- when the entry already exists.

			(* Unit Tested *)
		*)
		on addDictionaryKeyValue(rootKey, subKey, keyValue)
			if rootKey is missing value or subKey is missing value then
				error "Root key and sub key is not valued" number ERROR_PLIST_KEY_MISSING_VALUE
			end if

			set escapedRootKey to _escapeKey(rootKey)
			set escapedSubKey to _escapeKey(subKey)
			set settableValue to _quoteAsNeeded(keyValue)
			set dataType to _getType(keyValue)
			set command to format {"{} -c \"Add ':{}:{}' {} {}\" {}", {CLI, escapedRootKey, escapedSubKey, dataType, settableValue, quotedPlistPosixPath}}
			-- logger's debugf("command: {}", command)

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
			-- logger's debugf("command: {}", command)
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
			-- logger's debugf("command: {}", command)

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
			set regex to regexPatternLib's new("^\\d")
			if regex's matches(keyName) then
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

		(*
			Validates the the plist key parameter, no real purpose except to
			validate input. Copied from plutil.applescript
		*)
		on _validatePlistKey(plistKeyOrKeyList)
			if plistKeyOrKeyList is missing value then
				error "Plist Key is missing" number ERROR_PLIST_KEY_MISSING_VALUE
			else if class of plistKeyOrKeyList is text and textUtil's trim(plistKeyOrKeyList) is "" then
				error "Plist Key is empty" number ERROR_PLIST_KEY_EMPTY
			else if {text, list} does not contain the class of plistKeyOrKeyList then
				error "Plist Key type is not supported: " & class of plistKeyOrKeyList number ERROR_PLIST_KEY_INVALID_TYPE
			end if
		end _validatePlistKey
	end script
end new
