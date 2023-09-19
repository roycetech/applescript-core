(*
	Classic implementation. Uses pure AppleScript access to plist which can lock
	the property file access for significant time when accessed by too many
	threads.

	@Project:
		applescript-core

	@Build:
		make compile-lib SOURCE=core/property-list
 *)

use script "core/Text Utilities"
use scripting additions

use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"

use spotScript : script "core/spot-test"

-- PROPERTIES =================================================================
property logger : missing value

property ERROR_PLIST_NOT_FOUND : 1000
property ERROR_PLIST_CREATE_ALREADY_EXISTS : 1001

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
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
		set plistName to "spot-plist"
		if not plistExists(plistName) then createNewPList(plistName)

		set spotPList to newInstance(plistName)
		set plistKey to "spot1"

		spotPList's setValue(plistKey, 1)
		log spotPList's getValue(plistKey)
		log spotPList's getValue("missing")
		log spotPList's hasValue("missing")
		log spotPList's hasValue(plistKey)

	else if caseIndex is 2 then
		try
			newInstance("godly")
			tell me to error "Error expected!"
		end try

	else if caseIndex is 3 then
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
		exists of (file plistBaseFilename of folder "applescript-core" of (path to home folder))
	end tell
end plistExists


(*
	Creates a new empty plist in the user hardcoded AppleScript folder.

	@throws error when plist already exists.
	@returns Void
*)
on createNewPList(plistName)
	if plistExists(plistName) then error (format {"Can't create plist, file '{}' already exists", plistName}) number ERROR_PLIST_CREATE_ALREADY_EXISTS

	set calcPlistFile to format {"~/applescript-core/{}.plist", {asProjectName, plistName}}
	tell application "System Events"
		set theParentDictionary to make new property list item with properties {kind:record}

		make new property list file with properties {contents:theParentDictionary, name:calcPlistFile}
	end tell
end createNewPList


on new(plistName)
	set calcPlistFilename to format {"~/applescript-core/{}.plist", {plistName}}

	tell application "Finder"
		if not (exists file (plistName & ".plist") of folder "applescript-core" of (path to home folder)) then
			tell me to error "The plist: " & plistName & " could not be found." number ERROR_PLIST_NOT_FOUND
		end if

		set localPlistPosixPath to text 8 thru -1 of (URL of folder "applescript-core" of (path to home folder) as text) & plistName & ".plist"
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

		on appendElement(plistKey, newValue)
			set theList to getValue(plistKey)
			if theList is missing value or theList is "" then set theList to {}
			set end of theList to newValue
			setValue(plistKey, theList)
		end appendElement

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

		(* This is used for new data. Updating an existing data requires a slightly different code. *)
		on _newValue(mapKey, newValue)
			tell application "System Events" to tell property list file plistFilename
				make new property list item at end with properties {kind:class of newValue, name:mapKey, value:newValue}
			end tell
		end _newValue
	end script
end new
