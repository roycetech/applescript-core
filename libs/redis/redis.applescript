(*
	This library is implemented as copy from plutil.
	This is slightly slower than plutil, and different use case so make sure you 
	understand their differences.
	
	Requirements:
		redis-cli 7.0.5+. Run `redis-cli --version` to check your current version.
		Server must be running, start with: `redis-server`
		
	Compile:
		make install-redis

	@Usage:
		use redisLib : script "redis"

		property redis : redisLib's new(0) -- 0 for no timeout 

	@Build:
		make compile-lib SOURCE=libs/redis/redis

	@Troubleshooting:
		When you do an update, make sure to re-run the setup-redis-cli.applescript
		to update the cli location.
		Run "brew services restart redis" to fix the issue with "MISCONF Redis 
		is configured to save RDB snapshots, but it's currently unable to persist to disk"

	@Last Modified: 2023-07-13 21:07:08
 *)

use script "Core Text Utilities"
use scripting additions

-- PROPERTIES =================================================================

use listUtil : script "list"
use dt : script "date-time"

use loggerFactory : script "logger-factory"
use spotScript : script "spot-test"
use testLib : script "test"


property logger : missing value

property CR : ASCII character 13
property REDIS_CLI : do shell script "plutil -extract \"Redis CLI\" raw ~/applescript-core/config-system.plist"
property useBasicLogging : false

if {"Script Editor", "Script Debugger"} contains the name of current application then
	set useBasicLogging to true
	spotCheck()
end if

