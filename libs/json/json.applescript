global std

(* 
	@Prerequisites
		Requires JSON Helper app from the AppStore.  https://apps.apple.com/us/app/json-helper-for-applescript/id453114608?mt=12. 
		For testing, "AppleScript Core Project Path" needs to be set in config-system.plist.
		
	@Plists
		config-system.plist
			AppleScript Core Project Path
			
	@Installation
		make install-json
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "json-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	set configSystem to std's import("config")'s new("system")
	set asProjectPath to configSystem's getValue("AppleScript Core Project Path")
	
	set cases to listUtil's splitByLine("
		Read JSON File - Dictionary
		Read JSON File - List
		Convert object to JSON String
		From JSON String
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
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


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("json")
end init