(*
	Refactored out of finder.applescript

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Finder/15.2/finder-tab

	@Created: Tuesday, December 31, 2024 at 6:01:47 PM
	@Last Modified: 2025-01-03 08:18:20
*)
use scripting additions

use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use decFinderSelection : script "core/dec-finder-selection"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set spotScript to script "core/spot-test"
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		INFO
		Manual: Focus
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	tell application "Finder"
		activate
		set sut to my new(id of window 1)
	end tell

	logger's infof("URL: {}", sut's getURL())
	logger's infof("Get Path: {}", sut's getPath())
	logger's infof("Folder Name: {}", sut's getFolderName())
	logger's infof("Decorator: Selection: First Selected File Path: {}", sut's getFirstSelectionPath())

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's focus()

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new(windowId)
	loggerFactory's inject(me)

	script FinderTabInstance
		property appWindow : missing value -- not syseve window.

		(*
			@Deprecated. Use the finder.applescript#meneAddToSideBar instead.
			@returns true if successful in adding.
		*)
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

	set thisFinderTabInstance to decFinderSelection's decorate(result)

	tell application "Finder" to set appWindow of thisFinderTabInstance to window id windowId
	thisFinderTabInstance
end new
