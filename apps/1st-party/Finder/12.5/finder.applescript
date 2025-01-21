(*
	For consistency:
		POSIX directories should never end with "/", it's up to the client to append it along with the file.
		POSIX Sub-directories must not start with "/", to make it obvious that it is not relative to root.

	WARNING: Finder is slow in general (not just this script). Avoid using the app Finder as much as possible.

	NOTE: This version still works on macOS v15

	@Prerequisites:
		keyboard.applescript - some handlers require key presses.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Finder/12.5/finder

	@Last Modified: 2024-12-31 15:56:28
*)

use script "core/Text Utilities"
use scripting additions

use std : script "core/std"
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"
use decoratorLib : script "core/decorator"

property logger : missing value
property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	(* Have a Finder window open and manually verify result. *)
	set spotScript to script "core/spot-test"
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Misc Folders
		Manual: Selection (None, One, Multi)
		Manual: Current Folder
		Manual: Create From Template
		Get File Path

		Get File List
		Move File - (Manually Revert)
		New Tab for Path
		Find Tab: Projects
		Manual: Add to SideBar (Manual: Needs/Does not need adding)

		Manual: Posix to Folder (View in Replies: User Path, Non-User Path, Applications)
		Manual: Copy File
		Manual: Rename File
		Manual: Delete File
		Manual: Create Folder as Needed

		Manual: Add to Sidebar
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()
	logger's infof("Is Busy: {}", sut's isBusy())
	if caseIndex is 1 then
		logger's infof("User Folder: {}", sut's getUserFolder()) -- aka Home Folder
		logger's infof("User Path: {}", sut's getUserPath())
		logger's infof("User Library Folder: {}", sut's getUserLibraryFolder())
		logger's infof("User Scripts Folder: {}", sut's getUserScriptsFolder())
		logger's infof("Applications Folder: {}", sut's getApplicationsFolder())
		logger's infof("Trash Folder: {}", sut's getTrashFolder())

	else if caseIndex is 2 then
		logger's infof("Selected Objects: {}", sut's getSelection())
		logger's infof("First Selected File Path: {}", sut's getFirstSelectionPath())
		logger's infof("First Selected File URL: {}", sut's getFirstSelectionURL())
		logger's infof("First Selected Filename: {}", sut's getFirstSelectionName())
		logger's infof("First Selected Object Type: {}", sut's getFirstSelectionObjectType())

	else if caseIndex is 3 then
		set frontTab to sut's getFrontTab()
		logger's infof("Get Path: {}", frontTab's getPath())
		logger's infof("Folder Name: {}", frontTab's getFolderName())
		logger's infof("URL: {}", frontTab's getURL())

	else if caseIndex is 3 then -- WIP From here to cases below.
		tell application "Finder"
			set targetFolder to folder "Delete Daily" of my getUserFolder()
			set sourceFile to file "wordlist.txt" of my getUserFolder()
		end tell
		sut's createFile(sourceFile, targetFolder, "finder-spot.txt")

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

	else if caseIndex is 6 then
		tell application "Finder"
			set sourceFile to file "wordlist.txt" of (path to home folder)
			set destFolder to folder "Delete Daily" of (path to home folder)
			my moveFile(sourceFile, destFolder) -- does not work when file and folder is passed directly to the handler.

			reveal file "wordlist.txt" of destFolder -- May Hit Cmd + Z to undo the move on the Finder window.
		end tell

	else if caseIndex is 7 then
		set sutPosixPath to "~/Projectsx"
		set sutPosixPath to "/Applications"
		set sutPosixPath to "~/Projects"
		set finderTab to newTab(sutPosixPath)
		log finderTab's getPath()

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

	else if caseIndex is 12 then
		tell application "Finder"
			set sourceFile to file "wordlist.txt" of (path to home folder)
			set destFolder to folder "Delete Daily" of (path to home folder)
		end tell

		set copyResult to sut's copyFile(sourceFile, destFolder, false) -- Test false and true
		if copyResult is missing value then
			logger's fatal("Copy failed!")
		else
			tell application "Finder"
				reveal copyResult
			end tell
		end if

	else if caseIndex is 13 then
		-- Below code results in freeze when put inside the tell block.
		set homePath to path to home folder
		tell application "Finder"
			set fileReference to file "poc.txt" of folder "Delete Daily" of homePath
		end tell

		set renameResult to sut's renameFile(fileReference, "renamed.txt")
		tell application "Finder" to reveal renameResult

	else if caseIndex is 14 then
		do shell script "touch ~/Delete\\ Daily/spot-delete.txt"
		delay 1
		tell application "Finder"
			set fileReference to file "spot-delete.txt" of folder "Delete Daily" of (path to home folder)
		end tell
		sut's deleteFile(fileReference)

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
	set kb to kbLib's new()

	script FinderInstance
		on menuAddToSidebar()
			if running of application "Finder" is false then return

			tell application "System Events" to tell process "Finder"
				set frontmost to true
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


		(*
			@returns true if delete is successful.
		*)
		on deleteFile(fileReference)
			tell application "Finder" to delete fileReference
		end deleteFile

		on putInTrash(posixPath)
			set computedPosixPath to _untilde(posixPath)
			logger's debugf("computedPosixPath: {}", computedPosixPath)
			-- tell application "Finder" to delete POSIX file computedPosixPath
			-- Why did I use do shell script instead of running the code directly?
			do shell script "osascript -e 'tell application \"Finder\" to delete POSIX file \"" & computedPosixPath & "\"'"
		end putInTrash


		on findTab(tabName)
			tell application "Finder"
				try
					set matchedWindow to first window whose name is equal to tabName
					return my _new(id of matchedWindow)
				end try
			end tell

			missing value
		end findTab


		on newTab(posixPath)
			if posixPath is missing value then
				tell application "Finder"
					set finderWindow to make new Finder window
					return my _new(id of front window)
				end tell
			end if

			set computedPosixPath to _untilde(posixPath)
			set posixFileTarget to POSIX file computedPosixPath

			tell application "Finder"
				activate
				set finderWindow to make new Finder window
				try
					set target of finderWindow to posixFileTarget
				end try
				my _new(id of front window)
			end tell
		end newTab


		on _untilde(tildePath)
			set posixPath to tildePath
			if tildePath is "~" then
				set posixPath to format {"/Users/{}/", std's getUsername()}
			else if tildePath starts with "~" then
				set posixPath to format {"/Users/{}/{}", {std's getUsername(), text 3 thru -1 of posixPath}}
			end if
			-- logger's debugf("posixPath: {}", posixPath)
			posixPath
		end _untilde


		on getFrontTab()
			if running of application "Finder" is false then return missing value

			tell application "Finder"
				if (count of windows) is 0 then return missing value
			end tell

			tell application "Finder"
				my _new(id of front window)
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


		on getFilePath(fileObject)
			tell application "Finder"
				set fileUrl to URL of fileObject
			end tell
			set fileLess to textUtil's stringAfter(fileUrl, "file://")
			textUtil's replace(fileLess, "%20", " ")
		end getFilePath


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

			WARNING: When testing, I renamed the file back to test again. This will result in Finder app freezing if the operation is not properly completed. To make sure it is completed, click on the empty space in the Finder after renaming the file manually. Leaving the selection on the file after renaming, causes the Finder app to freeze when you invoke this handler.
		*)
		on renameFile(fileReference, newName)
			if not (exists fileReference) then return missing value

			tell application "Finder" to set containerFolder to container of fileReference
			set name of fileReference to newName

			file newName of containerFolder
		end renameFile


		on _new(windowId)
			script FinderInstance
				property appWindow : missing value -- not syseve window.

				(* @returns true if successful in adding. *)
				on addToSideBar()
						set inSideBar to false
					tell application "System Events" to tell process "Finder"
						repeat with nextRow in rows of outline 1 of scroll area 1 of splitter group 1 of window (name of appWindow)
							if value of static text 1 of UI element 1 of nextRow is equal to the name of appWindow then
								set inSideBar to true
								exit repeat
							end if
						end repeat
					end tell
					-- logger's debugf("inSideBar: {}", inSideBar)

					if not inSideBar then
						activate application "Finder"
						delay 0.1

						kb's pressCommandControl("t")
						return true
					end if

					false
				end addToSideBar


				on getURL()
					if running of application "Finder" is false then return missing value
					tell application "System Events" to tell process "Finder"
						if (count of windows) is 0 then return missing value
					end tell

					focus()
					tell application "Finder"
						set currentFolder to insertion location
						try
							return URL of currentFolder as text
						end try -- Ignore special locations like Recents.
					end tell
					missing value
				end getURL


				on getPath()
					set finderUrl to getURL()
					if finderUrl is missing value then return missing value

					text 1 thru -2 of textUtil's decodeUrl(textUtil's stringAfter(finderUrl, "file://"))
				end getPath


				on getFolderName()
					tell application "Finder"
						set currentFolder to insertion location
					end tell
					name of currentFolder -- would not work if we do 'name of insert location' inside the tell Finder block.
				end getFolderName

				on focus()
					tell application "Finder"
						set index of my appWindow to 1
					end tell
				end focus
			end script

			tell application "Finder" to set appWindow of FinderInstance to window id windowId
			FinderInstance
		end _new



		(* @param posixPath the string path e.g. /Users/you.name *)
		on openPosixPath(posixPath)
			tell application "Finder"
				activate
				set finderWindow to make new Finder window
				set target of finderWindow to POSIX file posixPath
			end tell
		end openPosixPath


		(* @param thePath Mac OS Notation folder path e.g. :Macintosh HD:Users: *)
		on openPath(thePath)
			tell application "Finder"
				activate
				set finderWindow to make new Finder window
				set target of finderWindow to thePath
			end tell
		end openPath


		(* @returns the selected objects. Empty list if none is selected. *)
		on getSelection()
			tell application "Finder"
				selection
			end tell
		end getSelection


		on getFirstSelectionPath()
			textUtil's replace(textUtil's stringAfter(getFirstSelectionURL(), "file://"), "%20", " ")
		end getFirstSelectionPath


		on getFirstSelectionURL()
			set userSelection to getSelection()
			if (the number of items in userSelection) is 0 then return missing value

			set firstSelection to first item of userSelection
			tell application "Finder"
				URL of firstSelection
			end tell
		end getFirstSelectionURL


		on getFirstSelectionName()
			set userSelection to getSelection()
			if (the number of items in userSelection) is 0 then return missing value

			set firstSelection to first item of userSelection
			name of firstSelection
		end getFirstSelectionName


		(*
			@returns
				folder - if folder is selected.
					.app - returns "app".
				file - the file extension
		*)
		on getFirstSelectionObjectType()
			set selectedFile to missing value
			try
				set selectedFile to first item of getSelection()
			end try
			if selectedFile is missing value then return missing value

			set filename to name of selectedFile
			if class of selectedFile as text is equal to "folder" then
				if filename ends with ".app" then return "app"
				return "folder"
			end if

			set filenameTokens to textUtil's split(filename, ".")

			last item of filenameTokens
		end getFirstSelectionObjectType


		on getUserFolder()
			getHomeFolder()
		end getUserFolder


		on getHomeFolder()
			tell application "Finder"
				path to home folder
			end tell
		end getHomeFolder


		on getUserPath()
			getHomePath()
		end getUserPath


		on getHomePath()
			if isBusy() then return missing value

			tell application "Finder"
				text 1 thru -2 of textUtil's stringAfter(URL of my getHomeFolder() as text, "file://")
			end tell
		end getHomePath


		on getDesktopFolder()
			tell application "Finder"
				(path to desktop folder)
			end tell
		end getDesktopFolder


		on getDocumentsFolder()
			tell application "Finder"
				(path to documents folder)
			end tell
		end getDocumentsFolder


		on getUserLibraryFolder()
			if isBusy() then return missing value

			tell application "Finder"
				folder "Library" of my getUserFolder()
			end tell
		end getUserLibraryFolder

		on getUserScriptsFolder()
			if isBusy() then return missing value

			tell application "Finder"
				folder "Scripts" of my getUserLibraryFolder()
			end tell
		end getUserScriptsFolder

		on getApplicationsFolder()
			tell application "Finder"
				(path to applications folder)
			end tell
		end getApplicationsFolder

		on getUserApplicationsFolder()
			tell application "Finder"
				path to applications folder from user domain
			end tell
		end getUserApplicationsFolder

		on getTrashFolder()
			tell application "Finder"
				(path to trash folder)
			end tell
		end getTrashFolder


		(* @returns true when a folder is created. *)
		on createFolderAsNeeded(newFolderName, containerFolder)
			tell application "Finder"
				if exists (folder newFolderName of containerFolder) then return false

				logger's infof("Folder not found, creating: {}", newFolderName)
				make new folder at containerFolder with properties {name:newFolderName}
			end tell
			true
		end createFolderAsNeeded

		on posixToFolder(posixPath)
			if posixPath is missing value or posixPath is "" then return missing value

			if posixPath starts with "/Users/" & std's getUsername() then
				set userRelativePath to textUtil's stringAfter(posixPath, "/Users/" & std's getUsername() & "/")
				-- logger's debugf("userRelativePath: {}", userRelativePath)
				return _posixSubPathToFolder(userRelativePath, path to home folder)

			else if posixPath starts with "/" then
				set rootRelativePath to text 2 thru -1 of posixPath
				if rootRelativePath ends with "/" then set rootRelativePath to text 1 thru -2 of rootRelativePath
				return _posixSubPathToFolder(rootRelativePath, path to startup disk)

			else if posixPath starts with "~" then
				set userRelativePath to textUtil's stringAfter(posixPath, "~/")
				return _posixSubPathToFolder(userRelativePath, path to home folder)

			end if
		end posixToFolder


		on _posixSubPathToFolder(subpath, sourceFolder)
			set calcEndFolder to sourceFolder
			set pathTokens to textUtil's split(subpath, "/")
			tell application "Finder"
				repeat with nextToken in pathTokens
					try
						set calcEndFolder to folder nextToken of calcEndFolder
					on error -- when folder is aliased.
						set calcEndFolder to file nextToken of calcEndFolder
					end try
				end repeat
			end tell

			calcEndFolder
		end _posixSubPathToFolder
	end script

	set decorator to decoratorLib's new(result)
	decorator's decorate()
end new
