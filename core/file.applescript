(*
	@Usage:
		use fileUtil : script "core/file"

	@Build:
		make compile-lib SOURCE=core/file

	@Change Log:
		July 26, 2023 4:11 PM - Add replaceText handler.

	@Last Modified: 2023-09-18 22:33:40
*)

use script "core/Text Utilities"
use scripting additions

use std : script "core/std"

use listUtil : script "core/list"
use textUtil : script "core/string"
use loggerFactory : script "core/logger-factory"

use spotScript : script "core/spot-test"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Unit Test
		POSIX File Exist
		POSIX File Don't Exist
		Read Text File
		Manual: POSIX Folder Exist
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
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

	else if caseIndex is 5 then
		set posixPath to "/Users/" & std's getUsername() & "/Desktop"
		logger's debugf("posix Folder Path exists: {}", posixFolderPathExists(posixPath))
		set posixPath to "/Users/" & std's getUsername() & "/Unicorn"
		logger's debugf("posix Folder Path exists: {}", posixFolderPathExists(posixPath))

	end if

	spot's finish()
	logger's finish()
end spotCheck


on insertBeforeEmptyLine(filePath, substring, textToInsert)
	-- TODO:
end insertBeforeEmptyLine


on deleteLineWithSubstring(filePath, substring)
	do shell script "filePath=" & _quotePath(filePath) & " && grep -v '" & substring & "' \"$filePath\" > /tmp/tmpfile && mv /tmp/tmpfile \"$filePath\"
"
end deleteText


(* @returns true if the file is successfully deleted. *)
on deleteFile(filePath)
	set command to  "rm " & _quotePath(filePath)
	try
		do shell script command
		return true
	end try

	false
end deleteText


on _quotePath(filePath)
	set quotedFilePath to filePath
	if filePath does not start with "~" then set quotedFilePath to quoted form of filePath
	quotedFilePath
end _quotePath


on replaceText(filePath, substring, replacement)
	set quotedFilePath to filePath
	if filePath does not start with "~" then set quotedFilePath to quoted form of filePath

	set escapedReplacement to replacement
	if replacement contains "&" then set escapedReplacement to textUtil's replace(replacement, "&", "\\&")
	if replacement contains "|" then set escapedReplacement to textUtil's replace(replacement, "|", "\\|")

	set command to "sed -i '' 's/" & substring & "/" & escapedReplacement & "/' " & quotedFilePath
	do shell script command
end replaceText


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


on posixFolderPathExists(posixFilePath)
	set shellCommand to format {"test -d {} && echo 'true'", quoted form of posixFilePath}
	try
		return (do shell script shellCommand) is equal to "true"
	end try
	false
end posixFolderPathExists


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
	@filePath file path in POSIX or Mac OS Notation (colon-separated)
*)
on getBaseFilename(filePath)
	if (offset of ":" in filePath) is greater than 0 then -- Mac OS Notation
		set theDelimiter to ":"
	else -- assume POSIX format
		set theDelimiter to "/"
	end if

	set theList to textUtil's split(filePath, theDelimiter)
	last item of theList
end getBaseFilename


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

