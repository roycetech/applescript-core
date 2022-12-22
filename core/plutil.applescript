global std, mapLib
global TZ_OFFSET, AS_CORE_PATH

(*
	This library is implemented prioritizing minimal dependency to othe libraries.
	
	Requirements

    Usage:
    	Create new plist in the defalt location with:
			set plutil to std's import("plutil")'s new()
			plutil's createNewPList("your-new-plist")  -- don't put the extension.
			set yourList to plutil's new("plistname")

	Example 2: 
		set cacheName to format {"dbcache-{}-{}", {env, dbName}}
		if not plutil's  plistExists(cacheName) then
			plutil's createNewPList(cacheName)
		end if
		set cache to plutil's new(cacheName)

		set cachedValue to cache's getValue(sqlQuery)
		if cachedValue is not missing value then
			return cachedValue
		end if
 *)

use script "Core Text Utilities"
use scripting additions


-- PROPERTIES =================================================================
property initialized : false
property logger : missing value
property homeFolderPath : missing value


if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "plutil-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	(* Plist creation already tested. *)
	set cases to listUtil's splitByLine("
		Unit Test				
		Instantiate non-existent plist
		(Broken, unchecked subsequest cases) Debug Note Menu Links 
		Get String		
		Get Boolean
		
		Get Date - Can't read date as string
		Get Date
		Get List
		Get Value - List
		Debug ON
		
		Append Value Debug
	")
	
	set spotLib to std's import("spot")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set plutil to new()
	set plistName to "spot-plist"
	if not plutil's plistExists(plistName) then plutil's createNewPList(plistName)
	set spotPList to plutil's new("spot-plist")
	
	if caseIndex is 1 then
		unitTest()
		
	else if caseIndex is 2 then
		try
			plutil's new("godly")
			tell me to error "Error expected!"
		end try
		logger's info("Passed.")
		
	else if caseIndex is 3 then
		set sut to new("app-menu-links")
		log sut's getValue("Sublime Text")'s toString()
		
	else if caseIndex is 4 then
		set sut to plutil's new("config-system")
		log sut's getString("AppleScript Core Project Path")
		
	else if caseIndex is 5 then
		set sessionPlist to plutil's new("session")
		set logLiteValue to sessionPlist's getBool("LOG_LITE")
		log class of logLiteValue
		log logLiteValue
		
	else if caseIndex is 6 then
		set sessionPlist to plutil's new("app-killer")
		set storedDate to sessionPlist's getDateText("Last Focused-1Password 6")
		log class of storedDate
		log storedDate
		
	else if caseIndex is 7 then
		set sessionPlist to plutil's new("app-killer")
		set storedDate to sessionPlist's getDate("Last Focused-1Password 6")
		log class of storedDate
		log storedDate
		
	else if caseIndex is 8 then
		set appKiller to plutil's new("app-killer")
		set storedList to appKiller's getList("Monitored App List")
		log class of storedList
		log storedList
		
		log "getting zoom.us list"
		set appMenu to plutil's new("app-menu-items")
		set zoomList to appMenu's getList("zoom.us")
		log zoomList
		
	else if caseIndex is 9 then
		set sessionPlist to plutil's new("session")
		set storedList to sessionPlist's getValue("Case Labels")
		log class of storedList
		log storedList
		
	else if caseIndex is 10 then
		set sessionPlist to plutil's new("session")
		log sessionPlist's debugOn()
		logger's debug("debug on prints this")
		
	else if caseIndex is 11 then
		set sessionPlist to plutil's new("session")
		log sessionPlist's appendValue("Pinned Notes", "Safari-$Title-udemy.com-AWS Certified Developer - Associate 2020 | Udemy.md")
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	script PlutilInstance
		on plistExists(plistName)
			set plistBaseFilename to format {"{}.plist", plistName}
			tell application "Finder"
				exists of (file plistBaseFilename of folder "applescript-core" of my _getHomeFolderPath())
			end tell
		end plistExists
		
		
		(*
	Creates a new empty plist in the user hardcoded AppleScript folder.

	@throws error when plist already exists.
	@returns Void
*)
		on createNewPList(plistName)
			if plistExists(plistName) then error format {"Can't create plist, file '{}' already exists", plistName}
			
			(*
	-- Does not work! Says it's readonly!
	set createPlistShellCommand to format {"plutil -create xml1 {}.plist", plistName}
	do shell script createPlistShellCommand
	return
	*)
			set calcPlistFile to format {"~/applescript-core/{}.plist", {plistName}}
			tell application "System Events"
				set theParentDictionary to make new property list item with properties {kind:record}
				
				make new property list file with properties {contents:theParentDictionary, name:calcPlistFile}
			end tell
		end createNewPList
		
		
		(* 
			Note: It is very expensive to check that the plist existence here 
			this is used a lot. Let the client code check it instead and assume
			it exists at this point. 
		*)
		on new(pPlistName)
			set calcPlistFilename to format {"~/applescript-core/{}.plist", {pPlistName}}
			
			set knownPlists to {"config-default", "session", "switches"} -- WET: 2/2
			set isKnown to knownPlists contains pPlistName
			
			-- if not plistExists(pPlistName) then
			-- 	tell me to error "The plist: " & pPlistName & " could not be found."
			-- end if
			
			tell application "Finder"
				-- if not isKnown and not (exists file (pPlistName & ".plist") of folder "applescript-core" of my _getHomeFolderPath()) then
				-- 	tell me to error "The plist: " & pPlistName & " could not be found."
				-- end if
				
				-- set localPlistPosixPath to text 8 thru -1 of (URL of folder "applescript-core" of my _getHomeFolderPath() as text) & pPlistName & ".plist"
			end tell
			
			set localPlistPosixPath to AS_CORE_PATH & pPlistName & ".plist"
			
			script PlutilInstance
				property plistFileName : calcPlistFilename
				property plistName : pPlistName
				property quotedPlistPosixPath : quoted form of localPlistPosixPath
				
				-- HANDLERS ==================================================================
				on setValue(plistKey, newValue)
					
					if plistKey is missing value then return
					
					set quotedPlistKey to quoted form of plistKey
					set dataType to class of newValue
					
					if {text, boolean, integer, real, date} contains dataType then
						set plUtilType to _getPlUtilType(newValue)
						set shellValue to newValue
						
						
						if dataType is text then
							set shellValue to quoted form of newValue
						else if dataType is date then
							set shellValue to quoted form of _formatPlistDate(newValue)
						end if
						
						set setValueShellCommand to format {"if [[ \"{}\" == *\".\"* ]]; then TMP=$(echo \"{}\" | sed 's/\\./\\\\./g');plutil -replace \"$TMP\" -{} {} {}; else plutil -replace {} -{} {} {}; fi", {plistKey, plistKey, plUtilType, shellValue, quotedPlistPosixPath, quotedPlistKey, plUtilType, shellValue, quotedPlistPosixPath}}
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
					
					tell application "System Events"
						if newValue is equal to missing value and my getValue(plistKey) is not missing value then
							tell property list file plistFileName to set value of property list item plistKey to ""
							return
						end if
						
						if my getValue(plistKey) is equal to missing value then
							my _newValue(plistKey, newValue)
						else
							tell property list file plistFileName to set value of property list item plistKey to newValue
						end if
					end tell
				end setValue
				
				on getString(plistKey)
					if plistKey is missing value then return missing value
					
					set getStringShellCommand to _getTypedGetterShellTemplate("string", plistKey, quotedPlistPosixPath)
					
					try
						return (do shell script getStringShellCommand) as text
					end try -- missing key
					missing value
				end getString
				
				on getDateText(plistKey)
					if plistKey is missing value then return missing value
					
					set getDateShellCommand to _getTypedGetterShellTemplate("date", plistKey, quotedPlistPosixPath)
					try
						return do shell script getDateShellCommand
					end try -- missing key
					missing value
				end getDateText
				
				on getDate(plistKey)
					if plistKey is missing value then return missing value
					
					set dateZuluText to getDateText(plistKey)
					_zuluToLocalDate(dateZuluText)
				end getDate
				
				on getBool(plistKey)
					if plistKey is missing value then return missing value
					
					set getBoolShellCommand to _getTypedGetterShellTemplate("bool", plistKey, quotedPlistPosixPath)
					try
						set boolValue to do shell script getBoolShellCommand
						return boolValue is equal to "true"
					end try
					false
				end getBool
				
				on getInt(plistKey)
					if plistKey is missing value then return missing value
					
					set getIntShellCommand to _getTypedGetterShellTemplate("integer", plistKey, quotedPlistPosixPath)
					try
						return (do shell script getIntShellCommand) as integer
					end try -- missing key
					missing value
				end getInt
				
				on getReal(plistKey)
					if plistKey is missing value then return missing value
					
					set getFloatShellCommand to _getTypedGetterShellTemplate("float", plistKey, quotedPlistPosixPath)
					try
						return (do shell script getFloatShellCommand) as real
					end try -- missing key
					missing value
				end getReal
				
				
				on getList(plistKey)
					if plistKey is missing value then return missing value
					-- if (offset of "." in plistKey) is not 0 then error "You cannot have a '.' in your plist key: [" & plistKey & "]"
					
					set quotedEspacedPlistKey to _escapeAndQuoteKey(plistKey)
					_getList(quotedEspacedPlistKey)
				end getList
				
				
				on _getList(quotedEspacedPlistKey)
					set array to {}
					try
						set getArrayTypeShellCommand to format {"plutil -type {}.{} {}", {quotedEspacedPlistKey, 0, quotedPlistPosixPath}}
						set arrayType to do shell script getArrayTypeShellCommand
					on error
						return array
					end try
					
					-- BANDAID.
					set DELIM to "~"
					if plistName starts with "window-regions" then
						set DELIM to ","
					end if
					
					-- WARNING: Can't have ~ in the text because it will be used as the delimiter.
					set getTsvCommand to format {"/usr/libexec/PlistBuddy -c \"Print :{}\" {} | awk '/^[[:space:]]/' | awk 'NF {$1=$1;print $0}' | paste -s -d{} -", {quotedEspacedPlistKey, quotedPlistPosixPath, DELIM}}
					
					set csv to do shell script getTsvCommand
					_split(csv, DELIM, arrayType)
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
							set getTypeShellCommand to format {"if [[ \"{}\" == *\".\"* ]]; then TMP=$(echo \"{}\" | sed 's/\\./\\\\./g');plutil -type \"$TMP\" {}; else plutil -type {} {}; fi", {plistKey, plistKey, quotedPlistPosixPath, quotedPlistKey, quotedPlistPosixPath}}
							set dataType to do shell script getTypeShellCommand
						end if
					on error
						return missing value
					end try
					
					if dataType is "array" then
						return _getList(quotedPlistKey)
						
					else if dataType is "dictionary" then
						-- set getDictShellCommand to format {"/usr/libexec/PlistBuddy -c \"Print :{}\"  {} | awk '/^[[:space:]]/' | awk 'NF {$1=$1;print $0}' | sed 's/[[:space:]]=[[:space:]]/: /g'", {quotedPlistKey, quotedPlistPosixPath}}
						set getDictShellCommand to format {"/usr/libexec/PlistBuddy -c \"Print :{}\"  {} | awk '/^[[:space:]]/' | awk 'NF {$1=$1;print $0}' | sed 's/:/__COLON__/g' | sed 's/[[:space:]]=[[:space:]]/: /g'", {quotedPlistKey, quotedPlistPosixPath}}
						set dictShellResult to do shell script getDictShellCommand
						return mapLib's newInstanceFromString(dictShellResult)
						
					else
						set getValueShellCommand to _getTypedGetterShellTemplate(missing value, plistKey, quotedPlistPosixPath)
						
						set plistValue to do shell script getValueShellCommand
						return _convertType(plistValue, dataType)
					end if
					
					tell application "System Events" to tell property list file plistFileName
						try
							return value of property list item plistKey
						on error errorText
							-- Goes here when the key don't exist, that's fine.
							return missing value
						end try
					end tell
				end getValue
				
				
				on hasValue(mapKey)
					getValue(mapKey) is not missing value
				end hasValue
				
				
				on appendValue(plistKey, newValue)
					if plistKey is missing value or newValue is missing value then return
					
					set escapedAndQuotedPlistKey to _escapeAndQuoteKey(plistKey)
					set plUtilType to _getPlUtilType(newValue)
					-- logger's debugf("plUtilType: {}", plUtilType)
					
					set quotedValue to newValue
					if not hasValue(plistKey) then setValue(plistKey, {})
					if newValue is not missing value then set quotedValue to _quoteValue(newValue)
					set appendShellCommand to format {"plutil -insert {} -{} {} -append {}", {escapedAndQuotedPlistKey, plUtilType, quotedValue, quotedPlistPosixPath}}
					do shell script appendShellCommand
					return
					
					set theList to getValue(plistKey)
					if theList is missing value or theList is "" then set theList to {}
					set end of theList to newValue
					setValue(plistKey, theList)
				end appendValue
				
				(* @returns true if the targetElement is present and removed. *)
				on removeElement(plistKey, targetElement)
					if plistKey is missing value then return false
					
					set quotedPlistKey to quoted form of plistKey
					set appendShellCommand to format {"plutil -remove {} {}", {quotedPlistKey, quotedPlistPosixPath}}
					set theList to getList(plistKey)
					set targetIndex to _indexOf(theList, targetElement) - 1
					if targetIndex is less than 0 then return false
					
					set deleteElementCommand to format {"plutil -remove {}.{} {}", {quotedPlistKey, targetIndex, quotedPlistPosixPath}}
					do shell script deleteElementCommand
					true
				end removeElement
				
				
				(* @returns true on success. *)
				on deleteKey(plistKey)
					if plistKey is missing value then return
					
					set quotedPlistKey to quoted form of plistKey
					set removeShellCommand to format {"plutil -remove {} {}", {quotedPlistKey, my quotedPlistPosixPath}}
					try
						do shell script removeShellCommand
						return true
					end try
					false
				end deleteKey
				
				
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
					set param to "<array>"
					if (count of the listToPersist) is greater than 0 then
						set elementType to _getPlUtilType(first item of listToPersist)
						repeat with nextElement in listToPersist
							set param to param & "<" & elementType & ">" & _escapeSpecialCharacters(nextElement) & "</" & elementType & ">"
						end repeat
					end if
					set param to param & "</array>"
					set setArrayCommand to format {"plutil -replace {} -xml {} {}", {quotedPlistKey, quoted form of param, quotedPlistPosixPath}}
					do shell script setArrayCommand
				end _insertList
				
				on _escapeSpecialCharacters(xmlValue)
					do shell script "echo '" & xmlValue & "' | sed \"s/\\&/\\&amp;/;s/>/\\&gt;/;s/</\\&lt;/;s/'/\\&apos;/\""
				end _escapeSpecialCharacters
				
				
				(* Keep this handler here despite being date-specific because this library is considered essential and we don't want to make the date library an essential library by putting a depnedency from an essential library. *)
				on _formatPlistDate(theDate)
					set dateString to short date string of theDate
					
					set myMonth to (first word of dateString) as integer
					if myMonth is less than 10 then set myMonth to "0" & myMonth
					set myDom to (second word of dateString) as integer
					
					set timeString to time string of theDate
					
					set myHour to ((first word of timeString) as integer)
					if timeString contains "PM" and myHour is not equal to 12 then set myHour to myHour + 12
					set myHour to myHour - TZ_OFFSET -- Local PH Timezone adjustment
					
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
				
				on _zuluToLocalDate(zuluDateText)
					if zuluDateText is missing value then return missing value
					
					set dateTimeTokens to _split(zuluDateText, "T", "string")
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
				
				on _getPlUtilType(dataToSave)
					if class of dataToSave is text then return "string"
					if class of dataToSave is integer then return "integer"
					if class of dataToSave is boolean then return "bool"
					if class of dataToSave is date then return "date"
					if class of dataToSave is list then return "array"
					if class of dataToSave is real then return "float"
					if class of dataToSave is record then return "dict"
					
					missing value
				end _getPlUtilType
				
				to _convertType(textValue, plistType)
					if plistType is "date" then return _zuluToLocalDate(textValue)
					if plistType is "integer" then return textValue as integer
					if plistType is "float" then return textValue as real
					if plistType is "bool" then return textValue is "true"
					
					textValue
				end _convertType
				
				to _newValue(mapKey, newValue)
					tell application "System Events" to tell property list file plistFileName
						make new property list item at end with properties {kind:class of newValue, name:mapKey, value:newValue}
					end tell
				end _newValue
				
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
		
		
		on _indexOf(aList, targetElement)
			repeat with i from 1 to count of aList
				set nextElement to item i of aList
				if nextElement as text is equal to targetElement as text then return i
			end repeat
			
			return 0
		end _indexOf
	end script
	
	std's applyMappedOverride(result)
end new



to unitTest()
	set utLib to std's import("unit-test")
	set ut to utLib's new()
	set sut to new()'s new("spot-plist")
	tell ut
		newMethod("_formatPlistDate +0800") -- Tested against +0800 only.
		assertEqual("2022-04-04T23:30:45Z", sut's _formatPlistDate(date "Tuesday, April 5, 2022 at 7:30:45 AM"), "Before 8AM")
		assertEqual("2022-04-05T00:30:45Z", sut's _formatPlistDate(date "Tuesday, April 5, 2022 at 8:30:45 AM"), "After 8AM")
		assertEqual("2022-04-05T04:30:45Z", sut's _formatPlistDate(date "Tuesday, April 5, 2022 at 12:30:45 PM"), "Afternoon")
		assertEqual("2022-04-11T07:13:45Z", sut's _formatPlistDate(date "Monday, April 11, 2022 at 3:13:45 PM"), "Afternoon")
		
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
		sut's deleteKey("spot-record")
		sut's deleteKey("spot-map")
		sut's deleteKey("spot-special")
		assertEqual(missing value, sut's getValue("spot-array"), "Clean array key")
		
		newMethod("setValue")
		sut's setValue(missing value, "haha")
		sut's setValue("spot-array", {1, 2})
		sut's setValue("spot-array-string", {"one", "two"})
		sut's setValue("spot-string", "text")
		sut's setValue("spot-special", "special&<>")
		sut's setValue("spot-list-special", {"&", "<", ">"}) -- Doesn't look like we need to escape apostrophe and double quotes.
		
		sut's setValue("spot-string.dotted-key", "string-dotted-value.txt")
		sut's setValue("spot-integer", 1)
		sut's setValue("spot-float", 1.5)
		sut's setValue("spot-record", {one:1, two:2, three:"a&c", |four: colonized|:"apat"})
		set testMap to mapLib's new()
		testMap's putValue("one", 1)
		testMap's putValue("two", 2)
		sut's setValue("spot-map", testMap)
		set zuluAdjust to 0 -- manually add/subtract hours if need to test before/after, arvo/midnight. PROBLEMATIC!
		logger's debugf("zulu adjustment hour: {}", zuluAdjust)
		set currentDate to (current date) + zuluAdjust * hours
		sut's setValue("spot-date", currentDate)
		sut's setValue("spot-bool", false)
		
		newMethod("getValue")
		set arrayValue to sut's getValue(missing value)
		set arrayValue to sut's getValue("spot-array")
		assertEqual(2, count of arrayValue, "Get array count")
		assertEqual(1, first item of arrayValue, "Get array element first")
		assertEqual(2, last item of arrayValue, "Get array element last")
		assertEqual("text", sut's getValue("spot-string"), "Get string value")
		assertEqual("string-dotted-value.txt", sut's getValue("spot-string.dotted-key"), "Get string value of dotted key")
		assertEqual(1.5, sut's getValue("spot-float"), "Get float value")
		assertEqual(currentDate, sut's getValue("spot-date"), "Get date value")
		assertEqual(false, sut's getValue("spot-bool"), "Get bool value")
		set actualRecord to sut's getValue("spot-record")
		assertEqual({"one", "two", "three", "four: colonized"}, actualRecord's getKeys(), "Get record keys")
		assertEqual("{one: 1, two: 2, three: a&c, four: colonized: apat}", actualRecord's toString(), "Get record value")
		
		newMethod("getValueWithDefault")
		assertEqual("use me", sut's getValueWithDefault("spot-string-absent", "use me"), "Value is absent")
		assertEqual("text", sut's getValueWithDefault("spot-string", 1), "Value is present")
		
		newMethod("getList")
		assertMissingValue(sut's getList(missing value), "Missing value")
		assertEqual({"one", "two"}, sut's getList("spot-array-string"), "Get List")
		
		newMethod("appendValue")
		sut's appendValue("spot-array2", 3)
		assertEqual({3}, sut's getList("spot-array2"), "First element")
		sut's appendValue(missing value, 3)
		sut's appendValue("spot-array", missing value)
		sut's appendValue("spot-array", 3)
		assertEqual({1, 2, 3}, sut's getList("spot-array"), "Append Int")
		sut's appendValue("spot-array-string", "four")
		assertEqual({"one", "two", "four"}, sut's getList("spot-array-string"), "Append String")
		sut's appendValue("spot-array-string", "five.five")
		assertEqual({"one", "two", "four", "five.five"}, sut's getList("spot-array-string"), "Append dotted string")
		
		newMethod("removeElement")
		assertFalse(sut's removeElement(missing value, "two"), "Missing value list")
		assertFalse(sut's removeElement("spot-array-string", missing value), "Missing value element")
		assertTrue(sut's removeElement("spot-array-string", "two"), "Successful removal")
		assertEqual({"one", "four", "five.five"}, sut's getList("spot-array-string"), "Get after removing an element")
		assertTrue(sut's removeElement("spot-array-string", "one"), "Successful removal")
		sut's removeElement("spot-array-string", "four")
		sut's removeElement("spot-array-string", "five.five")
		assertEqual({}, sut's getList("spot-array-string"), "Get after removing all element")
		assertFalse(sut's removeElement("spot-array-string", "Good Putin"), "Remove inexistent element")
		
		newMethod("getInt")
		assertMissingValue(sut's getInt(missing value), "Missing value")
		assertEqual(1, sut's getInt("spot-integer"), "Get integer value")
		
		newMethod("getReal")
		assertMissingValue(sut's getReal(missing value), "Missing value")
		assertEqual(1.5, sut's getReal("spot-float"), "Get real value")
		
		newMethod("getDateText")
		assertMissingValue(sut's getDateText(missing value), "Missing value")
		assertNotMissingValue(sut's getDateText("spot-date"), "Can get date text")
		
		newMethod("update") -- huh?!
		sut's setValue("spot-bool", 1)
		assertEqual(1, sut's getValue("spot-bool"), "Update bool to integer")
		
		newMethod("hasValue")
		assertEqual(false, sut's hasValue(missing value), "Missing value")
		assertEqual(false, sut's hasValue("spot-unicorn"), "Value not found")
		assertEqual(true, sut's hasValue("spot-bool"), "Value found")
		
		newMethod("hasValue")
		assertFalse(sut's hasValue("spot-unicorn"), "Value not found")
		assertFalse(sut's hasValue(missing value), missing value)
		
		if mapLib's hasJsonSupport() then
			newMethod("getRecord")
			assertEqual("{one: 1, two: 2}", sut's getRecord("spot-map")'s toString(), "Read Record Stored as JSON String")
		end if
		
		(*
		set fetchedMapValue to sut's getValue("spot-map")
		log fetchedMapValue
		log class of fetchedMapValue

		assertEqual("{one: 1, two: 2}", sut's getValue("spot-map")'s toString(), "Get record from Map")
		*)
		
		ut's done()
	end tell
end unitTest


(* Constructor. When you need to load another library, do it here. *)
on init()
	set std to script "std"
	set AS_CORE_PATH to "/Users/" & std's getUsername() & "/applescript-core/"
	
	if initialized of me then return
	set initialized of me to true
	
	set logger to std's import("logger")'s new("plutil")
	set mapLib to std's import("map")
	
	set TZ_OFFSET to (do shell script "date +'%z' | cut -c 2,3") as integer
end init