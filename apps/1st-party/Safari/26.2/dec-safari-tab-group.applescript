(*
	@Purpose:
		The original safari script is quite big and we want to improve its manageability by breaking it down into smaller pieces.
		This decorator will contain the handlers relating to tab groups.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/26.2/dec-safari-tab-group

	@Created: Monday, June 10, 2024 at 11:42:13 AM
	@Last Modified: 2026-01-20 15:01:38

	@Change Logs:
		Tue, Dec 23, 2025, at 11:14:51 AM - Migrated to 26.2
			Removed the group 1 from tool bar 1 in the UI hierarchy.
		Mon, Aug 18, 2025 at 02:27:33 PM - Migrated to 18.6.
		Monday, June 10, 2024 at 11:47:12 AM - cliclick no longer required.
*)
use textUtil : script "core/string"
use unic : script "core/unicodes"

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"
use kbLib : script "core/keyboard"

property logger : missing value

property kb : missing value
property retry : missing value

property DEFAULT_GROUP_NAME : "<default>"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		INFO: NOOP
		Manual: Switch to applescript-core
		Manual: Switch to Default
		Manual: Move current tab to a group
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
	set sutLib to script "core/safari"
	set sut to sutLib's new()
	set sut to decorate(sut)

	logger's infof("Integration: Sidebar visible: {}", sut's isSidebarVisible())
	logger's infof("Is Default Group: {}", sut's isDefaultGroup())
	logger's infof("Group name before: {}", sut's getGroupName())
	-- logger's debugf("Tab groups divider index: {}", sut's _getTabGroupsDividerIndex())
	-- logger's debugf("Sidebar selected tab group index: {}", sut's _getSelectedTabGroupIndex())

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's switchGroup("applescript-core")
		delay 1 -- Allow the group change to propagate before reading it again.

	else if caseIndex is 3 then
		sut's switchGroup(missing value)

	else if caseIndex is 4 then
		set sutGroupName to "Unicorn"
		set sutGroupName to "Shopping"
		logger's debugf("sutGroupName: {}", sutGroupName)

		sut's moveCurrentTabToGroup(sutGroupName)
	else

	end if

	logger's infof("Group name after: {}", sut's getGroupName())

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	set retry to retryLib's new()
	set kb to kbLib's new()

	script SafariTabGroupDecorator
		property parent : mainScript

		on moveCurrentTabToGroup(destinationGroupName)
			set mainWindow to getFirstZoomableWindow()
			if mainWindow is missing value then return
			tell application "System Events" to tell process "Safari"
				set frontmost to true
				try
					set tabGroupUI to first UI element of front window whose role description is "tab group"
					set currentTab to first radio button of tabGroupUI whose value is true
					perform action "AXShowMenu" of currentTab
					-- delay 0.5
					delay 1
					click menu item destinationGroupName of menu 1 of menu item "Move to Tab Group" of menu 1 of currentTab
				end try
			end tell

		end moveCurrentTabToGroup


		(*
			Determine if on default group when:
				Sidebar Visible: first row is selected.
				Sidebar Hidden: the tab picker is small, without any labels

		*)
		on isDefaultGroup()
			set sideBarPresent to isSidebarVisible()
			logger's debugf("sideBarPresent: {}", sideBarPresent)

			if sideBarPresent then
				(*
				tell application "System Events" to tell process "Safari"
					-- return value of attribute "AXSelected" of row 1 of outline 1 of scroll area 1 of group 1 of splitter group 1 of front window
					return value of attribute "AXSelected" of row 1 of my _getSidebarUIOutline()

				end tell
				*)

				return _getSelectedTabGroupIndex() is less than _getTabGroupsDividerIndex()
			end if

			-- else: Sidebar not visible.
			script GroupPickerWaiter
				tell application "System Events" to tell process "Safari"
					-- first menu button of group 1 of toolbar 1 of front window whose help is "Tab Group Picker"
					-- first menu button of toolbar 1 of front window -- macOS 26.2
				end tell
				_getTabGroupPickerUI()
			end script
			set groupPicker to exec of retry on result for 40 by 0.2 -- 2 seconds max.
			if groupPicker is missing value then error "Unable to find the group picker UI"

			(*
			-- Old implementation, checks the size of the UI
			tell application "System Events" to tell process "Safari"
				set wh to the size of groupPicker
				(first item of wh) is less than 40
			end tell
			*)


			tell application "System Events" to tell process "Safari"
				-- set tabGroupId to get value of attribute "AXIdentifier" of menu button 1 of group 1 of toolbar 1 of front window
				set tabGroupId to get value of attribute "AXIdentifier" of my _getTabGroupPickerUI()
			end tell
			tabGroupId does not contain "TabGroup="
		end isDefaultGroup


		on getGroupName()
			set mainWindow to getFirstZoomableWindow()
			if mainWindow is missing value then return missing value

			tell application "System Events" to tell process "Safari"
				set windowTitle to name of mainWindow
			end tell

			if isDefaultGroup() then return DEFAULT_GROUP_NAME

			set sideBarWasVisible to isSidebarVisible()
			-- logger's debugf("sideBarWasVisible: {}", sideBarWasVisible)

			if sideBarWasVisible is false then -- let's try to simplify by getting the name from the window name
				set nameTokens to textUtil's split(windowTitle, unic's SEPARATOR)
				if number of items in nameTokens is 2 then -- There's a small risk that a current website has the same separator characters in its title and thus result in the wrong group name.
					logger's info("Returning group name from window title")
					return first item of nameTokens
				end if
			end if

			showSidebar()


			-- UI detects side bar is still hidden, so we wait, to make close work reliably.
			script SidebarWaiter
				if isSidebarVisible() is true then return true
			end script
			exec of retry on SidebarWaiter for 5

			tell application "System Events" to tell process "Safari"
				-- repeat with nextRow in rows of outline 1 of scroll area 1 of group 1 of splitter group 1 of front window
				repeat with nextRow in rows of my _getSidebarUIOutline()
					if selected of nextRow is true then
						if not sideBarWasVisible then
							-- logger's debug("Closing Sidebar...")
							my closeSidebar()
						end if

						set groupDesc to description of UI element 1 of UI element 1 of nextRow
						set groupNameTokens to textUtil's split(groupDesc, ",")
						return first item of groupNameTokens
					end if
				end repeat
			end tell

			if not sideBarWasVisible then
				closeSidebar()
			end if
			missing value
		end getGroupName


		on switchToDefaultGroup()
			switchGroup(missing value)
		end switchToDefaultGroup


		(*
			Will switch group by:
				1.  Closing the Sidebar
				2.  Triggering the group switcher menu UI
				3.  Clicking the first (missing value) or the matching menu item.
				4.  Restore if Sidebar wasn't initially closed.

			@requires app focus.
			@groupName - The group name to switch to. Missing value for default.
		*)
		on switchGroup(groupName)
			logger's debugf("switchGroup({})", groupName)

			if running of application "Safari" is false then
				logger's debug("Launching Safari...")
				activate application "Safari"
				delay 0.1
			end if

			tell application "System Events" to tell process "Safari"
				if (count of windows) is 0 then
					my newWindow(missing value)
				end if
			end tell

			set sideBarWasVisible to isSidebarVisible()
			closeSidebar()

			script ToolBarWaiter
				tell application "System Events" to tell process "Safari"
					set frontmost to true

					click my _getTabGroupPickerUI()
				end tell
				true
			end script
			set waitResult to exec of retry on result for 3
			logger's debugf("ToolBarWaiter WaitResult: {}", waitResult)

			tell application "System Events" to tell process "Safari"
				if groupName is missing value then
					-- The default group is the 3rd item.
					-- click menu item 3 of menu 1 of group 1 of toolbar 1 of front window
					click menu item 3 of my _getTabGroupMenuUI()

				else
					try
						-- click menu item groupName of menu 1 of group 1 of toolbar 1 of window 1
						click menu item groupName of my _getTabGroupMenuUI() -- macOS 26.2
					on error the errorMessage number the errorNumber
						log errorMessage
						logger's warnf("Group: {} was not found", groupName)
						kb's pressKey("esc")
					end try
				end if
			end tell

			if sideBarWasVisible then showSidebar()
		end switchGroup


		on _getSelectedTabGroupIndex()
			if running of application "Safari" is false then return 0
			if not isSidebarVisible() then return 0
			set mainWindow to getFirstZoomableWindow()
			if mainWindow is missing value then return 0

			tell application "System Events" to tell process "Safari"
				first row of outline 1 of scroll area 1 of splitter group 1 of mainWindow whose selected is true
				(value of attribute "AXIndex" of result) + 1
			end tell
		end _getSelectedTabGroupIndex


		on _getTabGroupsDividerIndex()
			set mainWindow to getFirstZoomableWindow()
			if mainWindow is missing value then return 0
			if not isSidebarVisible() then return 0

			tell application "System Events" to tell process "Safari"
				first row of outline 1 of scroll area 1 of splitter group 1 of front window whose value of static text 1 of UI element 1 ends with "Tab Groups"
				(value of attribute "AXIndex" of result) + 1
			end tell
		end _getTabGroupsDividerIndex


		on _getSidebarUIOutline()
			set mainWindow to getFirstZoomableWindow()
			if mainWindow is missing value then return missing value

			tell application "System Events" to tell process "Safari"
				-- outline 1 of scroll area 1 of group 1 of splitter group 1 of front window
				outline 1 of scroll area 1 of splitter group 1 of mainWindow
			end tell
		end _getSidebarUIOutline


		(*
			This changes a lot for each macOS version update.
		*)
		on _getTabGroupPickerUI()
			set mainWindow to getFirstZoomableWindow()
			if mainWindow is missing value then return missing value

			tell application "System Events" to tell process "Safari"
				menu button 1 of toolbar 1 of mainWindow
			end tell
		end _getTabGroupPickerUI

		on _getTabGroupMenuUI()
			set mainWindow to getFirstZoomableWindow()
			if mainWindow is missing value then return missing value

			tell application "System Events" to tell process "Safari"
				menu 1 of menu button 1 of menu button 1 of toolbar 1 of mainWindow
			end tell
		end _getTabGroupMenuUI
	end script
end decorate
