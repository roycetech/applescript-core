global std, config, textUtil, keyboard

(*
	For consistency:
		Posix directories should never end with "/", it's up to the client to append it along with the file.
		Posix Sub-directories must not start with "/", to make it obvious that it is not relative to root.
		
	WARNING: Finder is slow in general (not just this script). Avoid using the app Finder as much as possible.
	
	@Prerequisites:
		keyboard.applescript - some handlers require keypresses.

	@Install:
		make install-finder
*)

use script "Core Text Utilities"
use scripting additions

property initialized : false
property logger : missing value


if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "finder-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	(* Have a Finder window open and manually verify result. *)
	set cases to listUtil's splitByLine("
		Misc Folders
		Manual: Selection (None, One, Multi)
		Manual: Current POSIX PATH
		Manual: Folder Name
		Manual: Create From Template
		
		Get File Path
		Get File List		
		Move File - (Manually Revert)
		New Tab for Path
		Find Tab: Projects
		
		Manual: Add to SideBar (Manual: Needs/Does not need adding) 
		Manual: Posix to Folder (View in Replies: User Path, Non-User Path)
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	if caseIndex is 1 then
		logger's infof("User Folder: {}", sut's getUserFolder()) -- aka Home Folder
		logger's infof("User Path: {}", sut's getUserPath())
		logger's infof("User Library Folder: {}", sut's getUserLibraryFolder())
		logger's infof("User Scripts Folder: {}", sut's getUserScriptsFolder())
		logger's infof("Applications Folder: {}", sut's getApplicationsFolder())
		logger's infof("Trash Folder: {}", sut's getTrashFolder())
		
	else if caseIndex is 2 then
		logger's infof("Selected Objects: {}", sut's getSelection())
		logger's infof("Selected File Path: {}", sut's getFirstSelectionPath())
		logger's infof("Selected Filename: {}", sut's getFirstSelectionName())
		
	else if caseIndex is 3 then
		set frontTab to sut's getFrontTab()
		logger's infof("Get Path: {}", frontTab's getPath())
		
	else if caseIndex is 2 then
		set frontTab to sut's getFrontTab()
		logger's infof("Folder Name: {}", frontTab's getFolderName())
		
	else if caseIndex is 3 then -- WIP From here to cases below.
		tell application "Finder"
			set targetFolder to folder "Delete Daily" of my getDesktopFolder()
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
			set destFolder to folder "Delete Daily" of (path to desktop folder)
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
		
	else if caseIndex is 12 then
		log sut's posixToFolder("/Users/" & std's getUsername() & "/applescript-core/logs")
		log sut's posixToFolder("/Applications")
	end if
	
	spot's finish()
	logger's finish()
	
	
	return
	
	openPath(":Macintosh HD:Users:")
	set theUserName to short user name of (system info)
	openPosixPath("/Users/" & theUserName)
	
end spotCheck

on new()
	script FinderInstance
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
			
			if posixPath is "~" then
				set posixPath to format {"/Users/{}/", std's getUsername()}
			else if posixPath starts with "~" then
				set posixPath to format {"/Users/{}/{}", {std's getUsername(), text 3 thru -1 of posixPath}}
			end if
			logger's debugf("posixPath: {}", posixPath)
			
			set posixFileTarget to POSIX file posixPath
			
			tell application "Finder"
				activate
				set finderWindow to make new Finder window
				try
					set target of finderWindow to posixFileTarget
				end try
				my _newInstance(id of front window)
			end tell
		end newTab
		
		
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
		
		
		on createFile(sourceFile, targetFolder, newFileName)
			tell application "Finder"
				if exists file newFileName of targetFolder then error "File already exists"
				
				duplicate sourceFile to targetFolder
				
				(* Not very robust, not expecting lots of duped files with same name. *)
				if container of sourceFile is targetFolder then
					set nameTokens to textUtil's split(name of sourceFile, ".")
					set newFile to file (first item of nameTokens & " 2." & last item of nameTokens) of targetFolder
				else
					set newFile to file (name of sourceFile) of targetFolder
				end if
				
				set name of newFile to newFileName
			end tell
			newFile
		end createFile
		
		
		on moveFile(sourceFile, destFolder)
			tell application "Finder"
				move sourceFile to destFolder
			end tell
		end moveFile
		
		
		on _new(windowId)
			script FinderInstance
				property appWindow : missing value -- not syseve window.
				
				(* @returns true if successful in adding. *)
				on addToSideBar()
					tell application "System Events" to tell process "Finder"
						set inSideBar to false
						repeat with nextRow in rows of outline 1 of scroll area 1 of splitter group 1 of window (name of appWindow)
							if value of static text 1 of UI element 1 of nextRow is equal to the name of appWindow then
								set inSideBar to true
								exit repeat
							end if
						end repeat
					end tell
					logger's debugf("inSideBar: {}", inSideBar)
					
					if not inSideBar then
						activate application "Finder"
						delay 0.1
						
						kb's pressCommandControl("t")
						return true
					end if
					
					false
				end addToSideBar
				
				on getPath()
					if running of application "Finder" is false then return missing value
					tell application "System Events" to tell process "Finder"
						if (count of windows) is 0 then return missing value
					end tell
					
					focus()
					tell application "Finder"
						set currentFolder to insertion location
						try
							return textUtil's decodeUrl(textUtil's stringAfter(URL of currentFolder, "file://"))
						end try -- Ignore special locations like Recents.
					end tell
					missing value
				end getPath
				
				to getFolderName()
					tell application "Finder"
						set currentFolder to insertion location
					end tell
					name of currentFolder -- would not work if we do 'name of insert location' inside the tell Finder block.
				end getFolderName
				
				to focus()
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
			set userSelection to getSelection()
			if (the number of items in userSelection) is 0 then return missing value
			
			set firstSelection to first item of userSelection
			tell application "Finder"
				textUtil's stringAfter(URL of firstSelection, "file://")
			end tell
		end getFirstSelectionPath
		
		
		on getFirstSelectionName()
			set userSelection to getSelection()
			if (the number of items in userSelection) is 0 then return missing value
			
			set firstSelection to first item of userSelection
			name of firstSelection
		end getFirstSelectionName
		
		
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
			tell application "Finder"
				text 1 thru -2 of textUtil's stringAfter(URL of my getHomeFolder() as text, "file://")
			end tell
		end getHomePath
		
		
		on getDesktopFolder()
			tell application "Finder"
				(path to desktop folder)
			end tell
		end getDesktopFolder
		
		
		on getUserLibraryFolder()
			tell application "Finder"
				folder "Library" of my getUserFolder()
			end tell
		end getUserLibraryFolder
		
		on getUserScriptsFolder()
			tell application "Finder"
				folder "Scripts" of my getUserLibraryFolder()
			end tell
		end getUserScriptsFolder
		
		on getApplicationsFolder()
			tell application "Finder"
				(path to applications folder)
			end tell
		end getApplicationsFolder
		
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
				return _posixSubPathToFolder(rootRelativePath, path to startup disk)
				
			end if			
		end posixToFolder
		
		
		on _posixSubPathToFolder(subpath, sourceFolder)
			set calcEndFolder to sourceFolder
			set pathTokens to textUtil's split(subpath, "/")
			tell application "Finder"
				repeat with nextToken in pathTokens
					set calcEndFolder to folder nextToken of calcEndFolder
				end repeat
			end tell
			
			calcEndFolder
		end _posixSubPathToFolder
	end script
	std's applyMappedOverride(result)
end new




-- Private Codes below =======================================================


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("finder")
	set textUtil to std's import("string")
	set kb to std's import("keyboard")'s new()
end init
