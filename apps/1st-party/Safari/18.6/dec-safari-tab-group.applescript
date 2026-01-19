(*
	@Purpose:
		The original safari script is quite big and we want to improve its manageability by breaking it down into smaller pieces.
		This decorator will contain the handlers relating to tab groups.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/18.6/dec-safari-tab-group

	@Created: Monday, June 10, 2024 at 11:42:13 AM
	@Last Modified: 2026-01-18 11:54:18

	@Change Logs:
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

	logger's infof("Group name before: {}", sut's getGroupName())
	logger's infof("Is Default Group: {}", sut's isDefaultGroup())

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's switchGroup("applescript-core")
		delay 1 -- Allow the group change to propagate before reading it again.

	else if caseIndex is 3 then
		sut's switchGroup(missing value)

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

		on getGroupName()
			if running of application "Safari" is false then return missing value

			tell application "System Events" to tell process "Safari"
				if (count of windows) is 0 then return

				set windowTitle to name of front window
			end tell

			if isDefaultGroup() then return DEFAULT_GROUP_NAME

			set sidebarWasVisible to isSidebarVisible()
			-- logger's debugf("sidebarWasVisible: {}", sidebarWasVisible)

			if sidebarWasVisible is false then -- let's try to simplify by getting the name from the window name
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
				repeat with nextRow in rows of outline 1 of scroll area 1 of group 1 of splitter group 1 of front window
					if selected of nextRow is true then
						if not sidebarWasVisible then
							-- logger's debug("Closing Sidebar...")
							my closeSidebar()
						end if

						set groupDesc to description of UI element 1 of UI element 1 of nextRow
						set groupNameTokens to textUtil's split(groupDesc, ",")
						return first item of groupNameTokens
					end if
				end repeat
			end tell

			if not sidebarWasVisible then
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

			set sidebarWasVisible to isSidebarVisible()
			closeSidebar()

			script ToolBarWaiter
				tell application "System Events" to tell process "Safari"
					set frontmost to true

					click menu button 1 of group 1 of toolbar 1 of front window
				end tell
				true
			end script
			set waitResult to exec of retry on result for 3
			-- logger's debugf("WaitResult: {}", waitResult)

			tell application "System Events" to tell process "Safari"
				if groupName is missing value then
					-- The default group is the 3rd item.
					click menu item 3 of menu 1 of group 1 of toolbar 1 of front window

				else
					try
						click menu item groupName of menu 1 of group 1 of toolbar 1 of window 1
					on error
						logger's warnf("Group: {} was not found", groupName)
						kb's pressKey("esc")
					end try
				end if
			end tell

			if sidebarWasVisible then showSidebar()
		end switchGroup

		(*
			Determine if on default group when:
				Sidebar Visible: first row is selected.
				Sidebar Hidden: the tab picker is small, without any labels

		*)
		on isDefaultGroup()
			if isSidebarVisible() then
				tell application "System Events" to tell process "Safari"
					return value of attribute "AXSelected" of row 1 of outline 1 of scroll area 1 of group 1 of splitter group 1 of front window
				end tell
			end if

			-- else: Sidebar not visible.
			script GroupPickerWaiter
				tell application "System Events" to tell process "Safari"
					first menu button of group 1 of toolbar 1 of front window whose help is "Tab Group Picker"
				end tell
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
				set tabGroupId to get value of attribute "AXIdentifier" of menu button 1 of group 1 of toolbar 1 of front window
			end tell
			tabGroupId does not contain "TabGroup="
		end isDefaultGroup

	end script
end decorate
