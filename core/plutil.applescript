(*
	This library is implemented prioritizing minimal dependency to other libraries.

	TODO: Migrate to accept text or list of keys.
	
	Requirements

	@Usage:
		-- Create new plist in the defalt location with:
		use plutilLib : script "plutil"
		property plutil : plutilLib's new()
			
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
		
	@Plists
		spot-plist - temporary plist used for testing.

	@Known Issues
		Cannot have a colon in the key name for arrays.
		Keys are case-sensitive.
		Script Debugger - Unit test fails when debugger is ON.

	@Build:
		make compile-lib SOURCE=core/plutil
		
	@Tests:
		tests/core/plutilTest.applescript

	@Last Modified: 2023-07-19 21:31:23
 *)
use script "Core Text Utilities"
use scripting additions

use std : script "std"

use listUtil : script "list"
use regex : script "regex"
use loggerFactory : script "logger-factory"

use overriderLib : script "overrider"

use spotScript : script "spot-test"

use test : script "test"

-- PROPERTIES =================================================================
property logger : missing value

property homeFolderPath : missing value
property linesDelimiter : "~"
property isSpot : false

property TZ_OFFSET : (do shell script "date +'%z' | cut -c 2,3") as integer

(*
	if {"Script Editor", "Script Debugger"} contains the name of current application then
		spotCheck()
	end if
*)

(* Used by ASUnit to access this script. *)
on run
	tell application "System Events"
		if name of (path to me) is "plutil.applescript" then
			my spotCheck()
			return
		end if
	end tell
	
	me
end run