on spotCheck()
	loggerFactory's inject(me, "redis")
	logger's start()
	
	set cases to listUtil's splitByLine("
		Unit Test
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
		unitTest()
		
	else if caseIndex is 2 then
		set sut to new(2)
		set keyName to "spot-zulu-date"
		sut's setValue(keyName, current date)
		logger's infof("Result: {}", sut's getValueAsDate(keyName))
		
	else if caseIndex is 2 then
		
		set spotPList to new(plistName)
		set plistKey to "spot1"
		
		spotPList's setValue(plistKey, 1)
		log spotPList's getValue(plistKey)
		log spotPList's getValue("missing")
		log spotPList's hasValue("missing")
		log spotPList's hasValue(plistKey)
		
	else if caseIndex is 3 then
		try
			new("godly")
			tell me to error "Error expected!"
		end try
		
	else if caseIndex is 4 then
		set sut to new("app-menu-links")
		log sut's getValue("Sublime Text")'s toString()
		
	else if caseIndex is 5 then
		set sut to new("config-bss")
		log sut's getString("DB_NAME")
		
	else if caseIndex is 6 then
		set session to new("session")
		set logLiteValue to session's getBool("LOG_LITE")
		log class of logLiteValue
		log logLiteValue
		
	else if caseIndex is 7 then
		set session to new("app-killer")
		set storedDate to session's getDateText("Last Focused-1Password 6")
		log class of storedDate
		log storedDate
		
	else if caseIndex is 8 then
		set session to new("app-killer")
		set storedDate to session's getDate("Last Focused-1Password 6")
		log class of storedDate
		log storedDate
		
	else if caseIndex is 9 then
		set appKiller to new("app-killer")
		set storedList to appKiller's getList("Monitored App List")
		log class of storedList
		log storedList
		
		log "getting zoom.us list"
		set appMenu to new("app-menu-items")
		set zoomList to appMenu's getList("zoom.us")
		log zoomList
		
	else if caseIndex is 10 then
		set session to new("session")
		set storedList to session's getValue("Case Labels")
		log class of storedList
		log storedList
		
	else if caseIndex is 11 then
		set session to new("session")
		log session's debugOn()
		logger's debug("debug on prints this")
		
	else if caseIndex is 12 then
		set session to new("session")
		log session's appendValue("Pinned Notes", "Safari-$Title-udemy.com-AWS Certified Developer - Associate 2020 | Udemy.md")
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(* 
	@pTimeoutSeconds - 0 for no expiration.
*)
on new(pTimeoutSeconds)
	loggerFactory's inject(me, "redis")
	
	script RedisInstance
		-- 0 for no expiration.
		property timeoutSeconds : pTimeoutSeconds
		
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
				do shell script setValueShellCommand
				return
				
			else if dataType is list then
				_insertList(quotedPlistKey, newValue)
				return
				
				(*
			else if dataType is record then
				_setRecordAsJson(plistKey, newValue)
				return
*)
				
			else if dataType is script and name of newValue is "ASDictionary" then
				setValue(plistKey, newValue's toJsonString())
				return
				
			end if
		end setValue
		
		on getString(plistKey)
			if plistKey is missing value then return missing value
			
			set quotedPlistKey to quoted form of plistKey
			
			set getStringShellCommand to format {"{} GET {}", {REDIS_CLI, quotedPlistKey}}
			-- set getStringShellCommand to _getTypedGetterShellTemplate("string", plistKey, quotedPlistPosixPath)
			
			try
				return (do shell script getStringShellCommand) as text
			end try -- missing key
			missing value
		end getString
		
		on getBool(plistKey)
			try
				return getString(plistKey) is equal to "true"
			end try
			false
		end getBool
		
		on getInt(plistKey)
			try
				return getString(plistKey) as integer
			end try -- missing key
			missing value
		end getInt
		
		on getReal(plistKey)
			try
				return getString(plistKey) as real
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
		
		
		on getRecord(plistKey)
			if plistKey is missing value then return missing value
			
			set getRecordShellCommand to _getTypedGetterShellTemplate("record", plistKey, quotedPlistPosixPath)
			try
				set calcResult to missing value
				set calcResult to (do shell script getRecordShellCommand) as record
			end try -- missing key
			
			logger's warn("calcResult: {}", calcResult)
			if calcResult is missing value and mapLib's hasJsonSupport() then -- let's try json string
				set getStringShellCommand to _getTypedGetterShellTemplate("string", plistKey, quotedPlistPosixPath)
				
				try
					set stringValue to (do shell script getStringShellCommand) as text
					set calcResult to mapLib's newInstanceFromJson(stringValue)
				end try -- missing key
			end if
			
			calcResult
		end getRecord
		
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
		
		
		on appendValue(plistKey, newValue)
			if plistKey is missing value or newValue is missing value then return
			
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
		on removeElement(plistKey, targetElement)
			if plistKey is missing value then return 0
			if targetElement is missing value then return 0
			set quotedValue to targetElement
			if targetElement is not missing value then set quotedValue to _quoteValue(targetElement)
			
			set quotedPlistKey to quoted form of plistKey
			
			-- set deleteElementCommand to format {"plutil -remove {}.{} {}", {quotedPlistKey, targetIndex, quotedPlistPosixPath}}
			set deleteElementCommand to format {"{} LREM {} 1 {}", {REDIS_CLI, quotedPlistKey, quotedValue}}
			(do shell script deleteElementCommand) as integer
		end removeElement
		
		
		(* @returns true on success. *)
		on deleteKey(plistKey)
			if plistKey is missing value then return
			
			set quotedPlistKey to quoted form of plistKey
			set removeShellCommand to format {"{} DEL {}", {REDIS_CLI, quotedPlistKey}}
			try
				return (do shell script removeShellCommand) is 1
			end try
			false
		end deleteKey
		
		
		on getValueAsDate(plistKey)
			set plistValue to getValue(plistKey)
			
			try
				return dt's fromZuluDateText(plistValue)
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
		
		
		(*
			@typeText 
			@plistKey
			@ quotedPlistPosixPath
		*)
		on _getTypedGetterShellTemplate(typeText, plistKey, quotedPlistPosixPath)
			if plistKey is missing value then return missing value
			
			set typeClause to ""
			if typeText is not missing value then set typeClause to "-expect " & typeText
			
			set shellTemplate to "if [[ \"{}\" == *\".\"* ]]; then TMP=$(echo \"{}\" | sed 's/\\./\\\\./g');plutil -extract \"$TMP\" raw " & typeClause & " {}; else plutil -extract {} raw " & typeClause & " {}; fi"
			format {shellTemplate, {plistKey, plistKey, quotedPlistPosixPath, quoted form of plistKey, quotedPlistPosixPath}}
		end _getTypedGetterShellTemplate
		
		
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
			
			set timeString to time string of theDate
			
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

		-- TO Migrate, from session.
		on debugOn()
			getBool("DEBUG_ON")
		end debugOn
	end script
end new


-- Private Codes below =======================================================

(* Intended to cache the value to reduce events triggered. *)
on _getHomeFolderPath()
	if my homeFolderPath is missing value then set my homeFolderPath to (path to home folder)
	my homeFolderPath
end _getHomeFolderPath


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

on _indexOf(aList, targetElement)
	repeat with i from 1 to count of aList
		set nextElement to item i of aList
		if nextElement as text is equal to targetElement as text then return i
	end repeat

	return 0
end _indexOf


on unitTest()
	set test to testLib's new()
	set ut to test's new()
	set UT_REDIS_TIMEOUT to 2
	set sut to new(UT_REDIS_TIMEOUT)
	tell ut
		newMethod("setup")
		sut's deleteKey(missing value)
		sut's deleteKey("spot-array")
		sut's deleteKey("spot-array2")
		sut's deleteKey("spot-array-string")
		sut's deleteKey("spot-string")
		sut's deleteKey("spot-string-dotted")
		sut's deleteKey("spot-integer")
		sut's deleteKey("spot-float")
		sut's deleteKey("spot-date")
		sut's deleteKey("spot-bool")
		sut's deleteKey("spot-true")
		sut's deleteKey("spot-false")
		sut's deleteKey("spot-record")
		sut's deleteKey("spot-map")
		assertMissingValue(sut's getValue("spot-array"), "Clean array key")

		newMethod("setValue")
		sut's setValue(missing value, "haha")
		sut's setValue("spot-array", {1, 2})
		sut's setValue("spot-array-one-time-set", {1, 2, 3})
		sut's setValue("spot-array-string", {"one", "two"})
		sut's setValue("spot-string", "text")
		sut's setValue("spot-string.dotted-key", "string-dotted-value.txt")
		sut's setValue("spot-integer", 1)
		sut's setValue("spot-float", 1.5)
		sut's setValue("spot-record", {one:1, two:2, three:"a&c", |four: colonized|:"apat"})
		sut's setValue("spot-bool", false)
		sut's setValue("spot-false", false)
		sut's setValue("spot-true", true)
		sut's setValue("spot text", "Multi word key")
		sut's setValue("spot missing", missing value)

		newMethod("getValue")
		assertMissingValue(sut's getValue(missing value), "missing value key")
		assertEqual("Multi word key", sut's getValue("spot text"), "Spaced Key")
		assertEqual("Multi word key", sut's getValue("spot text"), "Spaced Key")
		-- assertEqual({"1", "2"}, sut's getValue("spot-array"), "Array of integers") -- Int not supported

		set arrayValue to sut's getValue("spot-array")
		assertEqual(2, count of arrayValue, "Get array count")
		assertEqual("1", first item of arrayValue, "Get array element first")
		assertEqual("2", last item of arrayValue, "Get array element last")
		assertEqual("text", sut's getValue("spot-string"), "Get string value")
		assertEqual("string-dotted-value.txt", sut's getValue("spot-string.dotted-key"), "Get string value of dotted key")
		(*
		set actualRecord to sut's getValue("spot-record")
		assertEqual({"one", "two", "three", "four: colonized"}, actualRecord's getKeys(), "Get record keys")
		assertEqual("{one: 1, two: 2, three: a&c, four: colonized: apat}", actualRecord's toString(), "Get record value")
		*)

		newMethod("getValueWithDefault")
		assertEqual("use me", sut's getValueWithDefault("spot-string-absent", "use me"), "Value is absent")
		assertEqual("text", sut's getValueWithDefault("spot-string", 1), "Value is present")

		newMethod("getList")
		assertMissingValue(sut's getList(missing value), "Missing value")
		assertEqual({"one", "two"}, sut's getList("spot-array-string"), "Get List")

		newMethod("appendValue")
		sut's appendValue("spot-array2", 3)
		assertEqual({"3"}, sut's getList("spot-array2"), "First element")
		sut's appendValue(missing value, 3)
		sut's appendValue("spot-array", missing value)
		sut's appendValue("spot-array", 3)
		assertEqual({"1", "2", "3"}, sut's getList("spot-array"), "Append Int")
		sut's appendValue("spot-array-string", "four")
		assertEqual({"one", "two", "four"}, sut's getList("spot-array-string"), "Append String")
		sut's appendValue("spot-array-string", "five.five")
		assertEqual({"one", "two", "four", "five.five"}, sut's getList("spot-array-string"), "Append dotted string")

		newMethod("removeElement")
		assertEqual(0, sut's removeElement(missing value, "two"), "Missing value list")
		assertEqual(0, sut's removeElement("spot-array-string", missing value), "Missing value element")
		assertEqual(1, sut's removeElement("spot-array-string", "two"), "Successful removal")
		assertEqual({"one", "four", "five.five"}, sut's getList("spot-array-string"), "Get after removing an element")
		assertEqual(1, sut's removeElement("spot-array-string", "one"), "Successful removal")
		sut's removeElement("spot-array-string", "four")
		sut's removeElement("spot-array-string", "five.five")
		assertEqual({}, sut's getList("spot-array-string"), "Get after removing all element")
		assertEqual(0, sut's removeElement("spot-array-string", "Good Putin"), "Remove inexistent element")

		newMethod("getInt")
		assertMissingValue(sut's getInt(missing value), "Missing value")
		assertEqual(1, sut's getInt("spot-integer"), "Get integer value")

		newMethod("getReal")
		assertMissingValue(sut's getReal(missing value), "Missing value")
		assertEqual(1.5, sut's getReal("spot-float"), "Get real value")

		newMethod("getBool")
		assertFalse(sut's getBool("spot-none"), "Missing Value is False")
		assertTrue(sut's getBool("spot-true"), "Verify True")
		assertFalse(sut's getBool("spot-false"), "Verify False")

		newMethod("update") -- huh?!
		sut's setValue("spot-bool", 1)
		assertEqual(1, sut's getInt("spot-bool"), "Update bool to integer")

		newMethod("hasValue")
		assertFalse(sut's hasValue(missing value), "Missing value")
		assertFalse(sut's hasValue("spot-unicorn"), "Value not found")
		assertTrue(sut's hasValue("spot-bool"), "Value found")

		newMethod("hasValue")
		assertFalse(sut's hasValue("spot-unicorn"), "Value not found")
		assertFalse(sut's hasValue(missing value), missing value)

		logger's infof("Delaying by {} to force timeout", UT_REDIS_TIMEOUT)
		delay UT_REDIS_TIMEOUT
		newScenario("getValue with expiry")
		assertMissingValue(sut's getValue("spot-string"), "missing value expected after timeout elapsed")

		newScenario("Expiring List")
		assertMissingValue(sut's getValue("spot-array"), "missing value expected after timeout elapsed")
		assertMissingValue(sut's getValue("spot-array2"), "missing value expected after timeout elapsed")
		assertMissingValue(sut's getValue("spot-array-string"), "missing value expected after timeout elapsed")
		assertMissingValue(sut's getValue("spot-array-one-time-set"), "missing value expected after timeout elapsed")

		done()
	end tell
end unitTest

