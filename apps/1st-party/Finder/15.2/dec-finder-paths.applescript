(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Finder/15.2/dec-finder-paths

	@Created: Tuesday, December 31, 2024 at 6:17:40 PM
	@Last Modified: 2025-12-02 09:24:24
	@Change Logs:
*)
use scripting additions

use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use processLib : script "core/process"

property logger : missing value

property SPOT_FILENAME : "wordlist.txt" -- Pre-existing test file used for spot checking only.

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Get File Path
		Manual: Open POSIX Path
		Manual: Open MON Path
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

	logger's infof("User Path: {}", sut's getUserPath())
	if caseIndex is 1 then

	else if caseIndex is 2 then
		tell application "Finder"
			set sutFile to file SPOT_FILENAME of (path to home folder)
		end tell
		logger's infof("File path: {}", sut's getFilePath(sutFile))

	else if caseIndex is 3 then
		set sutPosix to "~/" & SPOT_FILENAME
		sut's openPosixPath(sutPosix)

	else if caseIndex is 4 then
		set sutMonPath to "Macintosh HD:private:tmp:"
		sut's openPath(sutMonPath)

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script FinderPathsDecorator
		property parent : mainScript


		on getFilePath(fileObject)
			tell application "Finder"
				set fileUrl to URL of fileObject
			end tell
			set fileLess to textUtil's stringAfter(fileUrl, "file://")
			textUtil's replace(fileLess, "%20", " ")
		end getFilePath


		(* @param posixPath the string path e.g. /Users/you.name *)
		on openPosixPath(posixPath)
			(*
			set finderProcess to processLib's new("Finder")
			finderProcess's waitActivate()
			*)

			tell application "Finder"
				activate -- No need to wait, it will work just fine.
				set finderWindow to make new Finder window
				set target of finderWindow to POSIX file (my untilde(posixPath))
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


		on getUserPath()
			getHomePath()
		end getUserPath


		on getHomePath()
			if isBusy() then return missing value

			tell application "Finder"
				text 1 thru -2 of textUtil's stringAfter(URL of my getHomeFolder() as text, "file://")
			end tell
		end getHomePath
	end script
end decorate
