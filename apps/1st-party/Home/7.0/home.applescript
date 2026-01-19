(*
	Wrapper to the Home app.

	Could not reference the UI elements directly so I used a recursive handler to find the known hierarchy of the target element based on the UI description.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Home/7.0/home

	@Created: December 8, 2023 9:40 PM
	@Last Modified: 2026-01-18 11:50:37
*)
use scripting additions

use textUtil : script "core/string"
use listUtil : script "core/list"
use loggerFactory : script "core/logger-factory"
use systemEventLib : script "core/system-events"
use retryLib : script "core/retry"

use spotScript : script "core/spot-test"

property logger : missing value
property systemEvent : missing value
property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Switch Sidebar Item (Missing, Happy)
		Manual: Click Tile
		Manual: Hide Sidebar
		Manual: Show Sidebar
		Manual: Accessory Status

		Manual: Camera
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()

	tell application "System Events" to tell process "Home"
		-- sut's printUIElements(front window, "")
	end tell

	set sideBarVisible to sut's hasSidebar()
	logger's infof("Has Sidebar: {}", sideBarVisible)
	if sideBarVisible then
		logger's infof("Selected Sidebar Item: {}", sut's getSelectedSidebarItem())
	end if
	-- logger's infof("Status: {}", sut's getAccessoryStatus("Table"))
	logger's infof("Status: {}", sut's getAccessoryStatus("YLBulbColor1s"))


	if caseIndex is 1 then
		-- logger's infof("Switch result: {}", sut's switchSidbarItem("Unicorn"))
		-- logger's infof("Switch result: {}", sut's switchSidbarItem("Automation"))
		logger's infof("Switch result: {}", sut's switchSidebarItem("Lights"))
		-- log sut's findUIClass(missing value, "split group")
		tell application "System Events" to tell process "Home"
			-- sut's printUIElements(front window, "")
		end tell

	else if caseIndex is 2 then
		logger's infof("Click result: {}", sut's clickTile("YLBulbColor1s-3BAD"))

	else if caseIndex is 3 then
		sut's hideSidebar()

	else if caseIndex is 4 then
		sut's showSidebar()

	else if caseIndex is 5 then
		sut's showSidebar()
		sut's switchSidebarItem("Bedroom")
		logger's infof("Status: {}", sut's getAccessoryStatus("Table"))

	else if caseIndex is 6 then
		logger's infof("Click result: {}", sut's clickTile("Cameras"))
		delay 1
		logger's infof("Click result: {}", sut's clickTile("Camera-"))

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	set systemEvent to systemEventLib's new()
	set retry to retryLib's new()

	script HomeInstance
		(* @returns true on success. *)
		on switchSidebarItem(itemName)
			-- logger's debugf("itemName: {}", itemName)
			set sideBarItem to findUiElementWithDescription(missing value, itemName)
			if sideBarItem is missing value then return false
			-- log class of sideBarItem

			tell application "System Events"
				try
					click sideBarItem
					return true
				end try
			end tell

			false
		end switchSidebarItem


		on hasSidebar()
			findUiElementWithDescription(missing value, "Sidebar") is not missing value
		end hasSidebar


		on hideSidebar()
			set currentApp to systemEvent's getFrontAppName()
			tell application "System Events" to tell process "Home"
				set frontmost to true
				try
					click menu item "Hide Sidebar" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
			tell application "System Events" to tell process currentApp
				set frontmost to true
			end tell
		end hideSidebar

		on showSidebar()
			set currentApp to systemEvent's getFrontAppName()
			tell application "System Events" to tell process "Home"
				set frontmost to true
				try
					click menu item "Show Sidebar" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
			tell application "System Events" to tell process currentApp
				set frontmost to true
			end tell
		end showSidebar


		on getSelectedSidebarItem()
			tell application "System Events"
				try
					return description of my findSelectedStaticText(missing value)
				end try
			end tell
			missing value
		end getSelectedSidebarItem


		on findSelectedStaticText(targetGroup)
			if targetGroup is missing value then
				tell application "System Events" to tell process "Home"
					try
						set targetGroup to group 1 of front window
					end try
				end tell
			end if
			if targetGroup is missing value then return missing value

			set selectedUIElement to missing value
			try

				tell application "System Events" to tell process "Home"
					set selectedUIElement to the first UI element of targetGroup whose selected is true
				end tell
			end try
			if selectedUIElement is not missing value then
				tell application "System Events" to tell process "Home"
					return selectedUIElement
				end tell
			end if

			tell application "System Events" to tell process "Home"
				set subgroups to groups of targetGroup
			end tell

			repeat with nextGroup in subgroups
				set nextStaticText to findSelectedStaticText(nextGroup)
				if nextStaticText is not missing value then return nextStaticText
			end repeat

			missing value
		end findSelectedStaticText


		on clickTile(tileName)
			set accessoryTile to findButtonWithDescription(missing value, tileName)
			if accessoryTile is missing value then return false

			tell application "System Events"
				try
					click of accessoryTile
					return true
				end try
			end tell
			false
		end clickTile


		on openDetails(tileName)
			set accessoryTile to findButtonWithDescription(missing value, tileName)
			if accessoryTile is missing value then return false

			tell application "System Events"
				try
					perform last action of accessoryTile
					return true
				end try
			end tell
			false
		end openDetails


		(*
			There was an issue with a lost reference to the window when this handler in invoked immediately after switching side bar item, so a retry was used to mitigate.

			@returns the text after the comma in the desccription.
		*)
		on getAccessoryStatus(tileName)
			script RetryScript
				findButtonWithDescription(missing value, tileName)
			end script
			set accessoryTile to exec of retry on result for 3
			if accessoryTile is missing value then return missing value

			tell application "System Events" to tell process "Home"
				last item of textUtil's split(description of accessoryTile, ", ")
			end tell
		end getAccessoryStatus


		on findUiElementWithDescription(targetGroup, textDescription)
			if targetGroup is missing value then
				tell application "System Events" to tell process "Home"
					try
						set targetGroup to group 1 of front window
					end try
				end tell
			end if
			if targetGroup is missing value then return missing value

			set matchingUiElement to missing value
			try

				tell application "System Events" to tell process "Home"
					set matchingUiElement to the first UI element of targetGroup whose description is equal to textDescription
				end tell
			end try
			if matchingUiElement is not missing value then return matchingUiElement

			tell application "System Events" to tell process "Home"
				set subgroups to groups of targetGroup
			end tell

			repeat with nextGroup in subgroups
				set nextUiElement to findUiElementWithDescription(nextGroup, textDescription)
				if nextUiElement is not missing value then return nextUiElement
			end repeat

			missing value
		end findUiElementWithDescription


		on printUIElements(sourceElement, padding)
			if sourceElement is missing value then return

			tell application "System Events"
				repeat with nextElement in UI elements of sourceElement
					try
						log padding & class of nextElement & ": " & description of nextElement & ": " & role description of nextElement
					end try
					my printUIElements(nextElement, padding & "  ")
				end repeat
			end tell
		end printUIElements


		on findUIClass(targetGroup, uiClass)
			if targetGroup is missing value then
				tell application "System Events" to tell process "Home"
					set targetGroup to group 1 of front window
				end tell
			end if

			if targetGroup is missing value then return missing value
			set matchingUI to missing value
			try
				tell application "System Events" to tell process "Home"
					set matchingUI to the first UI element of targetGroup whose role description is equal to uiClass
				end tell
			end try
			if matchingUI is not missing value then return matchingUI

			tell application "System Events" to tell process "Home"
				set subgroups to groups of targetGroup
			end tell

			repeat with nextGroup in subgroups
				set nextUI to findUIClass(nextGroup, uiClass)
				if nextUI is not missing value then return nextUI
			end repeat

			missing value
		end findUIClass


		on findButtonWithDescription(targetGroup, buttonDescription)
			if targetGroup is missing value then
				tell application "System Events" to tell process "Home"
					set targetGroup to group 1 of front window
				end tell
			end if

			if targetGroup is missing value then return missing value
			set matchingButton to missing value
			try
				tell application "System Events" to tell process "Home"
					set matchingButton to the first button of targetGroup whose description starts with buttonDescription
				end tell
			end try
			if matchingButton is not missing value then return matchingButton

			tell application "System Events" to tell process "Home"
				set subgroups to groups of targetGroup
			end tell

			repeat with nextGroup in subgroups
				set nextButton to findButtonWithDescription(nextGroup, buttonDescription)
				if nextButton is not missing value then return nextButton
			end repeat

			missing value
		end findButtonWithDescription
	end script
end new
