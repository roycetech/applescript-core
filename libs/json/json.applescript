(* 
	@Prerequisites
		Requires JSON Helper app from the AppStore.  https://apps.apple.com/us/app/json-helper-for-applescript/id453114608?mt=12. 
		Accessibility permission for JSON Helper. You simply need to confirm access on the first time you run this script to spot check.
		
	@Plists
		config-system.plist
			AppleScript Core Project Path - This is required for testing only.
			
	@Build:
		make compile-json
*)

use scripting additions

use listUtil : script "list"


use loggerLib : script "logger"
use configLib : script "config"

use spotScript : script "spot-test"

property logger : loggerLib's new("json")

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	logger's start()
	
	set configSystem to configLib's new("system")
	set asProjectPath to configSystem's getValue("AppleScript Core Project Path")
	set cases to listUtil's splitByLine("
		Read JSON File - Dictionary
		Read JSON File - List
		Convert object to JSON String
		From JSON String
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	if caseIndex is 1 then
		set jsonData to readJsonFile(asProjectPath & "/test/fixtures/sample-1.json")
		log jsonData
		
		log |menu| of jsonData
		log menuitem of popup of |menu| of jsonData
		
	else if caseIndex is 2 then
		log readJsonFile(asProjectPath & "/test/fixtures/sample-2.json")
		
	else if caseIndex is 3 then
		log toJsonString({|name|:"Hadooken", startDate:missing value})
		
	else if caseIndex is 4 then
		log class of fromJsonString("{\"name\":\"Havok\", \"last\":\"Noise\"}")
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(* @returns record. *)
on readJsonFile(posixPath)
	set jsonFile to POSIX file posixPath
	set jsonText to _readFile(jsonFile)
	tell application "JSON Helper" to read JSON from jsonText
end readJsonFile


(*
	@returns record of the json text.
*)
on fromJsonString(jsonText)
	tell application "JSON Helper" to read JSON from jsonText
end fromJsonString


on toJsonString(serializableObject)
	tell application "JSON Helper"
		make JSON from serializableObject
	end tell
end toJsonString


-- Private Codes below =======================================================
on _readFile(theFile)
	-- Convert the file to a string
	set theFile to theFile as string
	-- Read the file and return its contents
	read file theFile
end _readFile
