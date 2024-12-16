(*
	This library is implemented as copy from plutil.
	This is slightly slower than plutil, and different use case so make sure you
	understand their differences.

	Requirements:
		redis-cli 7.0.5+. Run `redis-cli --version` to check your current version.
		Server must be running, start with: `redis-server`

	@Install:
		make install-redis

	@Usage:
		use redisLib : script "core/redis"

		property redis : redisLib's new(0) -- 0 for no timeout

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh libs/redis/redis

	@Troubleshooting:
		When you do an update,
			1.  make sure to re-run the setup-redis-cli.applescript
		to update the cli location.
			2.  Re-compile this script so that the new CLI will be reloaded from the config.

		Run "brew services restart redis" to fix the issue with "MISCONF Redis
		is configured to save RDB snapshots, but it's currently unable to persist to disk"

	@Known Issues:
		September 2, 2023 9:53 AM - Records are not currently supported.

	@Last Modified: 2024-12-01 19:31:57
 *)

use scripting additions
use script "core/Text Utilities"

use textUtil : script "core/string"
use listUtil : script "core/list"
use loggerFactory : script "core/logger-factory"
use dateTimeLib : script "core/date-time"
use spotScript : script "core/spot-test"

property logger : missing value
property dateTime : missing value

property CR : ASCII character 13
property REDIS_CLI : do shell script "plutil -extract \"Redis CLI\" raw ~/applescript-core/config-system.plist"
property useBasicLogging : false

property ERROR_UNSUPPORTED_TYPE : 1000
property ERROR_WRONG_TYPE : 1001
property ERROR_KEY_IS_MISSING : 1002
property ERROR_VALUE_IS_MISSING : 1003
property ERROR_INVALID_ELEMENT_COUNT : 1004

if {"Script Editor", "Script Debugger"} contains the name of current application then
	set useBasicLogging to true
	spotCheck()
end if

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Read Value
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
		set sut to new(0)
		logger's infof("Handler result: {}", sut's getValue("inspector-app_name_previous"))

	else if caseIndex is 2 then
		set sut to new(2)
		set keyName to "spot-zulu-date"
		sut's setValue(keyName, current date)
		logger's infof("Result: {}", sut's getValueAsDate(keyName))

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*
	@pTimeoutSeconds - 0 for no expiration.
