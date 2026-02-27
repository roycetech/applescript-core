(*
	@Project:
		applescript-core

	NOTES:
		Cursor prefers "Side Bar" over Sidebar.

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Cursor/2.5/cursor

	@Created: Wed, Feb 25, 2026 at 12:27:36 PM
	@Last Modified: 2026-02-26 16:56:13
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
		NOOP
		Manual: Show secondary side bar
		Manual: Hide secondary side bar
		Manual: Show minimap
		Manual: Hide minimap

		Manual: Single file layout
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

	set sut to new()
	logger's infof("Secondary side bar visible: {}", sut's isSecondarySideBarVisible())
	logger's infof("Is minimap visible: {}", sut's isMinimapVisible())

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's showSecondarySideBar()

	else if caseIndex is 3 then
		sut's hideSecondarySideBar()

	else if caseIndex is 4 then
		sut's showMinimap()

	else if caseIndex is 5 then
		sut's hideMinimap()

	else if caseIndex is 6 then
		sut's singleFileLayout()

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	set decCursorLayout to script "core/dec-cursor-layout"
	set decCursorCurrentFile to script "core/dec-cursor-current-file"

	script CursorInstance
		on isMinimapVisible()
			if running of application "Cursor" is false then return false

			tell application "System Events" to tell process "Cursor"
				try
					menu item "Minimap" of menu 1 of menu item "Appearance" of menu 1 of menu bar item "View" of menu bar 1
					return value of attribute "AXMenuItemMarkChar" of result is equal to unic's MENU_CHECK

				end try
			end tell

			false
		end isMinimapVisible


		(*  *)
		on showMinimap()
			if running of application "Cursor" is false then return
			if isMinimapVisible() then return

			tell application "System Events" to tell process "Cursor"
				set frontmost to true -- Requires focus

				try
					click menu item "Minimap" of menu 1 of menu item "Appearance" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
		end showMinimap


		(*  *)
		on hideMinimap()
			if running of application "Cursor" is false then return
			if isMinimapVisible() is false then return

			tell application "System Events" to tell process "Cursor"
				set frontmost to true -- Requires focus
				try
					click menu item "Minimap" of menu 1 of menu item "Appearance" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
		end hideMinimap


		on showSecondarySideBar()
			if running of application "Cursor" is false then return
			if isSecondarySideBarVisible() then return

			tell application "System Events" to tell process "Cursor"
				set frontmost to true -- Requires focus

				try
					click menu item "Secondary Side Bar" of menu 1 of menu item "Appearance" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
		end showSecondarySideBar


		on hideSecondarySideBar()
			if running of application "Cursor" is false then return
			if isSecondarySideBarVisible() is false then return

			tell application "System Events" to tell process "Cursor"
				set frontmost to true -- Requires focus
				try
					click menu item "Secondary Side Bar" of menu 1 of menu item "Appearance" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
		end hideSecondarySideBar


		on isSecondarySideBarVisible()
			if running of application "Cursor" is false then return false

			tell application "System Events" to tell process "Cursor"
				try
					menu item "Secondary Side Bar" of menu 1 of menu item "Appearance" of menu 1 of menu bar item "View" of menu bar 1
					return value of attribute "AXMenuItemMarkChar" of result is equal to unic's MENU_CHECK

				end try
			end tell

			false
		end isSecondarySideBarVisible
	end script
	decCursorLayout's decorate(result)
	decCursorCurrentFile's decorate(result)
end new
