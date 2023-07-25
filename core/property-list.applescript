(*
	Classic implementation. Uses pure AppleScript access to plist which can lock
	the property file access for significant time when accessed by too many
	threads.
 *)

use script "Core Text Utilities"
use scripting additions

use listUtil : script "list"

use loggerFactory : script "logger-factory"

use spotScript : script "spot-test"
use testLib : script "test"


-- PROPERTIES =================================================================
property logger : missing value
property test : testLib's new()

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)

	logger's start()

	set cases to listUtil's splitByLine("
		Unit Test
		Create new plist
		Instantiate non-existent plist
		Debug Note Menu Links
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set spotPList to new("spot-plist")
	if caseIndex is 1 then
		unitTest()

	else if caseIndex is 2 then
		set plistName to "spot-plist"
		if not plistExists(plistName) then createNewPList(plistName)

		set spotPList to newInstance(plistName)
		set plistKey to "spot1"

		spotPList's setValue(plistKey, 1)
		log spotPList's getValue(plistKey)
		log spotPList's getValue("missing")
		log spotPList's hasValue("missing")
		log spotPList's hasValue(plistKey)

	else if caseIndex is 3 then
		try
			newInstance("godly")
			tell me to error "Error expected!"
		end try

	else if caseIndex is 4 then
		set sut to newInstance("app-menu-links")
		log sut's getValue("Sublime Text")'s toString()

	end if

	spot's finish()
	logger's finish()
end spotCheck


-- Start of actual handlers ================

on plistExists(plistName)
	set plistBaseFilename to format {"{}.plist", plistName}
	tell application "Finder"
		exists of (file plistBaseFilename of folder "applescript" of (path to home folder))
	end tell
end plistExists


(*
	Creates a new empty plist in the user hardcoded AppleScript folder.

	@throws error when plist already exists.
	@returns Void
*)
on createNewPList(plistName)
	if plistExists(plistName) then error format {"Can't create plist, file '{}' already exists", plistName}

	set asProjectName to _getAsFolderName()
	set calcPlistFile to format {"~/{}/{}.plist", {asProjectName, plistName}}
	tell application "System Events"
		set theParentDictionary to make new property list item with properties {kind:record}

		make new property list file with properties {contents:theParentDictionary, name:calcPlistFile}
	end tell
end createNewPList


on new(plistName)
	set asProjectName to _getAsFolderName()
	set calcPlistFilename to format {"~/{}/{}.plist", {asProjectName, plistName}}

	tell application "Finder"
		if not (exists file (plistName & ".plist") of folder "applescript" of (path to home folder)) then
			tell me to error "The plist: " & plistName & " could not be found."
		end if

		set localPlistPosixPath to text 8 thru -1 of (URL of folder "applescript" of (path to home folder) as text) & plistName & ".plist"
	end tell

	script PListClassicInstance
		property plistFilename : calcPlistFilename
		property quotedPlistPosixPath : quoted form of localPlistPosixPath

		-- HANDLERS ==================================================================
		on setValue(plistKey, newValue)
			tell application "System Events"
				if newValue is equal to missing value and my getValue(plistKey) is not missing value then
					tell property list file plistFilename to set value of property list item plistKey to ""
					return
				end if

				if my getValue(plistKey) is equal to missing value then
					my _newValue(plistKey, newValue)
				else
					tell property list file plistFilename to set value of property list item plistKey to newValue
				end if
			end tell
		end setValue

		on getValue(plistKey)
			tell application "System Events" to tell property list file plistFilename
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
			set quotedPlistKey to quoted form of plistKey
			set appendShellCommand to format {"plutil -insert {} -integer 3 -append spot-plist.plist ", {quotedPlistKey}}

			set theList to getValue(mapKey)
			if theList is missing value or theList is "" then set theList to {}
			set end of theList to newValue
			setValue(plistKey, theList)
		end appendValue

		(* @returns true on success. *)
		on deleteKey(plistKey)
			set quotedPlistKey to quoted form of plistKey
			-- set localQuotedPosixPath to quotedPlistPosixPath
			set removeShellCommand to format {"plutil -remove {} {}", {quotedPlistKey, my quotedPlistPosixPath}}
			try
				do shell script removeShellCommand
				return true
			end try
			false
		end deleteKey

		on _newValue(mapKey, newValue)
			tell application "System Events" to tell property list file plistFilename
				make new property list item at end with properties {kind:class of newValue, name:mapKey, value:newValue}
			end tell
		end _newValue
	end script
end new


-- Private Codes below =======================================================
on _getAsFolderName()
	tell application "Finder" -- Set the project folder name in the correct case
		name of folder "applescript" of (path to home folder) as text
	end tell
end _getAsFolderName


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
		else
			copy nextElement to typedValue
		end if
		set end of typedArray to typedValue
	end repeat

	typedArray
end _split


to unitTest()
	set ut to test's new()
	set sut to new("spot-plist")
	tell ut
		newMethod("setup")
		sut's deleteKey("spot-array")
		sut's deleteKey("spot-string")
		sut's deleteKey("spot-string-dotted")
		sut's deleteKey("spot-integer")
		sut's deleteKey("spot-float")
		sut's deleteKey("spot-date")
		sut's deleteKey("spot-bool")
		sut's deleteKey("spot-record")
		assertEqual(missing value, sut's getValue("spot-array"), "Clean array key")

		newMethod("setValue")
		sut's setValue("spot-array", {1, 2})
		sut's setValue("spot-string", "text")
		sut's setValue("text.exe", "spot-string-dotted")
		sut's setValue("spot-integer", 1)
		sut's setValue("spot-float", 1.5)
		sut's setValue("spot-record", {one:1, two:2, three:"a&c"})

		set zuluAdjust to 8 -- manually add/subtract hours if need to test before/after, arvo/midnight
		logger's debugf("zulu adjustment hour: {}", zuluAdjust)
		set currentDate to (current date) + zuluAdjust * hours
		sut's setValue("spot-date", currentDate)

		sut's setValue("spot-bool", false)

		newMethod("getValue")
		set arrayValue to sut's getValue("spot-array")
		assertEqual(2, count of arrayValue, "Get array count")
		assertEqual(1, first item of arrayValue, "Get array element first")
		assertEqual(2, last item of arrayValue, "Get array element last")
		assertEqual("text", sut's getValue("spot-string"), "Get string value")
		assertEqual(1, sut's getValue("spot-integer"), "Get integer value")
		assertEqual(1.5, sut's getValue("spot-float"), "Get float value")
		assertEqual(currentDate, sut's getValue("spot-date"), "Get date value")
		assertEqual(false, sut's getValue("spot-bool"), "Get bool value")

		assertEqual({one:1, two:2, three:"a&c"}, sut's getValue("spot-record"), "Get record value")

		newMethod("update")
		sut's setValue("spot-bool", 1)
		assertEqual(1, sut's getValue("spot-bool"), "Update bool to integer")

		newMethod("hasValue")
		assertEqual(false, sut's hasValue("spot-unicorn"), "Value not found")
		assertEqual(true, sut's hasValue("spot-bool"), "Value found")

		newMethod("append")

		done()
	end tell
end unitTest
