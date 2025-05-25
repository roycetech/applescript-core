(*
	NOTE: Folder reference has a class of "alias" when logged.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Finder/15.2/dec-finder-folders

	@Created: Tuesday, December 31, 2024 at 6:15:12 PM
	@Last Modified: 2025-01-02 09:10:50
	@Change Logs:
*)
use scripting additions
use std : script "core/std"
use textUtil : script "core/string"
use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		INFO
		Manual: POSIX to Folder
		Manual: Create Folder as Needed
	")
	
	set spotScript to script "core/spot-test"
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
	
	-- log class of sut's getDocumentsFolder()  -- Result: alias
	
	logger's infof("User Folder: {}", sut's getUserFolder()) -- aka Home Folder
	logger's infof("Desktop Folder: {}", sut's getDesktopFolder())
	logger's infof("Documents Folder: {}", sut's getDocumentsFolder())
	logger's infof("User Library Folder: {}", sut's getUserLibraryFolder())
	logger's infof("User Scripts Folder: {}", sut's getUserScriptsFolder())
	logger's infof("User Applications Folder: {}", sut's getUserApplicationsFolder())
	logger's infof("Applications Folder: {}", sut's getApplicationsFolder())
	logger's infof("Trash Folder: {}", sut's getTrashFolder())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		logger's infof("Handler result: {}", sut's posixToFolder("~/docker"))
		
	else if caseIndex is 3 then
		set tmpPath to "/tmp"
		set tempFolder to sut's posixToFolder(tmpPath)
		sut's createFolderAsNeeded("Spot Created", tempFolder)
		
		tell application "Finder"
			sut's openPath("Macintosh HD:private:tmp:") -- To manually inspect
		end tell
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script FinderFoldersDecorator
		property parent : mainScript
		property homeFolderCache : home folder
		
		on getUserFolder()
			getHomeFolder()
		end getUserFolder
		
		
		on getHomeFolder()
			tell application "Finder"
				-- path to home folder
			end tell
			
			return path to my homeFolderCache
		end getHomeFolder
		
		
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
			-- Specialized paths
			if posixPath is "/tmp" then return alias "Macintosh HD:tmp:"
			
			if posixPath starts with "/Users/" & std's getUsername() then
				set userRelativePath to textUtil's stringAfter(posixPath, "/Users/" & std's getUsername() & "/")
				-- logger's debugf("userRelativePath: {}", userRelativePath)
				-- return _posixSubPathToFolder(userRelativePath, path to home folder)
				return _posixSubPathToFolder(userRelativePath, my getHomeFolder())
				
			else if posixPath starts with "/" then
				set rootRelativePath to text 2 thru -1 of posixPath
				if rootRelativePath ends with "/" then set rootRelativePath to text 1 thru -2 of rootRelativePath
				return _posixSubPathToFolder(rootRelativePath, path to startup disk)
				
			else if posixPath starts with "~" then
				set userRelativePath to textUtil's stringAfter(posixPath, "~/")
				-- return _posixSubPathToFolder(userRelativePath, path to home folder)
				return _posixSubPathToFolder(userRelativePath, my getHomeFolder())
				
			end if
		end posixToFolder
		
		
		on _posixSubPathToFolder(subpath, sourceFolder)
			set calcEndFolder to sourceFolder
			set pathTokens to textUtil's split(subpath, "/")
			tell application "Finder"
				repeat with nextToken in pathTokens
					try
						set calcEndFolder to folder nextToken of calcEndFolder
					on error the errorMessage number the errorNumber
						-- log errorMessage
						-- 					on error -- when folder is aliased.
						set calcEndFolder to file nextToken of calcEndFolder
					end try 
				end repeat
			end tell
			
			calcEndFolder
		end _posixSubPathToFolder
	end script
end decorate
