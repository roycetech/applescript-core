(*
	@Purpose:
		Trigger sort.

		NOTE: Haven't found programmatic way to change the sort direction.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Finder/26.0/dec-finder-view

	@Created: Tue, Sep 23, 2025, at 03:11:04 PM
	@Last Modified: 2025-09-25 08:14:12
	@Change Logs:
		Thu, Sep 25, 2025, at 08:13:35 AM - Switch back to sorting via Menu. Sort By is not available on some virtual views like 'Recent'
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
		NOOP:
		Manual: Set View Type
		Manual: Sort By Name
		Manual: Sort By Date
		Manual: Sort By Kind

		Dummy
		Dummy
		Dummy
		Dummy
		Dummy
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
	logger's infof("Sort By in Menu: {}", sut's _isMenuSortByPresent())
	logger's infof("View type: {}", sut's getFileObjectViewType())
	logger's infof("Sorting by: {}", sut's getSortBy()) -- Returns "Kind", works fine when isolated on a tab.

	if caseIndex is 1 then


	else if caseIndex is 2 then
		set sutViewType to "Unicorn"
		set sutViewType to "Icons"
		set sutViewType to "List"
		-- set sutViewType to "Gallery"
		-- set sutViewType to "Columns"
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
			if not _isMenuSortByPresent() then return missing value

			tell application "System Events" to tell process "Finder"
				-- return title of (first menu item of menu 1 of menu item "Sort By" of menu 1 of menu bar item "View" of menu bar 1 whose value of attribute "AXMenuItemMarkChar" is equal to unic's MENU_CHECK)

				return title of (first menu item of menu 1 of menu item "Sort By" of menu 1 of menu bar item "View" of menu bar 1 whose value of attribute "AXMenuItemMarkChar" is equal to unic's MENU_CHECK)
				-- title of result
			end tell



			missing value
		end getSortBy


		on sortByName()
			_sortByMenu("Name")
		end sortByName


		on sortByDate()
			_sortByMenu("Date Modified")
		end sortByDate

		on sortByKind()
			_sortByMenu("Kind")
		end sortByKind


		on _sortByMenu(menuTitle)
			if not _isMenuSortByPresent() then return false

			tell application "System Events" to tell process "Finder"
				try
					click (menu item menuTitle of menu 1 of menu item "Sort By" of menu 1 of menu bar item "View" of menu bar 1)
				end try
			end tell

		end _sortByMenu


		on _sortBy(menuTitle)
			tell application "System Events" to tell process "Finder"
				click menu button 2 of toolbar 1 of front window
				try
					click menu item menuTitle of menu 1 of menu item "Sort By" of menu 1 of menu button 2 of toolbar 1 of front window
				end try
			end tell
		end _sortBy




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

		on _isMenuSortByPresent()
			if running of application "Finder" is false then return false

			tell application "System Events" to tell process "Finder"
				exists (menu item "Sort By" of menu 1 of menu bar item "View" of menu bar 1)
			end tell
		end _isMenuSortByPresent
	end script
end decorate
