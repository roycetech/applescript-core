(*
	@Usage:
		use fileUtil : script "core/file"

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/file

	@Change Log:
		July 26, 2023 4:11 PM - Add replaceText handler.

	@Last Modified: 2025-04-28 09:32:50
*)

use script "core/Text Utilities"
use scripting additions

use std : script "core/std"

use textUtil : script "core/string"
use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Read Text File
		Manual: Modification Date
		Manual: Creation Date
	")
	
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set userPath to format {"/Users/{}", std's getUsername()}
	set existingFilePath to format {"{}/.zprofile", userPath}
	logger's infof("Existing file exists: {}", posixFilePathExists(existingFilePath))
	
	set nonExistingFilePath to format {"{}/virus.txt", userPath}
	logger's infof("Non-Existing file does not exist: {}", posixFilePathExists(nonExistingFilePath))
	
	set posixPath to "/Users/" & std's getUsername() & "/Desktop"
	logger's infof("Existing Posix Folder Path exists: {}", posixFolderPathExists(posixPath))
	set posixPath to "/Users/" & std's getUsername() & "/Unicorn"
	logger's infof("Non-existing Posix Folder Path does not exists: {}", posixFolderPathExists(posixPath))
	
	if caseIndex is 1 then
		set posixPath to "/etc/hosts"
		logger's debugf("posixPath: {}", posixPath)
		logger's infof("File contents: {}", readFile(POSIX file posixPath))
		
	else if caseIndex is 2 then
		getModificationDate("/Users/" & std's getUsername() & "/wordlist.txt")
		logger's infof("Modification Date: {}", getModificationDate("/Users/" & std's getUsername() & "/wordlist.txt"))
		
	else if caseIndex is 3 then
		logger's infof("Creation Date: {}", getCreationDate("/Users/" & std's getUsername() & "/wordlist.txt"))
		
	else if caseIndex is 4 then
		
	else if caseIndex is 5 then
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on insertBeforeEmptyLine(filePath, substring, textToInsert)
	set quotedFilePath to quoteFilePath(filePath)
	try
		-- Use sed to find the substring and insert textToInsert after it on the next empty line
		set command to "awk -v header=\"" & substring & "\" -v text='" & textToInsert & "' '
	BEGIN {
	    in_target_block = 0;
	}
	$0 ~ header {
	    print $0;
	    in_target_block = 1;
	    next;
	}
	in_target_block == 1 && NF == 0 {
	    print text;
	    in_target_block = 0;
	}
	{ print $0}
	' " & quotedFilePath & " > /tmp/tmpfile && mv /tmp/tmpfile " & quotedFilePath
		do shell script command
		return true -- Success
	on error the errorMessage number the errorNumber
		log errorMessage
		return false -- Error occurred
	end try
end insertBeforeEmptyLine


on deleteLineWithSubstring(filePath, substring)
	do shell script "filePath=" & _quotePath(filePath) & " && grep -v '" & substring & "' \"$filePath\" > /tmp/tmpfile && mv /tmp/tmpfile \"$filePath\"
"
end deleteLineWithSubstring


(* @returns true if the file is successfully deleted. *)
on deleteFile(filePath)
	set command to "rm " & _quotePath(filePath)
	try
		do shell script command
		return true
	end try
	
	false
end deleteFile


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
	
	set command to "sed -i '' \"s/" & substring & "/" & escapedReplacement & "/\" " & quotedFilePath
	do shell script command
end replaceText


(* @posixFilePath - need to pass "POSIX file c:/System32". For review later. *)
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
	@returns the name of the file with its extension/s.
*)
on getBaseFilename(filePath)
	if filePath is missing value then return missing value
	if filePath is "" then return missing value
	
	-- if (offset of ":" in filePath) is greater than 0 then  -- Mac OS Notation
	-- if (offset of "/" in filePath) is greater than 0 then -- POSIX Notation
	if filePath contains "/" then -- POSIX Notation
		set theDelimiter to "/"
		
		-- else if (offset of ":" in filePath) is greater than 0 then -- assume Mac OS Notation
	else if filePath contains ":" then -- assume Mac OS Notation
		set theDelimiter to ":"
		
	else
		error "Could not determine the file separator: " & filePath
		
	end if
	
	set theList to textUtil's split(filePath, theDelimiter)
	last item of theList
end getBaseFilename


on getFolderName(filePath)
	if filePath is missing value then return missing value
	
	set tokens to textUtil's split(filePath, "/")
	if the (count of tokens) is 2 and filePath starts with "~" then return std's getUsername()
	if the (count of tokens) is less than 3 then return missing value
	
	item -2 of tokens
end getFolderName


on getContainingDirectory(filePath)
	if filePath is missing value then return missing value
	
	set cleanFilePath to expandTildePath(filePath)
	if cleanFilePath ends with "/" then set cleanFilePath to text 1 thru -2 of cleanFilePath
	set tokens to textUtil's split(cleanFilePath, "/")
	if the (count of tokens) is 2 then return "/"
	
	textUtil's join(reverse of rest of reverse of tokens, "/")
end getContainingDirectory


on quoteFilePath(posixFilePath)
	if posixFilePath is missing value then return missing value
	if posixFilePath starts with "~" then return posixFilePath
	
	quoted form of posixFilePath
end quoteFilePath


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


on convertPathToTilde(filePath)
	set markerText to "/Users/" & std's getUsername()
	if filePath starts with markerText then
		return textUtil's replace(filePath, markerText, "~")
	end if
	
	filePath
end convertPathToTilde


on expandTildePath(tildePath)
	textUtil's replace(tildePath, "~", "/Users/" & std's getUsername())
end expandTildePath


on containsText(filePath, substring)
	try
		set shellCommand to "grep " & quoted form of substring & " " & quoteFilePath(filePath)
		do shell script shellCommand
		return true
	end try
	false
end containsText


on getModificationDate(filePath)
	if filePath is missing value then return missing value
	
	set modificationDateStr to do shell script "stat -f %Sm -t \"%Y %m %d %H:%M:%S\" " & quoted form of filePath
	set {ye, mo, da, Ho, mi, se} to words of modificationDateStr
	
	set t to Ho * hours + mi * minutes + se
	set modificationDate to current date
	set modificationDate's year to ye
	set modificationDate's month to mo
	set modificationDate's day to da
	set modificationDate's time to t
	modificationDate
end getModificationDate


on getCreationDate(filePath)
	if filePath is missing value then return missing value
	
	set creationDateStr to do shell script "stat -f %Sc -t \"%Y %m %d %H:%M:%S\" " & quoted form of filePath
	set {ye, mo, da, Ho, mi, se} to words of creationDateStr
	
	set t to Ho * hours + mi * minutes + se
	set creationDate to current date
	set creationDate's year to ye
	set creationDate's month to mo
	set creationDate's day to da
	set creationDate's time to t
	creationDate
end getCreationDate
