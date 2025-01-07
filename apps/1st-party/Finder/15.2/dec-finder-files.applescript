(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Finder/15.2/dec-finder-files

	@Created: Tuesday, December 31, 2024 at 6:11:21 PM
	@Last Modified: 2025-01-03 07:59:02
	@Change Logs:
*)
use scripting additions

use loggerFactory : script "core/logger-factory"

property logger : missing value

property SPOT_FILENAME : "wordlist.txt" -- Pre-existing test file used for spot checking only.
property SPOT_RENAMED_FILENAME : "renamed.txt"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Main
		Manual: Create File
		Manual: Copy File
		Manual: Rename File
		Manual: Move File - (Manually Revert)

		Manual: Delete File
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	-- activate application ""
	set sutLib to script "core/finder"
	set sut to sutLib's new()
	set sut to decorate(sut)

	(* Let's to our tests inside the /tmp where files are automatically purged. *)
	set tmpPath to "/tmp"
	set tempFolder to sut's posixToFolder(tmpPath)

	if caseIndex is 1 then

	else if caseIndex is 2 then
		tell application "Finder"
			set sourceFile to file SPOT_FILENAME of (path to home folder)
		end tell
		sut's createFile(sourceFile, tempFolder, "finder-spot.txt")
		sut's openPath("Macintosh HD:private:tmp:") -- To manually inspect.

	else if caseIndex is 3 then
		tell application "Finder"
			set sourceFile to file SPOT_FILENAME of (path to home folder)
		end tell

		set overwriteFlag to false -- Case 1/2: Don't overwrite
		-- set overwriteFlag to true  -- Case 2/2: Overwrite
		logger's infof("overwriteFlag: {}", overwriteFlag)

		set copyResult to sut's copyFile(sourceFile, tempFolder, overwriteFlag)
		if copyResult is missing value then
			logger's fatal("Copy failed!")
		else
			tell application "Finder"
				reveal copyResult
			end tell
		end if

	else if caseIndex is 4 then
		tell application "Finder"
			set fileReference to file SPOT_FILENAME of tempFolder
		end tell

		set renameResult to sut's renameFile(fileReference, SPOT_RENAMED_FILENAME)
		tell application "Finder" to reveal renameResult

	else if caseIndex is 5 then
		(* NOTE: Dependent on Case 4. *)
		tell application "Finder"
			set sourceFile to file SPOT_RENAMED_FILENAME of tempFolder
			set destFolder to folder "Delete Daily" of (path to home folder)
			sut's moveFile(sourceFile, destFolder) -- does not work when file and folder is passed directly to the handler.

			reveal file SPOT_RENAMED_FILENAME of destFolder -- May Hit Cmd + Z to undo the move on the Finder window.

		end tell

	else if caseIndex is 6 then
		(* NOTE: Dependent on Case 5. *)
		tell application "Finder"
			set fileReference to file SPOT_RENAMED_FILENAME of folder "Delete Daily" of (path to home folder)
		end tell
		sut's deleteFile(fileReference)

		tell application "Finder" to open folder "Delete Daily" of (path to home folder)
	else

	end if


	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script FinderFilesDecorator
		property parent : mainScript

		(* *)
		on createFile(sourceFile, targetFolder, newFilename)
			tell application "Finder"
				if exists file newFilename of targetFolder then error "File already exists"

				duplicate sourceFile to targetFolder

				(* Not very robust, not expecting lots of duped files with same name. *)
				if container of sourceFile is targetFolder then
					set nameTokens to textUtil's split(name of sourceFile, ".")
					set newFile to file (first item of nameTokens & " 2." & last item of nameTokens) of targetFolder
				else
					set newFile to file (name of sourceFile) of targetFolder
				end if

				set name of newFile to newFilename
			end tell
			newFile
		end createFile


		(*
			@returns the handle to the copied file if successful, otherwise return missing value.
		*)
		on copyFile(sourceFile, destinationFolder, overwriteFlag)
			tell application "Finder"
				if overwriteFlag then
					return duplicate sourceFile to destinationFolder with replacing
				end if

				-- else
				try
					return duplicate sourceFile to destinationFolder
				end try
			end tell
			missing value
		end copyFile


		on moveFile(sourceFile, destFolder)
			tell application "Finder"
				move sourceFile to destFolder
			end tell
		end moveFile

		(*
			@sourceMonPath - e.g. "Macintosh HD:Users:john:poc.txt"
			@newName - "joseph"
			@returns the file reference if successful, otherwise missing value

			WARNING: When testing, I renamed the file back to test again. This will result in Finder app freezing if the operation is not properly completed. To make sure it is completed, click on the empty space in the Finder after renaming the file manually.
			Leaving the selection on the file after renaming, causes the Finder app to freeze when you invoke this handler.
		*)
		on renameFile(fileReference, newName)
			if not (exists fileReference) then return missing value

			tell application "Finder" to set containerFolder to container of fileReference
			set name of fileReference to newName

			file newName of containerFolder
		end renameFile


		(*
			@returns true if delete is successful.
		*)
		on deleteFile(fileReference)
			tell application "Finder" to delete fileReference
		end deleteFile
	end script
end decorate
