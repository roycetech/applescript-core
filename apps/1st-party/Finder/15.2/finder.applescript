(*
	For consistency:
		POSIX directories should never end with "/", it's up to the client to append it along with the file.
		POSIX Sub-directories must not start with "/", to make it obvious that it is not relative to root.

	WARNING: Finder is slow in general (not just this script). Avoid using the app Finder as much as possible.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Finder/15.2/finder

	@Last Modified: 2026-01-15 16:01:40
*)
use scripting additions
use script "core/Text Utilities"

use std : script "core/std"
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use finderTabLib : script "core/finder-tab"

use decFinderFolders : script "core/dec-finder-folders"
use decFinderFiles : script "core/dec-finder-files"
use decFinderPaths : script "core/dec-finder-paths"
use decFinderSelection : script "core/dec-finder-selection"
use decFinderView : script "core/dec-finder-view"

use decoratorLib : script "core/decorator"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	(* Have a Finder window open and manually verify result. *)
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		INFO:
		Integration: finder-tab
		Manual: New Tab for Path

		Misc Folders
		Manual: Current Folder
		Manual: Create From Template
		Get File Path

		Get File List
		Find Tab: Projects
		Manual: Add to SideBar (Manual: Needs/Does not need adding)

		Manual: Posix to Folder (View in Replies: User Path, Non-User Path, Applications)
		Manual: Create Folder as Needed

		Manual: Add to Sidebar
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()
	logger's infof("Is Busy: {}", sut's isBusy())
	logger's infof("Integration: User Path: {}", sut's getUserPath())
	logger's infof("Integration: View Type: {}", sut's getFileObjectViewType())

	if caseIndex is 1 then

	else if caseIndex is 2 then
		set frontTab to sut's getFrontTab()
		logger's infof("Folder Name: {}", frontTab's getFolderName())

	else if caseIndex is 3 then
		set sutPosixPath to "~/Projectsx"
		set sutPosixPath to "/Applications"
		set sutPosixPath to "~/Projects"
		set sutPosixPath to "~"
		set finderTab to sut's newTab(sutPosixPath)
		logger's infof("Handler result: {}", finderTab's getPath())

		-- REVIEW BELOW CASES

	else if caseIndex is 4 then
		tell application "Finder"
			set sut to file "wordlist.txt" of sut's getUserFolder()
		end tell
		log getFilePath(sut)

	else if caseIndex is 5 then
		tell application "Finder"
			repeat with nextFilename in my getFileList(folder "Ticket Templates" of folder "Extra Notes" of jada's getNotesFolder())
				log nextFilename
			end repeat
		end tell

	else if caseIndex is 7 then

	else if caseIndex is 8 then
		set foundTab to findTab("Projects")
		if foundTab is not missing value then
			foundTab's focus()

		else
			logger's info("Tab was not found")
		end if

	else if caseIndex is 9 then
		set foundTab to findTab("Projects")
		set addResult to foundTab's addToSideBar()
		logger's debugf("addResult: {}", addResult)

	else if caseIndex is 11 then
		logger's infof("Handler result: {}", sut's posixToFolder("/Users/" & std's getUsername() & "/applescript-core/logs"))
		logger's infof("Handler result: {}", sut's posixToFolder("/Applications"))
		logger's infof("Handler result: {}", sut's posixToFolder("/Applications/"))

	else if caseIndex is 15 then
		set websitesFolder to sut's posixToFolder("~/Documents/websites")
		sut's createFolderAsNeeded("poc", websitesFolder)

	else if caseIndex is 16 then
		sut's menuAddToSidebar()

	end if

	spot's finish()
	logger's finish()


	return

	openPath(":Macintosh HD:Users:")
	set theUserName to short user name of (system info)
	openPosixPath("/Users/" & theUserName)

end spotCheck


on new()
	loggerFactory's inject(me)

	script FinderInstance
		on menuAddToSidebar()
			if running of application "Finder" is false then return

			tell application "System Events" to tell process "Finder"
				set frontmost to true -- This is required to work.
				try
					click menu item "Add to Sidebar" of menu 1 of menu bar item "File" of menu bar 1
				end try
			end tell
		end menuAddToSidebar


		on isBusy()
			tell application "System Events" to tell process "Finder"
				exists (first window whose role description is "dialog")
			end tell
		end isBusy



		on putInTrash(posixPath)
			set computedPosixPath to untilde(posixPath)
			-- logger's debugf("computedPosixPath: {}", computedPosixPath)
			-- tell application "Finder" to delete POSIX file computedPosixPath
			(*
				The Finder delete action is executed via a shell script to
				prevent the main script from blocking during the operation.
			*)
			do shell script "osascript -e 'tell application \"Finder\" to delete POSIX file \"" & computedPosixPath & "\"'"
		end putInTrash


		on findTab(tabName)
			tell application "Finder"
				try
					set matchedWindow to first window whose name is equal to tabName
					return finderTabLib's new(id of matchedWindow)
				end try
			end tell

			missing value
		end findTab


		on newTab(posixPath)
			if posixPath is missing value then
				tell application "Finder"
					set finderWindow to make new Finder window
					return finderTabLib's new(id of front window)

				end tell
			end if

			set computedPosixPath to untilde(posixPath)
			set posixFileTarget to POSIX file computedPosixPath

			tell application "Finder"
				activate
				set finderWindow to make new Finder window
				try
					set target of finderWindow to posixFileTarget
				end try
				finderTabLib's new(id of front window)
			end tell
		end newTab


		on getFrontTab()
			if running of application "Finder" is false then return missing value
			if (count of windows of application "Finder") is 0 then return missing value

			tell application "Finder"
				finderTabLib's new(id of front window)
			end tell
		end getFrontTab


		on getFileList(folderObject)
			set filenameList to {}
			tell application "Finder"
				set filesInFolder to every item of folderObject

				repeat with nextFile in filesInFolder
					set end of filenameList to name of nextFile as text
				end repeat
			end tell
			filenameList
		end getFileList


		on untilde(tildePath)
			set posixPath to tildePath
			POSIX path of (path to home folder as text)
			set posixHomePath to text 1 thru -2 of result
			if tildePath is "~" then
				set posixPath to posixHomePath
			else if tildePath starts with "~" then
				set posixPath to textUtil's join({posixHomePath, text 3 thru -1 of posixPath}, "/")
			else
				set posixPath to tildePath
			end if
			posixPath
		end untilde
	end script

	decFinderFolders's decorate(result)
	decFinderFiles's decorate(result)
	decFinderPaths's decorate(result)
	decFinderSelection's decorate(result)
	decFinderView's decorate(result)

	set decorator to decoratorLib's new(result)
	decorator's decorateByName("FinderInstance")
end new
