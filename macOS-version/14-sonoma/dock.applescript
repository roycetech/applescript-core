(*
	For the Assign to Desktop menu item to appear, there has to be more than one
	Desktop "Spaces" available.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh macOS-version/14-sonoma/dock

	@Change Logs:
		Wednesday, May 8, 2024 at 12:45:19 PM - Allow trigger of a single nest menu.

	TODO: Re-code the spotcheck to have idempotent info only as the first case.
*)

use loggerFactory : script "core/logger-factory"
use retryLib : script "core/retry"
use kbLib : script "core/keyboard"

property logger : missing value
property retry : missing value
property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set spotScript to script "core/spot-test"
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Assign to Desktop 1
		Assign to Desktop 2
		Assign to All
		Assign to None
		Manual: Trigger Menu: (Basic, Nested)

		Position
		Vertical?
		Horizontal?
		Occupied Dock Width
		Occupied Dock Height

		Coordinates
		AutoHide
		Manual: Click App
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set lib to new()
	set appName to "Script Editor"
	if running of application appName is false then
		activate application appName
		delay 1
	end if

	if caseIndex is 1 then
		set assignResult to lib's assignToDesktop(appName, 1)

	else if caseIndex is 2 then
		set assignResult to lib's assignToDesktop(appName, 2)

	else if caseIndex is 3 then
		set assignResult to lib's assignToDesktop(appName, "all")

	else if caseIndex is 4 then
		set assignResult to lib's assignToDesktop(appName, "none")

	else if caseIndex is 5 then
		lib's triggerAppMenu("Safari", "New Private Window")
		-- lib's triggerAppMenu("Safari", {"New Window", "New Personal Window"})

	else if caseIndex is 6 then
		logger's infof("Dock Position: {}", lib's getPosition())

	else if caseIndex is 7 then
		logger's infof("Is Vertical: {}", lib's isVertical())

	else if caseIndex is 8 then
		logger's infof("Is Horizontal: {}", lib's isHorizontal())

	else if caseIndex is 9 then
		logger's infof("Dock Width: {}", lib's getWidth())

	else if caseIndex is 11 then
		logger's infof("Coordinates: {}, {}", lib's getCoordinates())

	else if caseIndex is 12 then
		logger's infof("Is Autohide?: {}", lib's isAutoHide())

	else if caseIndex is 13 then

		lib's clickApp("Safari")

	else if caseIndex is 10 then
		logger's infof("Dock Height: {}", lib's getHeight())

	end if

	if caseIndex is less than 5 then
		logger's debugf("assignResult: {}", assignResult)
	end if

	if caseIndex is less than 5 and running of application appName and assignResult is true then
		delay 1.5
		-- Visually verify
		-- tell application "System Events" to key code 53
		tell application "System Events" to tell process "Dock"
			perform action "AXShowMenu" of UI element appName of list 1
			click menu item "Options" of first menu of UI element appName of list 1
		end tell
	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)

	set retry to retryLib's new()
	set kb to kbLib's new()

	script DockInstance
		property waitSeconds : 1
		property waitMax : 3

		(* Will not work if the app doesn't even appear in the dock. *)
		on clickApp(appName)
			tell application "System Events" to tell process "Dock"
				try
					repeat 2 times -- does not work if clicked for one time only.
						click UI element appName of list 1
					end repeat
				end try
			end tell
		end clickApp

		(*
			@returns bottom, left, or right
		*)
		on getPosition()
			tell application "System Events" to tell dock preferences
				screen edge
			end tell
		end getPosition

		on isVertical()
			not isHorizontal()
		end isVertical

		on isHorizontal()
			tell application "System Events" to tell dock preferences
				my getPosition() is bottom
			end tell
		end isHorizontal

		on getWidth()
			if isHorizontal() or isAutoHide() then return 0

			tell application "System Events" to tell application process "Dock"
				set theSize to size of first list
			end tell
			first item of theSize
		end getWidth

		on getHeight()
			tell application "System Events" to tell application process "Dock"
				set theSize to size of first list
			end tell
			second item of theSize
		end getHeight

		on getCoordinates()
			tell application "System Events" to tell application process "Dock"
				position of first list
			end tell
		end getCoordinates


		on isAutoHide()
			tell application "System Events" to tell dock preferences
				autohide
			end tell
		end isAutoHide


		on setAutoHide(newState)
			tell application "System Events" to tell dock preferences
				set autohide to newState
			end tell
		end setAutoHide


		(*
			NOTE: Up to single nesting only.

			@appName - Application name in the dock.
			@menuItemKey - the exact menu item name, index, or the list of either.
		*)
		on triggerAppMenu(appName, menuItemKey)
			if class of menuItemKey is not list then
				set menuItemNames to {menuItemKey}
			else
				set menuItemNames to menuItemKey
			end if
			if the number of items in menuItemNames is greater than 2 then
				logger's warn("Deeply nested menu items are not yet supported. ")
				return
			end if

			tell application "System Events" to tell process "Dock"
				if not (exists UI element appName of list 1) then return false

				perform action "AXShowMenu" of UI element appName of list 1 -- This is required.
			end tell

			tell application "System Events" to tell process "Dock"
				set dockAppMenu to menu 1 of UI element appName of list 1
			end tell

			set isNestedMenu to the number of items in menuItemNames is 2
			set menuItemMain to item 1 of menuItemNames

			-- Verify if the menu keys provided are valid.
			tell application "System Events" to tell process "Dock"
				if isNestedMenu then
					set menuItemSub to item 2 of menuItemNames
					if not (exists (menu item menuItemSub of menu 1 of menu item menuItemMain of dockAppMenu)) then
						logger's fatalf("Menu key {} was not found.", menuItemNames as text)
						return false
					end if
				else
					if not (exists (menu item menuItemMain of dockAppMenu)) then
						logger's fatalf("Menu key {} was not found.", menuItemNames)
						return false
					end if

				end if
			end tell

			set retry to retryLib's new()
			script MenuWaiter
				tell application "System Events" to tell process "Dock"
					if isNestedMenu then
						click menu item menuItemSub of menu 1 of menu item menuItemMain of dockAppMenu

					else
						click menu item menuItemMain of dockAppMenu
					end if
					true
				end tell
			end script
			set clickResult to exec of retry on result for waitMax by waitSeconds
			if clickResult is missing value then kb's pressKey("escape")
		end triggerAppMenu


		(* @deprecated. No longer available as of December 10, 2022
		@returns false if app is not found in the dock or the menu item is unavailable due to absence of external monitor. *)
		on assignToDesktop(appName, desktopIndex)
			if class of desktopIndex is integer then
				set subMenuName to "Desktop on Display " & desktopIndex

			else if desktopIndex is "all" then
				set subMenuName to "All Desktops"

			else if desktopIndex is "none" then
				set subMenuName to "None"

			end if

			tell application "System Events" to tell process "Dock"
				if not (exists UI element appName of list 1) then return false

				perform action "AXShowMenu" of UI element appName of list 1
				delay 0.2 -- Intermittently fails without this.
				click menu item "Options" of first menu of UI element appName of list 1
				delay 0.1
				try
					click menu item subMenuName of menu 1 of menu item "Options" of first menu of UI element appName of list 1
				on error
					kb's pressKey("esc")
					return false
				end try
			end tell
			true
		end assignToDesktop
	end script
end new