on spotCheck()
	set logger to loggerFactory's newBasic("plutil")
	logger's start()
	
	(* Plist creation already tested. *)
	set cases to listUtil's splitByLine("
		Unit Test				
		Instantiate non-existent plist
		(Broken, unchecked subsequest cases) Debug Note Menu Links 
		Get String		
		Get Boolean
		
		Get Date - Cannot read date as string
		Get Date
		Get List
		Get Value - List
		Debug ON
		
		Append Value Debug
		Manual: Delete Plist (Verify spot-plist is deleted)
		Manual: Plist Exists (Basic, SubPath, Non-existing)
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
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
		set session to plutil's new("session")
		set logLiteValue to session's getBool("LOG_LITE")
		log class of logLiteValue
		log logLiteValue
		
	else if caseIndex is 6 then
		set session to plutil's new("app-killer")
		set storedDate to session's getDateText("Last Focused-1Password 6")
		log class of storedDate
		log storedDate
		
	else if caseIndex is 7 then
		set session to plutil's new("app-killer")
		set storedDate to session's getDate("Last Focused-1Password 6")
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
		set session to plutil's new("session")
		set storedList to session's getValue("Case Labels")
		log class of storedList
		log storedList
		
	else if caseIndex is 10 then
		set session to plutil's new("session")
		log session's debugOn()
		logger's debug("debug on prints this")
		
	else if caseIndex is 11 then
		set session to plutil's new("session")
		log session's appendValue("Pinned Notes", "Safari-$Title-udemy.com-AWS Certified Developer - Associate 2020 | Udemy.md")
		
	else if caseIndex is 12 then
		spotPList's deletePlist()
		delay 5
		plutil's createNewPList("spot-plist")
		
	else if caseIndex is 13 then
		set testPlists to listUtil's splitByLine("
			app-windows/region-windows_big-bottom
			app-notes/shared/URL-Pattern
			app-windows/region-windows_big-bottomx
			session
			sessionx
		")
		
		repeat with nextPlist in testPlists
			logger's infof("{} Exists: {}", {nextPlist, plutil's plistExists(nextPlist)})
		end repeat
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's injectBasic(me)
	script PlutilInstance
		(* 
			@plistKey - plistName or subpath with name relative to the home/applescript-core folder. 
		*)
		on plistExists(plistKey)
			if regex's matches("^(?:[a-zA-Z0-9_.-]+/)*[a-zA-Z0-9_.-]+$", plistKey) is false then
				error "Invalid PList Name: " & plistKey
			end if
			
			if (offset of "/" in plistKey) is greater than 0 then
				set plistTokens to _split(plistKey, "/", "string")
				set plistBaseFilename to format {"{}.plist", last item of plistTokens}
				set plistKeyLength to count of plistKey -- using "every characters" fails.
				set plistSubPath to text 1 thru (plistKeyLength - (the number of characters in the last item of plistTokens) - 1) of plistKey
				tell application "Finder"
					set coreFolder to folder "applescript-core" of my _getHomeFolderPath()
					set plistSubfolder to my _posixSubPathToFolder(plistSubPath, coreFolder)
					return exists of (file plistBaseFilename of plistSubfolder)
				end tell
			end if
			
			set plistBaseFilename to format {"{}.plist", plistKey}
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
			if regex's matches("^(?:[a-zA-Z0-9_-]+/)*[a-zA-Z0-9_-]+$", pPlistName) is false then
				error "Invalid PList Name: " & pPlistName number 1
			end if
			
			set calcPlistFilename to format {"~/applescript-core/{}.plist", {pPlistName}}
			
			set knownPlists to {"config-default", "session", "switches"} -- WET: 2/2
			set isKnown to knownPlists contains pPlistName
			
			set AS_CORE_PATH to "/Users/" & std's getUsername() & "/applescript-core/"
			set localPlistPosixPath to AS_CORE_PATH & pPlistName & ".plist"
			
			script PlutilPlistInstance
				property plistFilename : calcPlistFilename
				property plistName : pPlistName
				property quotedPlistPosixPath : quoted form of localPlistPosixPath
				
				-- HANDLERS ==================================================================
				
				on deletePlist()
					do shell script "rm " & plistFilename
				end deletePlist

				(*
					@returns TODO. Void, the value set, or if successful?
				*)
				on setValue(plistKeyOrKeyList, newValue)
					if plistKeyOrKeyList is missing value then return missing value
					
					set isTextParam to class of plistKeyOrKeyList is text
					if isTextParam then
						if regex's matches("^\\d", plistKeyOrKeyList) then
							set plistKeyOrKeyList to "_" & plistKeyOrKeyList
						end if
						set quotedPlistKey to quoted form of plistKeyOrKeyList
					else
						set quotedPlistKey to quoted form of _buildKeyNameFromList(plistKeyOrKeyList)
					end if
					
					-- display dialog quotedPlistKey
					set dataType to class of newValue
					
					if {text, boolean, integer, real, date} contains dataType then
						set plUtilType to _getPlUtilType(newValue)
						set shellValue to newValue
						
						
						if dataType is text then
							set shellValue to quoted form of newValue
						else if dataType is date then
							set shellValue to quoted form of _formatPlistDate(newValue)
						end if
						
						if isTextParam then
							set setValueShellCommand to format {"if [[ \"{}\" == *\".\"* ]]; then TMP=$(echo \"{}\" | sed 's/\\./\\\\./g');plutil -replace \"$TMP\" -{} {} {}; else plutil -replace {} -{} {} {}; fi", {plistKeyOrKeyList, plistKeyOrKeyList, plUtilType, shellValue, quotedPlistPosixPath, quotedPlistKey, plUtilType, shellValue, quotedPlistPosixPath}}
						else
							set setValueShellCommand to format {"plutil -replace {} -{} {} {}", {quotedPlistKey, plUtilType, shellValue, quotedPlistPosixPath}}
							
						end if
						
						-- logger's debugf("setValueShellCommand: {}", setValueShellCommand)
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
						setValue(plistKeyOrKeyList, newValue's toJsonString())
						return
						
					end if
					
					tell application "System Events"
						if newValue is equal to missing value and my getValue(plistKeyOrKeyList) is not missing value then
							tell property list file plistFilename to set value of property list item plistKeyOrKeyList to ""
							return
						end if
						
						if my getValue(plistKeyOrKeyList) is equal to missing value then
							my _newValue(plistKeyOrKeyList, newValue)
						else
							tell property list file plistFilename to set value of property list item plistKey to newValue
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
					if regex's matches("^\\d", plistKey) then set plistKey to "_" & plistKey
					
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
				
				
				(* 
					Always returns a list instance. If the the key does not 
					exist, it returns an empty list instead of a missing value. 
				*)
				on getForcedList(plistKey)
					set fetchedList to getList(plistKey)
					if fetchedList is not missing value then return fetchedList
					
					{}
				end getForcedList
				
				
				on _getList(quotedEspacedPlistKey)
					set array to {}
					try
						set getArrayTypeShellCommand to format {"plutil -type {}.{} {}", {quotedEspacedPlistKey, 0, quotedPlistPosixPath}}
						set arrayType to do shell script getArrayTypeShellCommand
					on error
						try
							set shellCommand to "plutil -extract " & quotedEspacedPlistKey & " raw " & quotedPlistPosixPath
							do shell script shellCommand
							return {}
						end try
						
						return missing value
					end try
					
					-- Band Aid
					if (offset of "$" in quotedEspacedPlistKey) is greater than 0 then
						if quotedEspacedPlistKey contains "$" then set quotedEspacedPlistKey to regex's stringByReplacingMatchesInString("\\$", quotedEspacedPlistKey, "\\\\$")
					end if
					set getTsvCommand to format {"/usr/libexec/PlistBuddy -c \"Print :{}\" {} | awk '/^[[:space:]]/' | awk 'NF {$1=$1;print $0}' | paste -s -d{} -", {quotedEspacedPlistKey, quotedPlistPosixPath, my linesDelimiter}}
					
					set csv to do shell script getTsvCommand
					_split(csv, my linesDelimiter, arrayType)
				end _getList
				
				
				on getRecord(plistKey)
					if plistKey is missing value then return missing value
					
					set getRecordShellCommand to _getTypedGetterShellTemplate("record", plistKey, quotedPlistPosixPath)
					try
						return (do shell script getRecordShellCommand) as record
					end try
					
					missing value
				end getRecord
				
				on getValueWithDefault(plistKey, defaultValue)
					set fetchedValue to getValue(plistKey)
					if fetchedValue is missing value then return defaultValue
					
					fetchedValue
				end getValueWithDefault
				
				
				on getValue(plistKeyOrKeyList)
					if plistKeyOrKeyList is missing value then return missing value
					
					set isTextParam to class of plistKeyOrKeyList is text
					set quotedPlistKey to _quoteKey(plistKeyOrKeyList)
					try
						if isTextParam then
							set getTypeShellCommand to format {"if [[ \"{}\" == *\".\"* ]]; then TMP=$(echo \"{}\" | sed 's/\\./\\\\./g');plutil -type \"$TMP\" {}; else plutil -type {} {}; fi", {plistKeyOrKeyList, plistKeyOrKeyList, quotedPlistPosixPath, quotedPlistKey, quotedPlistPosixPath}}
						else
							set getTypeShellCommand to format {"plutil -type {} {}", {quotedPlistKey, quotedPlistPosixPath}}
							
						end if
						
						set dataType to do shell script getTypeShellCommand
					on error the errorMessage number the errorNumber
						return missing value
					end try
					
					if dataType is "array" then
						return _getList(quotedPlistKey)
						
					else if dataType is "dictionary" then
						(* Use the traditional way via property list. *)
						tell application "System Events" to tell property list file plistFilename
							try
								return value of property list item plistKeyOrKeyList
							on error errorText
								-- Goes here when the key don't exist, that's fine.
								return missing value
							end try
						end tell
						-- 	set getDictShellCommand to format {"/usr/libexec/PlistBuddy -c \"Print :{}\"  {} | awk '/^[[:space:]]/' | awk 'NF {$1=$1;print $0}' | sed 's/:/__COLON__/g' | sed 's/[[:space:]]=[[:space:]]/: /g'", {quotedPlistKey, quotedPlistPosixPath}}
						-- 	set dictShellResult to do shell script getDictShellCommand
						-- 	return mapLib's newFromString(dictShellResult)
						
					else
						set getValueShellCommand to _getTypedGetterShellTemplate(missing value, plistKeyOrKeyList, quotedPlistPosixPath)
						
						set plistValue to do shell script getValueShellCommand
						return _convertType(plistValue, dataType)
					end if
					
					tell application "System Events" to tell property list file plistFilename
						try
							return value of property list item plistKeyOrKeyList
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
				on deleteKey(plistKeyOrKeyList)
					if plistKeyOrKeyList is missing value then return false
					
					set isTextParam to class of plistKeyOrKeyList is text
					set quotedPlistKey to _quoteKey(plistKeyOrKeyList)

					if isTextParam then
						set removeShellCommand to format {"if [[ \"{}\" == *\".\"* ]]; then TMP=$(echo \"{}\" | sed 's/\\./\\\\./g');plutil -remove \"$TMP\" {}; else plutil -remove {} {}; fi", {plistKeyOrKeyList, plistKeyOrKeyList, my quotedPlistPosixPath, quotedPlistKey, my quotedPlistPosixPath}}
					else
						set removeShellCommand to format {"plutil -remove {} {}", {quotedPlistKey, my quotedPlistPosixPath}}
					end if

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
				
				
				on _quoteKey(plistKeyOrKeyList)
					if class of plistKeyOrKeyList is text then
						if regex's matches("^\\d", plistKeyOrKeyList) then
							set plistKeyOrKeyList to "_" & plistKeyOrKeyList
						end if
						return quoted form of plistKeyOrKeyList
					end if

					quoted form of _buildKeyNameFromList(plistKeyOrKeyList)
				end _quoteKey
				
				
				(*
					@typeText
					@plistKey
					@quotedPlistPosixPath
				*)
				on _getTypedGetterShellTemplate(typeText, plistKeyOrKeyList, quotedPlistPosixPath)
					if plistKeyOrKeyList is missing value then return missing value


					set typeClause to ""
					if typeText is not missing value then set typeClause to "-expect " & typeText

					if class of plistKeyOrKeyList is text then
						set shellTemplate to "if [[ \"{}\" == *\".\"* ]]; then TMP=$(echo \"{}\" | sed 's/\\./\\\\./g');plutil -extract \"$TMP\" raw " & typeClause & " {}; else plutil -extract {} raw " & typeClause & " {}; fi"
						format {shellTemplate, {plistKeyOrKeyList, plistKeyOrKeyList, quotedPlistPosixPath, quoted form of plistKeyOrKeyList, quotedPlistPosixPath}}
					else
						set keyName to _buildKeyNameFromList(plistKeyOrKeyList)
						set shellTemplate to "plutil -extract {} raw " & typeClause & " {}"
						format {shellTemplate, {quoted form of keyName, quotedPlistPosixPath}}
					end if
				end _getTypedGetterShellTemplate


				on _buildKeyNameFromList(keyNameList)
					set keynameBuilder to "" -- May be a bad idea to use the string-builder library.
					repeat with nextKeyName in keyNameList
						if keynameBuilder is not "" then set keynameBuilder to keynameBuilder & "."
						if regex's matches("^\\d", nextKeyName) then set nextKeyName to "_" & nextKeyName

						set keynameBuilder to keynameBuilder & nextKeyName
					end repeat
					keynameBuilder
				end _buildKeyNameFromList


				on _escapeAndQuoteKey(plistKey)
					if plistKey is missing value then return missing value

					if regex's matches("^\\d", plistKey) then set plistKey to "_" & plistKey
					set escapedPlistKey to plistKey
					if plistKey contains "." then set escapedPlistKey to do shell script (format {"echo \"{}\" | sed 's/\\./\\\\./g'", plistKey})

					quoted form of escapedPlistKey
				end _escapeAndQuoteKey

				(*
					@listToSet must have similarly element type.

					@Known Issues - wouldn't work if there's $ and other xml special characters combined.
				*)
				on _insertList(quotedPlistKey, listToPersist)
					set param to "<array>"
					if (count of the listToPersist) is greater than 0 then
						set elementType to _getPlUtilType(first item of listToPersist)
						repeat with nextElement in listToPersist
							set nextElementValue to nextElement
							if (offset of "$" in nextElement) is 0 then
								set nextElementValue to _escapeSpecialCharacters(nextElement)
							end if

							set param to param & "<" & elementType & ">" & nextElementValue & "</" & elementType & ">"
						end repeat
					end if
					set param to param & "</array>"
					set setArrayCommand to format {"plutil -replace {} -xml {} {}", {quotedPlistKey, quoted form of param, quotedPlistPosixPath}}

					do shell script setArrayCommand
				end _insertList

				on _escapeSpecialCharacters(xmlValue)
					do shell script "echo \"" & xmlValue & "\" | sed \"s/\\&/\\&amp;/;s/>/\\&gt;/;s/</\\&lt;/;s/'/\\&apos;/\""
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

				on _convertType(textValue, plistType)
					if plistType is "date" then return _zuluToLocalDate(textValue)
					if plistType is "integer" then return textValue as integer
					if plistType is "float" then return textValue as real
					if plistType is "bool" then return textValue is "true"

					textValue
				end _convertType

				on _newValue(mapKey, newValue)
					tell application "System Events" to tell property list file plistFilename
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

		on _posixSubPathToFolder(subpath, sourceFolder)
			set calcEndFolder to sourceFolder
			set pathTokens to _split(subpath, "/", "string")
			tell application "Finder"
				repeat with nextToken in pathTokens
					try
						set calcEndFolder to folder nextToken of calcEndFolder
					on error -- when folder is aliased.
						set calcEndFolder to file nextToken of calcEndFolder
					end try
				end repeat
			end tell

			calcEndFolder
		end _posixSubPathToFolder


		(* Intended to cache the value to reduce events triggered. *)
		on _getHomeFolderPath()
			if my homeFolderPath is missing value then set my homeFolderPath to (path to home folder)
			my homeFolderPath
		end _getHomeFolderPath


		(*
			WET: Keep it wet because this library will be considered essential and shouldn't have many transitive dependencies to simplify deployment.
			@elementType - can be integer, float, bool, or string
		*)
		on _split(theString, theDelimiter, elementType)
			set oldDelimiters to AppleScript's text item delimiters
			set AppleScript's text item delimiters to theDelimiter
			set theArray to every text item of theString
			set AppleScript's text item delimiters to oldDelimiters

			set typedArray to {}
			repeat with nextElement in theArray
				if elementType is "integer" then
					set typedValue to nextElement as integer
				else if elementType is "float" then
					set typedValue to textValue as real
				else if elementType is "bool" then
					set typedValue to nextElement is "true"
				else if elementType is "string" then
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
	if isSpot then return PlutilInstance

	set overrider to overriderLib's new()
	overrider's applyMappedOverride(PlutilInstance)
end new



on unitTest()
	set mapLib to script "map"

	set ut to test's new()
	set plutil to new()
	set sut to plutil's new("spot-plist")

	tell ut
		newMethod("setup")
		sut's deleteKey("spot-string-dotted")
		sut's deleteKey("spot-date")
		sut's deleteKey("spot-record")
		sut's deleteKey("spot-map")
		sut's deleteKey("spot-special")

		set actual to sut's getValue("spot-array")
		assertEqual(missing value, sut's getValue("spot-array"), "Clean array key")
		assertMissingValue(actual, "Clean array key")

		newMethod("setValue")
		-- sut's setValue("101 Dalmatian", "Key Starts with Number Breaks")
		sut's setValue(missing value, "haha")
		sut's setValue("spot-array", {1, 2})
		sut's setValue("spot-array-string", {"one", "two"})
		sut's setValue("spot-array-empty", {})
		sut's setValue("spot array empty", {})
		sut's setValue("spot-string", "text")
		sut's setValue("spot-special", "special&<>")
		sut's setValue("spot-list-special", {"&", "<", ">"}) -- Doesn't look like we need to escape apostrophe and double quotes.
		sut's setValue("spot-$dollar", "$5")
		sut's setValue("spot-$dollar-list", {"$yes-5"})

		sut's setValue("spot-string.dotted-key", "string-dotted-value.txt")
		sut's setValue("spot-integer", 1)
		sut's setValue("spot-float", 1.5)
		sut's setValue("spot-record", {one:1, two:2, three:"a&c", |four: colonized|:"apat"})
		set testMap to mapLib's new()
		testMap's putValue("one", 1)
		testMap's putValue("two", 2)
		sut's setValue("spot-map", testMap)
		set zuluAdjust to 0 -- manually add/subtract hours if need to test before/after, arvo/midnight. PROBLEMATIC!
		-- logger's debugf("zulu adjustment hour: {}", zuluAdjust)
		set currentDate to (current date) + zuluAdjust * hours
		sut's setValue("spot-date", currentDate)
		sut's setValue({"spot-date-dict", "sub-key"}, currentDate)
		sut's setValue("spot-bool", false)

		newMethod("getValueWithDefault")
		assertEqual("use me", sut's getValueWithDefault("spot-string-absent", "use me"), "Value is absent")
		assertEqual("text", sut's getValueWithDefault("spot-string", 1), "Value is present")

		newMethod("getList")
		assertMissingValue(sut's getList(missing value), "Missing value")
		assertEqual({"one", "two"}, sut's getList("spot-array-string"), "Get List")
		assertMissingValue(sut's getList("unicorn-list"), "Missing key returns missing value")
		assertEqual({}, sut's getList("spot-array-empty"), "Empty List")
		assertEqual({}, sut's getList("spot array empty"), "Empty List, Spaced-Key")

		newMethod("getForcedList")
		assertEqual({"one", "two"}, sut's getForcedList("spot-array-string"), "List exists")
		assertEqual({}, sut's getForcedList("unicorn-list"), "Missing List")

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
		log sut's getDateText({"spot-date-dict", "sub-key"})
		log sut's getDate({"spot-date-dict", "sub-key"})

		newMethod("update") -- huh?!
		sut's setValue("spot-bool", 1)
		assertEqual(1, sut's getValue("spot-bool"), "Update bool to integer")

		newMethod("hasValue")
		assertEqual(false, sut's hasValue(missing value), "Missing value")
		assertEqual(false, sut's hasValue("spot-unicorn"), "Value not found")
		assertEqual(true, sut's hasValue("spot-bool"), "Value found")

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

		done()
	end tell
end unitTest
