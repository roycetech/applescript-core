global std, textUtil

use script "Core Text Utilities"
use scripting additions

(*
	Usage:
		set fileUtil to std's import("file")
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "file-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Unit Test
		POSIX File Exist
		POSIX File Don't Exist
		Read Text File
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set userPath to format {"/Users/{}", std's getUsername()}
	
	if caseIndex is 1 then
		unitTest()
		
	else if caseIndex is 2 then
		set existingFilePath to format {"{}/.zprofile", userPath}
		log posixFilePathExists(existingFilePath)
		
	else if caseIndex is 3 then
		set existingFilePath to format {"{}/virus.txt", userPath}
		log posixFilePathExists(existingFilePath)
		
	else if caseIndex is 4 then
		set posixPath to "/etc/hosts"
		logger's debugf("posixPath: {}", posixPath)
		log readFile(POSIX file posixPath)
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on readFile(posixFilePath as string)
	read file posixFilePath
end readFile


on posixFilePathExists(posixFilePath)
	set shellCommand to format {"test -f {} && echo 'true'", quoted form of posixFilePath}
	try
		return (do shell script shellCommand) is equal to "true"
	end try
	false
end posixFilePathExists


on readTempFile()
	tell application "Finder" to set theFile to file "applescript.tmp" of folder "AppleScript" of (path to home folder)
	
	set theFile to theFile as string
	
	read file theFile
end readTempFile

on writeTextToTempFile(theText as text)
	tell application "Finder"
		set targetFolder to folder "AppleScript" of (path to home folder)
		if not (exists of file "applescript.tmp" of targetFolder) then
			make new file at targetFolder with properties {name:"applescript.tmp", file type:"text"}
		end if
		
		set theFile to file "applescript.tmp" of folder "AppleScript" of (path to home folder)
	end tell
	
	try
		set theFile to theFile as string
		set theOpenedFile to open for access file theFile with write permission
		set eof of theOpenedFile to 0
		write theText to theOpenedFile starting at eof
		close access theOpenedFile
		
		return true
	on error
		try
			close access file theFile
		end try
		return false
	end try
end writeTextToTempFile

(*
	@filePath file path in Mac OS Notation (colon-separated) or POSIX
*)
on getBaseFileName(filePath)
	if (offset of ":" in filePath) is greater than 0 then -- Mac OS Notation
		set theDelimiter to ":"
	else -- assume POSIX format
		set theDelimiter to "/"
	end if
	
	set theList to textUtil's split(filePath, theDelimiter)
	last item of theList
end getBaseFileName


on convertPosixToMacOsNotation(posixFilePath)
	(POSIX file posixFilePath) as string
end convertPosixToMacOsNotation

(*
	@thePath Mac OS notation path e.g. Macintosh HD:Users...
*)
on convertPathToPOSIXString(thePath)
	tell application "System Events"
		try
			set thePath to path of disk item (thePath as string)
		on error
			set thePath to path of thePath
		end try
	end tell
	POSIX path of thePath
end convertPathToPOSIXString


-- Private Codes below =======================================================


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("file")
	set textUtil to std's import("string")
end init


on unitTest()
	set utLib to std's import("unit-test")
	set ut to utLib's new()
	tell ut
		newMethod("getBaseFileName")
		assertEqual("sublimetext3.applescript", my getBaseFileName("/Users/cloud.strife/projects/@rt-learn-lang/applescript/DEPLOYED/Common/sublimetext3.applescript"), "Happy Case")
		
		ut's done()
	end tell	
end unitTest