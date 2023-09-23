(*
	 This library is implemented prioritizing minimal dependency to other libraries.

	Requirements

	@Usage:
		-- Create new plist in the defalt location with:
		use plutilLib : script "core/plutil"
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

	@Project:
		applescript-core

	@Build:
		make compile-lib SOURCE=core/plutil

	@Tests:
		tests/core/Test plutil.applescript

	@Last Modified: 2023-09-20 19:04:31
	@Change Logs:
		August 3, 2023 11:27 AM - Refactored the escaping inside the shell command.
 *)
use script "core/Text Utilities"
use scripting additions

use std : script "core/std"

use textUtil : script "core/string"
use listUtil : script "core/list"
use loggerFactory : script "core/logger-factory"

use decoratorLib : script "core/decorator"

use spotScript : script "core/spot-test"

-- PROPERTIES =================================================================
property logger : missing value

property homeFolderPath : missing value
property linesDelimiter : "~"
property isSpot : false
property regex : missing value

property TZ_OFFSET : (do shell script "date +'%z' | cut -c 2,3") as integer

property ERROR_PLIST_PATH_INVALID : 1000
property ERROR_PLIST_KEY_MISSING_VALUE : 1001
property ERROR_PLIST_KEY_EMPTY : 1002
property ERROR_PLIST_KEY_INVALID_TYPE : 1003

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
	set regex to script "core/regex"

	script PlutilInstance
		(*
			@plistKey - plistName or subpath with name relative to the home/applescript-core folder.
		*)
		on plistExists(plistKey)
			-- Below fails intermittently with NSString issue.
			-- if regex's matches("^(?:[a-zA-Z0-9_.-]+/)*[a-zA-Z0-9_.-]+$", plistKey) is false then
			-- 	error "Invalid PList Name: " & plistKey
			-- end if

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
			-- Below fails intermittently with NSString issue.
			-- if regex's matches("^(?:[a-zA-Z0-9_-]+/)*[a-zA-Z0-9_-]+$", pPlistName) is false then
			-- 	error "Invalid PList Name: " & pPlistName number ERROR_PLIST_PATH_INVALID
			-- end if

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
					set isTextParam to class of plistKeyOrKeyList is text
					set quotedPlistKey to _quotePlistKey(plistKeyOrKeyList)
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
							set setValueShellCommand to _shellEscape(plistKeyOrKeyList) &  format {"plutil -replace \"$TMP\" -{} {} {}; \\
								else \\
									plutil -replace {} -{} {} {}; \\
								fi", {plUtilType, shellValue, quotedPlistPosixPath, quotedPlistKey, plUtilType, shellValue, quotedPlistPosixPath}}
						else
							set setValueShellCommand to format {"plutil -replace {} -{} {} {}", {quotedPlistKey, plUtilType, shellValue, quotedPlistPosixPath}}

						end if

						return do shell script setValueShellCommand

					else if dataType is list then
						_insertList(quotedPlistKey, newValue)
						return

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


				on getString(plistKeyOrKeyList)
					set getStringShellCommand to _getTypedGetterShellTemplate("string", plistKeyOrKeyList)
					try
						return (do shell script getStringShellCommand) as text
					end try -- missing key

					missing value
				end getString

				on getDate(plistKeyOrKeyList)
					set dateZuluText to _getDateText(plistKeyOrKeyList)
					_zuluToLocalDate(dateZuluText)
				end getDate

				on _getDateText(plistKeyOrKeyList)
					set getDateShellCommand to _getTypedGetterShellTemplate("date", plistKeyOrKeyList)

					try
						return do shell script getDateShellCommand
					end try -- missing key
					missing value
				end _getDateText


				on getBool(plistKeyOrKeyList)
					set getBoolShellCommand to _getTypedGetterShellTemplate("bool", plistKeyOrKeyList)
					try
						set boolValue to do shell script getBoolShellCommand
						return boolValue is equal to "true"
					end try
					false
				end getBool

				on getInt(plistKeyOrKeyList)
					set getIntShellCommand to _getTypedGetterShellTemplate("integer", plistKeyOrKeyList)

					try
						return (do shell script getIntShellCommand) as integer
					end try -- missing key
					missing value
				end getInt

				on getReal(plistKeyOrKeyList)
					set getFloatShellCommand to _getTypedGetterShellTemplate("float", plistKeyOrKeyList)
					try
						return (do shell script getFloatShellCommand) as real
					end try -- missing key
					missing value
				end getReal


				on getList(plistKeyOrKeyList)
					set array to {}

					try
						set arrayTypeShellCommand to _getArrayTypeShellCommand(plistKeyOrKeyList)
						set arrayType to do shell script arrayTypeShellCommand
					on error
						set getValueShellCommand to _getTypedGetterShellTemplate(missing value, plistKeyOrKeyList)
						try
							do shell script getValueShellCommand
							return {}
						on error
							return missing value
						end try
					end try

					-- try
					-- 	set getArrayTypeShellCommand to format {"plutil -type {}.{} {}", {quotedEspacedPlistKey, 0, quotedPlistPosixPath}}
					-- 	set arrayType to do shell script getArrayTypeShellCommand
					-- on error
					-- 	try
					-- 		set shellCommand to "plutil -extract " & quotedEspacedPlistKey & " raw " & quotedPlistPosixPath
					-- 		do shell script shellCommand
					-- 		return {}
					-- 	end try

					-- 	return missing value
					-- end try

					-- Band Aid
					-- if (offset of "$" in quotedEspacedPlistKey) is greater than 0 then
					-- 	if quotedEspacedPlistKey contains "$" then set quotedEspacedPlistKey to regex's stringByReplacingMatchesInString("\\$", quotedEspacedPlistKey, "\\\\$")
					-- end if

					set quotedPlistKey to _quotePlistKey(plistKeyOrKeyList)
					set isTextParam to class of plistKeyOrKeyList is text
					if isTextParam then
						set plutilCommand to _shellEscape(plistKeyOrKeyList) & format {"\\
								XML=$(plutil -extract \"$TMP\" xml1 {} -o - ); \\
							else \\
								XML=$(plutil -extract {} xml1 {} -o -); \\
							fi && echo \"$XML\"", {quotedPlistPosixPath, quotedPlistKey, quotedPlistPosixPath}}

					else
						set plutilCommand to format {"plutil -extract {} xml1 {} -o - ", {quotedPlistKey, quotedPlistPosixPath}}
					end if

					set getTsvCommand to plutilCommand & (format {" \\
						| tail -n +5 \\
						| tail -r \\
						| tail -n +3 \\
						| tail -r \\
						| awk -F\">\" '{print $2}' \\
						| awk -F\"<\" '{print $1}' \\
						| sed 's/&lt;/</g' \\
						| sed 's/&gt;/>/g' \\
						| sed 's/&amp;/\\&/g' \\
						| sed 's/&quot;/\"/g' \\
						| sed \"s/&apos;/'/g\" \\
						| paste -s -d{} -", {my linesDelimiter}})

					set csv to do shell script getTsvCommand
					_split(csv, my linesDelimiter, arrayType)
				end getList


				on getRecord(plistKeyOrKeyList)
					set getRecordShellCommand to _getTypedGetterShellTemplate("record", plistKeyOrKeyList)
					try
						return (do shell script getRecordShellCommand) as record
					end try

					missing value
				end getRecord

				on getValueWithDefault(plistKeyOrKeyList, defaultValue)
					set fetchedValue to getValue(plistKeyOrKeyList)
					if fetchedValue is missing value then return defaultValue

					fetchedValue
				end getValueWithDefault


				(*
					@plistKeyOrKeyList - plist key for retrieval.
				*)
				on getValue(plistKeyOrKeyList)
					set getTypeShellCommand to _getTypeShellCommand(plistKeyOrKeyList)
					try
						set dataType to (do shell script getTypeShellCommand) as text
					on error the errorMessage number the errorNumber
						return missing value
					end try

					if dataType is "array" then
						return getList(plistKeyOrKeyList)

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

					else
						set getValueShellCommand to _getTypedGetterShellTemplate(missing value, plistKeyOrKeyList)

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


				on hasValue(plistKeyOrKeyList)
					getValue(plistKeyOrKeyList) is not missing value
				end hasValue


				(*
					Appends new element to an array. Will create the array if not found.
					Can append different type to array but is probably not a good idea.
					@Void
				*)
				on appendValue(plistKeyOrKeyList, newValue)
					if newValue is missing value then return

					set isTextParam to class of plistKeyOrKeyList is text
					-- logger's debugf("isTextParam: {}", isTextParam)

					set quotedPlistKey to _quotePlistKey(plistKeyOrKeyList)
					-- logger's debugf("quotedPlistKey: {}", quotedPlistKey)
					set quotedValue to _quoteValue(newValue)
					-- set escapedAndQuotedPlistKey to _escapeAndQuoteKey(plistKey)
					set plUtilType to _getPlUtilType(newValue)
					-- logger's debugf("plUtilType: {}", plUtilType)

					if not hasValue(plistKeyOrKeyList) then
						-- logger's debug("no value...")
						setValue(plistKeyOrKeyList, {})
					end if
					-- logger's debug("after has value")
					if isTextParam then
						set appendShellCommand to format {"
							if [[ \"{}\" == *\".\"* ]]; then TMP=$(echo \"{}\" | sed 's/\\./\\\\./g'); \\
								plutil -insert \"$TMP\" -{} {} -append {}; \\
							else \\
								plutil -insert {} -{} {} -append {}; \\
							fi
							", {plistKeyOrKeyList, plistKeyOrKeyList, plUtilType, quotedValue, quotedPlistPosixPath, quotedPlistKey, plUtilType, quotedValue, quotedPlistPosixPath}}
					else
						set appendShellCommand to format {"
							plutil -insert {} -{} {} -append {}
							", {quotedPlistKey, plUtilType, quotedValue, quotedPlistPosixPath}}
					end if
					-- logger's debug(appendShellCommand)

					do shell script appendShellCommand
				end appendValue


				(*
					@Known Issues:
						All elements are treated as string.
					@returns true if the targetElement is present and removed.
				*)
				on removeElement(plistKeyOrKeyList, targetElement)
					if targetElement is missing value then return false

					-- logger's debugf("plistKeyOrKeyList: {}", plistKeyOrKeyList as text)
					-- logger's debugf("targetElement: {}", targetElement)

					-- set quotedPlistKey to quoted form of plistKey
					set theList to getList(plistKeyOrKeyList)
					-- logger's debugf("theList: {}", theList as text)
					if theList is missing value then return false

					-- logger's debug(2)
					set targetIndex to _indexOf(theList, targetElement) - 1
					if targetIndex is less than 0 then return false

					-- logger's debug(3)
					set quotedPlistKey to _quotePlistKey(plistKeyOrKeyList)
					set quoteChar to text 1 thru 1 of quotedPlistKey
					set indexedKey to (text 1 thru -2 of quotedPlistKey) & "." & targetIndex & quoteChar

					if class of plistKeyOrKeyList is text then
						set deleteElementCommand to format {"
							if [[ \"{}\" == *\".\"* ]]; then \\
								TMP=$(echo \"{}\" | sed 's/\\./\\\\./g');\\
								plutil -remove \"$TMP.{}\" {}; \\
							else \\
								plutil -remove {} {}; \\
							fi", {plistKeyOrKeyList, plistKeyOrKeyList, targetIndex, quotedPlistPosixPath, indexedKey, quotedPlistPosixPath}}
					else
						set deleteElementCommand to format {"plutil -remove {} {}", {indexedKey, quotedPlistPosixPath}}

					end if
					do shell script deleteElementCommand
					true
				end removeElement


				(* @returns true on success. *)
				on deleteKey(plistKeyOrKeyList)
					if plistKeyOrKeyList is missing value then return false
					if {text, list} does not contain the class of plistKeyOrKeyList then return false

					set isTextParam to class of plistKeyOrKeyList is text
					set quotedPlistKey to _quotePlistKey(plistKeyOrKeyList)

					if isTextParam then
						set removeShellCommand to _shellEscape(plistKeyOrKeyList) & (format {"plutil -remove \"$TMP\" {}; \\
							else \\
								plutil -remove {} {}; \\
							fi", {my quotedPlistPosixPath, quotedPlistKey, my quotedPlistPosixPath}})
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
					Refactored the escaping part of the shell command. The result is not a valid shell command, but rather it needs to be
					prepended as part of the if-else shell command.
				*)
				on _shellEscape(plistKeyOrKeyList)
					format {"if [[ \"{}\" == *\".\"* ]]; then TMP=$(echo \"{}\" | sed 's/\\./\\\\./g');", {plistKeyOrKeyList, plistKeyOrKeyList}}
				end _shellEscape


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


				on _quotePlistKey(plistKeyOrKeyList)
					_validatePlistKey(plistKeyOrKeyList)

					if class of plistKeyOrKeyList is text then
						if regex's matches("^\\d", plistKeyOrKeyList) then
							set plistKeyOrKeyList to "_" & plistKeyOrKeyList
						end if
						return quoted form of plistKeyOrKeyList
					end if

					quoted form of _buildKeyNameFromList(plistKeyOrKeyList)
				end _quotePlistKey


				(* Validates the the plist key parameter, no real purpose except to validate input. *)
				on _validatePlistKey(plistKeyOrKeyList)
					if plistKeyOrKeyList is missing value then
						error "Plist Key is missing" number ERROR_PLIST_KEY_MISSING_VALUE
					else if class of plistKeyOrKeyList is text and textUtil's trim(plistKeyOrKeyList) is "" then
						error "Plist Key is empty" number ERROR_PLIST_KEY_EMPTY
					else if {text, list} does not contain the class of plistKeyOrKeyList then
						error "Plist Key type is not supported: " & class of plistKeyOrKeyList number ERROR_PLIST_KEY_INVALID_TYPE
					end if
				end _validatePlistKey


				on _getTypeShellCommand(plistKeyOrKeyList)
					set quotedPlistKey to _quotePlistKey(plistKeyOrKeyList)
					if class of plistKeyOrKeyList is text then
						_shellEscape(plistKeyOrKeyList) & (format {"plutil -type \"$TMP\" {}; \\
							else \\
								plutil -type {} {}; \\
							fi", {quotedPlistPosixPath, quotedPlistKey, quotedPlistPosixPath}})
					else
						format {"plutil -type {} {}", {quotedPlistKey, quotedPlistPosixPath}}
					end if
				end _getTypeShellCommand


				on _getArrayTypeShellCommand(plistKeyOrKeyList)
					set quotedPlistKey to _quotePlistKey(plistKeyOrKeyList)
					set quoteChar to text 1 thru 1 of quotedPlistKey
					set zeroIndexedKey to (text 1 thru -2 of quotedPlistKey) & ".0" & quoteChar

					if class of plistKeyOrKeyList is text then
						_shellEscape(plistKeyOrKeyList) & (format {"plutil -type \"$TMP.0\" {}; \\
							else \\
								plutil -type {} {}; \\
							fi
						", {quotedPlistPosixPath, zeroIndexedKey, quotedPlistPosixPath}})
					else
						format {"plutil -type {} {}", {zeroIndexedKey, quotedPlistPosixPath}}
					end if
				end _getArrayTypeShellCommand

				(*
					@typeText
					@plistKey
				*)
				on _getTypedGetterShellTemplate(typeText, plistKeyOrKeyList)
					set quotedKey to _quotePlistKey(plistKeyOrKeyList)

					set typeClause to ""
					if typeText is not missing value then set typeClause to "-expect " & typeText

					if (class of plistKeyOrKeyList) is text then
						set shellTemplate to _shellEscape(plistKeyOrKeyList) & "plutil -extract \"$TMP\" raw " & typeClause & " {}; \\
							else \\
								plutil -extract {} raw " & typeClause & " {}; \\
							fi"
						format {shellTemplate, {quotedPlistPosixPath, quotedKey, quotedPlistPosixPath}}
					else
						set shellTemplate to "plutil -extract {} raw " & typeClause & " {}"
						format {shellTemplate, {quotedKey, quotedPlistPosixPath}}
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
					set typedValue to nextElement as real
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

			0
		end _indexOf
	end script
	if isSpot then return PlutilInstance

	set decorator to decoratorLib's new(PlutilInstance)
	decorator's decorate()
end new
