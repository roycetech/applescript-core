global std, listUtil, sb, textUtil, json

(* 
	ASDictionary code derived from:
	Author(s): Philip Regan
	License: Copyright 2012 Philip Regan, https://github.com/oatmealandcoffee/ASDictionary
	
	NOT SUPPORTED: 
		- Map of Maps!
		- Saving to plist.
*)

use framework "Foundation"
use script "Core Text Utilities"
use scripting additions

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

try
on error the errorMessage number the errorNumber
	logger's finish() -- unlock the script active flag
	error errorMessage
end try


on spotCheck()
	init()
	set thisCaseId to "Map-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set config to std's import("config")'s new("system")
	
	set cases to listUtil's splitByLine("
		Unit Test
		From PList - Skip this
		From String
		From JSON String
		To String
		
		Iterate
		Debug getValueRecord
		Debug multiple colon
		Map of Maps
		Dollar Sign
	")
	
	set spotLib to std's import("spot")
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	if caseIndex is 1 then
		unitTest()
		
	else if caseIndex is 2 then
		set plistMap to config's getCategoryValue("system", "test map")
		set sut to fromRecord(plistMap)
		repeat with nextKey in sut's getKeys()
			log nextKey & " - " & sut's getValue(nextKey)
		end repeat
		log sut's toString()
		
	else if caseIndex is 3 then
		set sut to newInstanceFromString("
		ts: TypeScript
		md: Markdown
		applescript: AppleScript
		js: JavaScript
		rb: Ruby
		sh: Shell Script
		yml: YAML
		plist: Property List
		json: JSON
		cfc: Coldfusion Component
		cfm: Coldfusion Page
		Spec.cfc: Testbox
		Test.cfc: MxUnit
		txt: Text
		icns: macOS Icon Resource File
		")
		log sut's toString()
		
	else if caseIndex is 4 then
		set sut to newInstanceFromJson("{\"ts\": \"TypeScript\", \"md\": \"Markdown\"}")
		log sut's toString()
		
	else if caseIndex is 5 then
		set sut to fromRecord(plistMap)
		repeat with nextKey in sut's getKeys()
			logger's debugf("Key: {}, Value: {}", {nextKey, sut's getValue(nextKey)})
		end repeat
		
	else if caseIndex is 7 then
		tell application "Finder"
			set localPlistPosixPath to text 8 thru -1 of (URL of folder "applescript" of (path to home folder) as text) & "spot-plist.plist"
		end tell
		-- set getDictShellCommand to format {"/usr/libexec/PlistBuddy -c \"Print :{}\"  {} | awk '/^[[:space:]]/' | awk 'NF {$1=$1;print $0}' | sed 's/[[:space:]]=[[:space:]]/: /g'", {"spot-record", quoted form of localPlistPosixPath}}
		set getDictShellCommand to format {"/usr/libexec/PlistBuddy -c \"Print :{}\"  {} | awk '/^[[:space:]]/' | awk 'NF {$1=$1;print $0}'  | sed 's/:/__COLON__/g' | sed 's/[[:space:]]=[[:space:]]/: /g'", {"spot-record", quoted form of localPlistPosixPath}}
		set dictShellResult to do shell script getDictShellCommand
		logger's debugf("dictShellResult: {}", dictShellResult)
		
		set sut to newInstanceFromString(dictShellResult)
		log sut's toString()
		log sut's getKeys()
		
	else if caseIndex is 7 then
		set sut to newInstanceFromString("
			amazing OWA: kmtrigger://macro=Open%20Safari%20Group&amp;value=amazing%20OWA
			Personal OWA: kmtrigger://macro=Open%20Safari%20Group&amp;value=personal%20OWA
			IT Support Ticket: mailto:aPE.that.Rapport@amazing.com.au?body=LOCATION%3A%20Remote%0ALOB%3A%20Mobile%20%28Engineering%29%0ATeam%20Lead%3A%20Joyce%20Avestro%0AIssue/%20Request%3A%0ATime:%0AOther%20Details%3A
		")
		log sut's toString()
		
	else if caseIndex is 8 then
		set fried to new()
		set mav to newInstanceFromString("
			agent: none
			lawyer: max
			noone: nic	
		")
		fried's putValue("mav", mav)
		log fried's getValue("may")
		-- log fried's toString()
		set friedSon to fried's getValue("mav")
		log friedSon's toString()
		
	else if caseIndex is 9 then
		set sut to newInstanceFromString("
			amazing OWA: kmtrigger://macro=Open%20Safari%20Group&amp;value=amazing%20OWA$Special
		")
		log sut's toString()
	end if
	
	
	(*
	TODO: Move to unit test.

	set map to fromRecord({|name|:"Joe", special:"Danger"})
	
	log map's getValue("name")
	log map's getValue("special")
	
	map's putValue("custom", 1234)
	
	log map's getValue("no")
	log map's getValue("custom")
	logger's finish()
	
	set map2 to new()
	map2's putValue("name", "mich")
	
	log map's getValue("name")
	log map2's getValue("name")
	*)
	
	spot's finish()
	logger's finish()
end spotCheck


on newInstanceFromString(theText)
	set mapLines to listUtil's splitByLine(theText as text)
	set theMap to new()
	repeat with nextLine in mapLines
		set lineTokens to listUtil's _split(nextLine, ": ")
		set nextKey to first item of lineTokens
		set nextValue to second item of lineTokens
		if nextKey contains "__COLON__" then set nextKey to textUtil's replace(nextKey, "__COLON__", ":")
		if nextValue contains "__COLON__" then set nextValue to textUtil's replace(nextValue, "__COLON__", ":")
		-- theMap's putValue(nextKey, theMap's __JoinList(rest of lineTokens, ":"))
		theMap's putValue(nextKey, nextValue)
	end repeat
	
	theMap
end newInstanceFromString


on newInstanceFromRecord(theRecord as record)
	fromRecord(theRecord)
end newInstanceFromRecord


on hasJsonSupport()
	if not std's appExists("com.vidblishen.jsonhelper") then return false
	try
		set json to std's import("json")
		return true
	end try
	
	false
end hasJsonSupport


on newInstanceFromJson(jsonString)
	if hasJsonSupport() is false then
		error "The app 'JSON Helper' available in the App Store is required for this operation."
	end if
	
	set jsonRecord to json's fromJsonString(jsonString)
	return newInstanceFromRecord(jsonRecord)
	
	set keyList to __keys of jsonRecord
	set newRecord to new()
	repeat with nextKey in keyList
		newRecord's putValue(nextKey, |nextKey| of jsonRecord)
	end repeat
	newRecord
end newInstanceFromJson


(* @deprecated use newInstanceFromRecord *)
to fromRecord(theRecord as record)
	set objCDictionary to current application's NSDictionary's dictionaryWithDictionary:theRecord
	set allKeys to objCDictionary's allKeys()
	set theMap to new()
	
	repeat with theKey in allKeys
		set nextValue to (objCDictionary's valueForKey:theKey) as text
		theMap's putValue(theKey as text, nextValue)
	end repeat
	
	theMap
end fromRecord


to new()
	script ASDictionary
		(* Private properties *)
		property __keys : {}
		property __values : {}
		
		property __checkDataIntegrity : true
		
		
		on isEmpty()
			(number of getKeys()) is 0
		end isEmpty
		
		
		(* Simplified Handlers*)
		to putValue(theKey as text, theValue)
			setValueForKey(theValue, theKey)
		end putValue
		
		
		to getValue(theKey as text)
			valueForKey(theKey)
		end getValue
		
		
		to removeValue(theKey as text)
			removeValueForKey(theKey)
		end removeValue
		
		
		on clear()
			removeAllValues()
		end clear
		
		(* Public SubRoutines *)
		
		to hasKey(aKey) -- (object) as boolean
			
			set keyValueIndex to __getIndexForKey(aKey) of me
			
			if keyValueIndex is missing value then
				return false
			end if
			
			return true
		end hasKey
		
		to getKeys() -- (void) as list
			-- keys are in a list separate from the values so we need only return the list
			return __keys
		end getKeys
		
		to getValues() -- (void) as list
			return __values
		end getValues
		
		to setValueForKey(aValue, aKey) -- (object, object) as boolean			
			set keyValueIndex to __getIndexForKey(aKey) of me
			
			if keyValueIndex is missing value then
				set end of __values to aValue
				set end of __keys to aKey
				
				set keyValuePairsCount to count __keys
				my __setKeyAndIndexToHash(aKey, keyValuePairsCount)
			else
				set item keyValueIndex of __values to aValue
			end if
			
			return true
		end setValueForKey
		
		to removeValueForKey(aKey) -- (string) as void
			
			-- check if there is a value for the key
			set theIndex to __getIndexForKey(aKey)
			if theIndex = missing value then
				return
			end if
			
			-- if there is a value, replace that item in values with missing value
			set item theIndex of __values to missing value
			set item theIndex of __keys to missing value
			
			-- and replace the key in keys with missing value
			-- go to node in the hash and remove the index of the key-value pair
			
			set lastChr to (count aKey)
			set currentNode to __keyIndexHash of me
			
			repeat with chr from 1 to lastChr
				set nodeIdx to __chrToHashIndex(item chr of aKey) of me
				set currentNode to __getGlyphInNode(currentNode, nodeIdx)
				if currentNode is missing value then
					-- something bad happened that shouldn't have
					return
				end if
				-- we are where the index is located, so we clear the index so it cannot be found again as being valid
				if chr = lastChr then
					set index of currentNode to missing value
				end if
			end repeat
			
		end removeValueForKey
		
		to removeValuesForKeys(keys) -- (list) as void
			set lastKey to (count keys)
			repeat with thisKey from 1 to lastKey
				set theKey to item thisKey of keys
				my removeValueForKey(theKey)
			end repeat
		end removeValuesForKeys
		
		to removeAllValues() -- (void) as void)
			set __keys to {}
			set __values to {}
			set __keyIndexHash to {}
		end removeAllValues
		
		to valueForKey(aKey) -- (object) as object or (missing value)
			set keyValueIndex to __getIndexForKey(aKey) of me
			
			if keyValueIndex is missing value then
				return missing value
			end if
			
			return item keyValueIndex of __values
		end valueForKey
		
		to valueForIndex(anIndex) -- (integer) as object or (missing value)		
			set keysCount to count __keys
			
			-- we do not make any assumptions about how they got their index, so we simply check
			if (anIndex < 1) or (anIndex > keysCount) then
				return missing value
			end if
			
			return item anIndex of __values
		end valueForIndex
		
		to addValuesForKeys(someValues, someKeys) -- (list, list) -- as boolean
			set keysCount to (count someKeys)
			set valuesCount to (count someValues)
			
			
			set keysCount to (count someKeys)
			repeat with thisKey from 1 to keysCount
				try
					set theKey to item thisKey of someKeys
					set theValue to item thisKey of someValues
					set theResult to setValueForKey(theValue, theKey) of me
				on error
					-- fail silently
				end try
			end repeat
			
			return true
		end addValuesForKeys
		
		
		on toString()
			set resultBuilder to "{"
			repeat with nextKey in getKeys()
				set isFirst to resultBuilder is equal to "{"
				if not isFirst then set resultBuilder to resultBuilder & ", "
				set resultBuilder to resultBuilder & nextKey & ": " & getValue(nextKey)
			end repeat
			set resultBuilder to resultBuilder & "}"
		end toString
		
		
		on toJsonString()
			set keyList to getKeys()
			set nameValueList to {}
			set mainJsonBuilder to sb's new("{")
			repeat with i from 1 to count of keyList
				if i is not 1 then
					mainJsonBuilder's append(", ")
				end if
				
				set nextKey to item i of keyList
				set nextValue to getValue(nextKey)
				
				set end of nameValueList to nextKey
				set end of nameValueList to nextValue
				
				mainJsonBuilder's append("\"" & nextKey & "\": ")
				
				if nextValue is missing value then
					mainJsonBuilder's append("null")
					
				else if {integer, real, boolean} contains class of nextValue then
					mainJsonBuilder's append(nextValue)
					
				else
					mainJsonBuilder's append("\"" & nextValue & "\"")
				end if
			end repeat
			
			mainJsonBuilder's append("}")
			mainJsonBuilder's toString()
		end toJsonString
		
		
		(* 
				Private Subroutines
				All error checking is done before we get to these methods, so these should not be called directly.
				*)
		
		-- this is created in __setKeyAndIndexToHash when we actually need it.
		property __keyIndexHash : {}
		
		-- Unicode support: (* !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~*)
		
		property __val_lo : 32
		property __val_hi : 126
		
		property __val_0 : 48
		property __val_9 : 57
		property __upper_a : 65
		property __upper_z : 90
		property __lower_a : 97
		property __lower_z : 122
		
		property __unsupported_chr : __val_hi - __val_lo + 1
		
		on __makeGlyphNode() -- (void) as node
			(*
					index: the index in the key-value pairs list. 0 means there is not a key that exists
					nodes: the used characters for the keys
					*)
			set nodeList to {}
			repeat with i from 1 to __unsupported_chr
				set end of nodeList to missing value
			end repeat
			set theNode to {index:missing value, nodes:nodeList}
			return theNode
		end __makeGlyphNode
		
		on __makeGlyphInNode(parentNode, idx) --(node, int) as node
			-- check to see if there is already a node at that location
			set foundNode to item idx of nodes of parentNode
			if (foundNode is not missing value) then
				return foundNode
			end if
			-- make a new node if one isn't found
			set newNode to __makeGlyphNode() of me
			set item idx of nodes of parentNode to newNode
			return newNode
		end __makeGlyphInNode
		
		on __getGlyphInNode(parentNode, idx) --(node, int) as node
			return item idx of nodes of parentNode
		end __getGlyphInNode
		
		
		-- records the key into the hash table
		on __setKeyAndIndexToHash(key, idx) --(string, int) as void
			-- init the root has if need be
			if (count __keyIndexHash) = 0 then
				set __keyIndexHash to __makeGlyphNode() of me
			end if
			
			-- get the root as a place to kick off
			set newNode to __keyIndexHash
			
			-- iterate through the string
			set lastChr to (count key)
			repeat with chr from 1 to lastChr
				set nodeIdx to __chrToHashIndex(item chr of key) of me
				set newNode to __makeGlyphInNode(newNode, nodeIdx) of me
				if chr = lastChr then
					set index of newNode to idx
				end if
				
			end repeat
			
		end __setKeyAndIndexToHash
		
		-- takes a key and returns the index if it exists for that key, else returns missing value
		on __getIndexForKey(key) -- (string) as int or missing value
			if (count __keyIndexHash) = 0 then
				return missing value
			end if
			
			set currentNode to __keyIndexHash
			set idx to missing value
			set lastChr to (count key)
			
			repeat with chr from 1 to lastChr
				set nodeIdx to __chrToHashIndex(item chr of key) of me
				set currentNode to __getGlyphInNode(currentNode, nodeIdx)
				if currentNode is missing value then
					return missing value
				end if
				set idx to index of currentNode
			end repeat
			
			return idx
		end __getIndexForKey
		
		-- converts a char to its unicode equivalent, then a value useful to the hash
		on __chrToHashIndex(chr) -- (string) as int
			-- get the unicode value of the character
			set val to ((id of chr) - __val_lo) + 1
			
			if val is greater than or equal to __unsupported_chr or val is less than or equal to 1 then
				set val to __unsupported_chr
			end if
			
			return val
		end __chrToHashIndex
		
		on hashDescription()
			__traverseChildNodes(__keyIndexHash) of me
		end hashDescription
		
		on __traverseChildNodes(node)
			__printNode(node) of me
			repeat with i from 1 to __unsupported_chr
				if ((item i of nodes of node) is not missing value) then
					__traverseChildNodes(item i of nodes of node)
				end if
			end repeat
		end __traverseChildNodes
		
		on __printNode(node) -- (node) as string
			set output to {}
			
			repeat with i from 1 to __unsupported_chr
				if ((item i of nodes of node) is not missing value) then
					set end of output to (character id (i + __val_lo - 1))
				else
					set end of output to "."
				end if
			end repeat
			
			set end of output to index of node as string
			
			log __JoinList(output, " ") of me
		end __printNode
		
		on __JoinList(theList, TheDelimiter)
			set AppleScript's text item delimiters to {TheDelimiter}
			set theListAsText to theList as text
			set AppleScript's text item delimiters to ""
			return theListAsText
		end __JoinList
	end script
end new

-- Private Codes below =======================================================

(*
	Handler grouped by hundredths.
	Put the case you are debugging at the top, and move to correct place once verified.
*)
to unitTest()
	set utLib to std's import("unit-test")
	set ut to utLib's new()
	tell ut
		newMethod("newInstanceFromString")
		set sut to my newInstanceFromString("
			ts: TypeScript
			md: Markdown
		")
		assertEqual("TypeScript", sut's getValue("ts"), "First Item")
		assertEqual("Markdown", sut's getValue("md"), "Second Item")
		assertEqual(missing value, sut's getValue("nah"), "Not found")
		
		newMethod("toJsonString")
		assertEqual("{\"ts\": \"TypeScript\", \"md\": \"Markdown\"}", sut's toJsonString(), "Basic")
		
		newMethod("clear")
		sut's clear()
		assertEqual("{}", sut's toJsonString(), "Basic")
		
		newMethod("isEmpty")
		set sut to my new()
		assertTrue(sut's isEmpty(), "Empty")
		sut's putValue("first", "una")
		assertFalse(sut's isEmpty(), "Non-Empty")
		
		ut's done()
	end tell
	
end unitTest


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("map")
	set listUtil to std's import("list")
	set sb to std's import("string-builder")
	set textUtil to std's import("string")
end init