*)
on new(pTimeoutSeconds)
	loggerFactory's inject(me)

	set dateTime to dateTimeLib's new()

	script RedisInstance
		-- 0 for no expiration.
		property timeoutSeconds : pTimeoutSeconds

		(* TODO: Unit Test rpush, lrange, lpop. *)
		on rpush(listKey, newValue)
			if listKey is missing value then return
			set quotedListKey to quoted form of listKey
			set quotedValue to quoted form of newValue

			set pushValueShellCommand to format {"{} RPUSH {} {}", {REDIS_CLI, quotedListKey, quotedValue}}
			try
				do shell script pushValueShellCommand
			on error the errorMessage number the errorNumber
				logger's warn(errorMessage)
			end try
		end rpush


		on lrange(listKey, startIndex, endIndex)
			if listKey is missing value then return
			set quotedListKey to quoted form of listKey

			set lrangeShellCommand to format {"{} LRANGE {} {} {}", {REDIS_CLI, quotedListKey, startIndex, endIndex}}
			try
				do shell script lrangeShellCommand
			on error the errorMessage number the errorNumber
				logger's warn(errorMessage)
			end try
		end lrange


		on lpop(listKey)
			if listKey is missing value then return
			set quotedListKey to quoted form of listKey

			set popValueShellCommand to format {"{} LPOP {}", {REDIS_CLI, quotedListKey}}
			try
				do shell script popValueShellCommand
			on error the errorMessage number the errorNumber
				logger's warn(errorMessage)
			end try
		end lpop


		on setValue(plistKey, newValue)
			if plistKey is missing value then return

			if newValue is missing value then deleteKey(plistKey)

			set quotedPlistKey to quoted form of plistKey
			set dataType to class of newValue

			if {text, boolean, integer, real, date} contains dataType then
				set shellValue to newValue

				if dataType is text then
					set shellValue to quoted form of newValue
				else if dataType is date then
					set shellValue to quoted form of _formatPlistDate(newValue)
				end if

				set timeoutParam to ""
				if timeoutSeconds is greater than 0 then
					set timeoutParam to format {" EX {}", timeoutSeconds}
				end if

				set setValueShellCommand to format {"{} SET {} {} {}", {REDIS_CLI, quotedPlistKey, shellValue, timeoutParam}}
				try
					do shell script setValueShellCommand
				on error the errorMessage number the errorNumber
					logger's warn(errorMessage)
				end try

				return

			else if dataType is list then
				_insertList(quotedPlistKey, newValue)
				return

			else if dataType is record then
				error "Unsupported data type error" number ERROR_UNSUPPORTED_TYPE
				-- _setRecordAsJson(plistKey, newValue)
				-- return

			else if dataType is script and name of newValue is "ASDictionary" then
				setValue(plistKey, newValue's toJsonString())
				return

			end if
		end setValue


		on getBool(plistKey)
			try
				return getValue(plistKey) is equal to "true"
			end try
			false
		end getBool

		on getInt(plistKey)
			try
				return getValue(plistKey) as integer
			end try -- missing key
			missing value
		end getInt

		on getReal(plistKey)
			try
				return getValue(plistKey) as real
			end try -- missing key
			missing value
		end getReal


		on getList(plistKey)
			if plistKey is missing value then return missing value

			set quotedEspacedPlistKey to _escapeAndQuoteKey(plistKey)
			_getList(quotedEspacedPlistKey)
		end getList


		(* Works for string types only *)
		on _getList(quotedEspacedPlistKey)
			set getTsvCommand to format {"{} LRANGE {} 0 -1", {REDIS_CLI, quotedEspacedPlistKey}}
			set csv to do shell script getTsvCommand
			_splitByLine(csv)
		end _getList


		on getValueWithDefault(plistKey, defaultValue)
			set fetchedValue to getValue(plistKey)
			if fetchedValue is missing value then return defaultValue

			fetchedValue
		end getValueWithDefault

		on getValue(plistKey)
			if plistKey is missing value then return missing value

			set quotedPlistKey to quoted form of plistKey
			try
				if plistKey starts with "EMOJI" then -- follow convention, reduce execution of shell commands.
					set dataType to "string"
				else
					set getTypeShellCommand to format {"{} type {}", {REDIS_CLI, quotedPlistKey}}
					set dataType to do shell script getTypeShellCommand
					if dataType is "none" then return missing value
				end if
			on error the errorMessage number the errorNumber
				if errorMessage contains "Could not connect to Redis" then
					logger's info("Connection refused, will attempt to launch redis")
					set redisServerCli to textUtil's replace(REDIS_CLI, "redis-cli", "redis-server --daemonize yes")
					do shell script redisServerCli
				end if
				return missing value
			end try

			if dataType is "list" then
				return _getList(quotedPlistKey)

			else if dataType is "dictionary" then
				-- set getDictShellCommand to format {"/usr/libexec/PlistBuddy -c \"Print :{}\"  {} | awk '/^[[:space:]]/' | awk 'NF {$1=$1;print $0}' | sed 's/[[:space:]]=[[:space:]]/: /g'", {quotedPlistKey, quotedPlistPosixPath}}
				set getDictShellCommand to format {"/usr/libexec/PlistBuddy -c \"Print :{}\"  {} | awk '/^[[:space:]]/' | awk 'NF {$1=$1;print $0}' | sed 's/:/__COLON__/g' | sed 's/[[:space:]]=[[:space:]]/: /g'", {quotedPlistKey, quotedPlistPosixPath}}
				set dictShellResult to do shell script getDictShellCommand
				return mapLib's newFromString(dictShellResult)

			else
				set getValueShellCommand to format {"{} get {}", {REDIS_CLI, quotedPlistKey}}
				set plistValue to do shell script getValueShellCommand
				return _convertType(plistValue, dataType)
			end if

			tell application "System Events" to tell property list file plistFilename
				try
					return value of property list item plistKey
				on error errorText
					-- Goes here when the key don't exist, that's fine.
					return missing value
				end try
			end tell
		end getValue


		on hasValue(plistKey)
			if plistKey is missing value then return false

			set quotedPlistKey to quoted form of plistKey

			set getTypeShellCommand to format {"{} TYPE {}", {REDIS_CLI, quotedPlistKey}}
			set dataType to do shell script getTypeShellCommand
			if dataType is "none" then return false

			if dataType is equal to "list" then
				set countShellCommand to format {"{} LLEN {}", {REDIS_CLI, quotedPlistKey}}
				return (do shell script countShellCommand) as integer is greater than 0
			end if

			true
		end hasValue


		(*
			To replace the appendValue so we have consistent naming.
		*)
		on appendElement(plistKey, newValue)
			appendValue(plistKey, newValue)
		end appendElement


		on appendValue(plistKey, newValue)
			if plistKey is missing value then error "plistkey is missing" number ERROR_KEY_IS_MISSING
			if newValue is missing value then error "newValue is missing" number ERROR_VALUE_IS_MISSING

			set escapedAndQuotedPlistKey to _escapeAndQuoteKey(plistKey)

			set quotedValue to newValue
			if not hasValue(plistKey) then setValue(plistKey, {})
			if newValue is not missing value then set quotedValue to _quoteValue(newValue)
			set appendShellCommand to format {"{} RPUSH {} {}", {REDIS_CLI, escapedAndQuotedPlistKey, quotedValue}}
			do shell script appendShellCommand

			if my timeoutSeconds is not 0 then
				set expireListShellCommand to format {"{} EXPIRE {} {}", {REDIS_CLI, escapedAndQuotedPlistKey, timeoutSeconds}}
				do shell script expireListShellCommand
			end if
		end appendValue


		(* @returns the number of removed elements. *)
		on removeElement(plistKey, targetElement, countToRemove)
			if plistKey is missing value then error "Key is missing" number ERROR_KEY_IS_MISSING
			if targetElement is missing value then error "Value is missing" number ERROR_VALUE_IS_MISSING

			set quotedValue to targetElement
			if targetElement is not missing value then set quotedValue to _quoteValue(targetElement)

			set quotedPlistKey to quoted form of plistKey

			-- set deleteElementCommand to format {"plutil -remove {}.{} {}", {quotedPlistKey, targetIndex, quotedPlistPosixPath}}
			set deleteElementCommand to format {"{} LREM {} {} {}", {REDIS_CLI, quotedPlistKey, countToRemove, quotedValue}}
			(do shell script deleteElementCommand) as integer
		end removeElement


		(* @returns true on success. *)
		on deleteKey(plistKey)
			if plistKey is missing value then error "plistkey is missing" number ERROR_KEY_IS_MISSING

			set quotedPlistKey to quoted form of plistKey
			set removeShellCommand to format {"{} DEL {}", {REDIS_CLI, quotedPlistKey}}
			try
				return (do shell script removeShellCommand) is "1"
			end try

			false
		end deleteKey


		on getValueAsDate(plistKey)
			set plistValue to getValue(plistKey)

			try
				return dateTime's fromZuluDateText(plistValue)
			on error the errorMessage number the errorNumber
				logger's warn(errorMessage)
			end try

			missing value
		end getValueAsDate

		(*
			Will serialize the record into a json string and then set the value as string.
			You must explicitly read properties like this as record by using getRecord().
			@recordValue the record value to persist as json.
		*)
		on _setRecordAsJson(plistKey, recordValue)
			set jsonString to json's toJsonString(recordValue)
			setValue(plistKey, jsonString)
		end _setRecordAsJson

		on _quoteValue(theValue)
			if theValue is missing value then return missing value

			if {real, boolean, integer} contains class of theValue then return theValue

			quoted form of theValue
		end _quoteValue


		on _escapeAndQuoteKey(plistKey)
			if plistKey is missing value then return missing value

			set escapedPlistKey to plistKey
			if plistKey contains "." then set escapedPlistKey to do shell script (format {"echo \"{}\" | sed 's/\\./\\\\./g'", plistKey})

			quoted form of escapedPlistKey
		end _escapeAndQuoteKey


		(* @listToSet must have similarly element type. *)
		on _insertList(quotedPlistKey, listToPersist)
			if (count of the listToPersist) is greater than 0 then
				repeat with nextElement in listToPersist
					if class of nextElement is text then set nextElement to quoted form of nextElement
					set appendCommand to format {"{} RPUSH {} {}", {REDIS_CLI, quotedPlistKey, nextElement}}
					do shell script appendCommand
				end repeat

				if my timeoutSeconds is not 0 then
					set expireListShellCommand to format {"{} EXPIRE {} {}", {REDIS_CLI, quotedPlistKey, timeoutSeconds}}
					do shell script expireListShellCommand
				end if

			end if
		end _insertList

		on _convertType(textValue, plistType)
			if plistType is "date" then return _zuluToLocalDate(textValue)
			if plistType is "integer" then return textValue as integer
			if plistType is "float" then return textValue as real
			if plistType is "bool" then return textValue is "true"

			textValue
		end _convertType

		(* Keep this handler here despite being date-specific because this library is considered essential and we don't want to make the date library an essential library by putting a depnedency from an essential library. *)
		on _formatPlistDate(theDate)
			set dateString to short date string of theDate

			set myMonth to (first word of dateString) as integer
			if myMonth is less than 10 then set myMonth to "0" & myMonth
			set myDom to (second word of dateString) as integer
			set timeString to dateTime's cleanTimeString(time string of theDate)

			set myHour to ((first word of timeString) as integer)
			if timeString contains "PM" and myHour is not equal to 12 then set myHour to myHour + 12
			set tzOffset to do shell script "date +'%z' | cut -c 2,3"
			set myHour to myHour - tzOffset -- Local Timezone adjustment

			if myHour is less than 0 then
				set myHour to (myHour + 24) mod 24
				set myDom to myDom - 1 -- problem on new year.
			end if

			if myDom is less than 10 then set myDom to "0" & myDom
			if myHour is less than 10 then set myHour to "0" & myHour
			set myMin to (second word of timeString) as integer
			if myMin is less than 10 then set myMin to "0" & myMin

			set mySec to (third word of timeString) as integer
			if mySec is less than 10 then set mySec to "0" & mySec

			format {"20{}-{}-{}T{}:{}:{}Z", {last word of dateString, myMonth, myDom, myHour, myMin, mySec}}
		end _formatPlistDate
	end script
end new


-- Private Codes below =======================================================


(* WET: Keep it wet because this library will be considered essential and shouldn't have many transitive dependencies to simplify deployment. *)
on _split(theString, theDelimiter, plistType)
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to theDelimiter
	set theArray to every text item of theString
	set AppleScript's text item delimiters to oldDelimiters

	set typedArray to {}
	repeat with nextElement in theArray
		if plistType is "integer" then
			set typedValue to nextElement as integer
		else if plistType is "float" then
			set typedValue to textValue as real
		else if plistType is "bool" then
			set typedValue to nextElement is "true"
		else if plistType is "string" then
			set typedValue to nextElement as text
		else
			copy nextElement to typedValue
		end if
		set end of typedArray to typedValue
	end repeat

	typedArray
end _split


on _splitByLine(theString as text)
	if theString contains (CR) then
		return _split(theString, CR, "string") -- assuming this is shell command result, we have to split by CR.
	end if

	-- Only printable ASCII characters below 127 works. tab character don't work.
	set SEP to "@" -- #%+= are probably worth considering.

	if theString contains SEP or theString contains "\"" then error "Sorry but you can't have " & SEP & " or double quote in the text :("
	if theString contains "$" and theString contains "'" then error "Sorry, but you can't have a dollar sign and a single quote in your string"

	set theQuote to "\""
	if theString contains "$" then set theQuote to "'"
	set command to "echo " & theQuote & theString & theQuote & " | awk 'NF {$1=$1;print $0}' | paste -s -d" & SEP & " - | sed 's/" & SEP & "[[:space:]]*/" & SEP & "/g' | sed 's/[[:space:]]*" & SEP & "/" & SEP & "/g' | sed 's/^" & SEP & "//' | sed 's/" & SEP & SEP & "//g' | sed 's/" & SEP & "$//'" -- failed when using escaped/non escaped plus instead of asterisk.
	set csv to do shell script command

	_split(csv, SEP, "string")
end _splitByLine
