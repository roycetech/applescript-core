(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Finder/15.2/dec-finder-view

	@Created: Sun, May 04, 2025 at 10:40:36 AM
	@Last Modified: 2025-05-04 14:34:13
	@Change Logs:
*)
use unic : script "core/unicodes"
use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Set View Type
		Manual: Sort By Name
		Manual: Sort By Date
		Manual: Sort By Kind
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

	activate application "Finder"
	logger's infof("View type: {}", sut's getFileObjectViewType())
	logger's infof("Sorting by: {}", sut's getSortBy())

	if caseIndex is 1 then


	else if caseIndex is 2 then
		set sutViewType to "Unicorn"
		set sutViewType to "Icons"
		set sutViewType to "List"
		set sutViewType to "Gallery"
		set sutViewType to "Columns"
		logger's debugf("sutViewType: {}", sutViewType)

		sut's setFileObjectViewType(sutViewType)

	else if caseIndex is 3 then
		sut's sortByName()

	else if caseIndex is 4 then
		sut's sortByDate()

	else if caseIndex is 5 then
		sut's sortByKind()

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script FinderViewDecorator
		property parent : mainScript

		on getSortBy()
			tell application "System Events" to tell process "Finder"
				return title of (first menu item of menu 1 of menu item "Sort By" of menu 1 of menu bar item "View" of menu bar 1 whose value of attribute "AXMenuItemMarkChar" is equal to unic's MENU_CHECK)
			end tell

			missing value
		end getSortBy


		on sortByName()
			tell application "System Events" to tell process "Finder"
				try
					click (menu item "Name" of menu 1 of menu item "Sort By" of menu 1 of menu bar item "View" of menu bar 1)
				end try
			end tell
		end sortByName


		on sortByDate()
			tell application "System Events" to tell process "Finder"
				try
					click (menu item "Date Modified" of menu 1 of menu item "Sort By" of menu 1 of menu bar item "View" of menu bar 1)
				end try
			end tell
		end sortByDate

		on sortByKind()
			tell application "System Events" to tell process "Finder"
				try
					click (menu item "Kind" of menu 1 of menu item "Sort By" of menu 1 of menu bar item "View" of menu bar 1)
				end try
			end tell
		end sortByDate

		(*
			@ viewType - List, Icons, Gallery, Columns
		*)
		on setFileObjectViewType(viewType)
			tell application "System Events" to tell process "Finder"
				try
					click (first menu item of menu 1 of menu bar item "View" of menu bar 1 whose title starts with "as " & viewType)
				end try
			end tell
		end setFileObjectViewType


		on getFileObjectViewType()
			tell application "System Events" to tell process "Finder"
				try
					title of (first menu item of menu 1 of menu bar item "View" of menu bar 1 whose value of attribute "AXMenuItemMarkChar" is equal to unic's MENU_CHECK)
					return last word of result
				end try
			end tell

			missing value
		end getFileObjectViewType
	end script
end decorate
