(*
	@Purpose:
		The original safari script is quite big and we want to improve its manageability by breaking it down into smaller pieces.
		This decorator will contain the handlers relating to tab groups.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/16.0/dec-safari-tab-group

	@Created: Wednesday, September 20, 2023 at 10:13:11 AM
	@Last Modified: 2023-10-09 10:46:47
	@Change Logs: .
*)
use listUtil : script "core/list"
use textUtil : script "core/string"
use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"

use spotScript : script "core/spot-test"

property logger : missing value
property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Switch to applescript-core
		Manual: Switch to Default
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	-- activate application ""
	set sutLib to script "safari"
	set sut to sutLib's new()
	set sut to decorate(sut)

	logger's infof("Group name before: {}", sut's getGroupName())

	if caseIndex is 1 then
		sut's switchGroup("applescript-core")

	else if caseIndex is 2 then
		sut's switchGroup(missing value)

	else if caseIndex is 3 then

	else

	end if
	logger's infof("Group name after: {}", sut's getGroupName())

	spot's finish()
	logger's finish()
end spotCheck


on newSpotBase()
	script SpotBaseInstance
		property template : missing value
	end script
end newSpotBase


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	set retry to retryLib's new()

	script SafariTabGroupDecorator
		property parent : mainScript

		on getGroupName()
			if running of application "Safari" is false then return missing value

			tell application "System Events" to tell process "Safari"
				if (count of windows) is 0 then return

				set windowTitle to name of front window
			end tell


			set sideBarWasVisible to isSideBarVisible()
			-- logger's debugf("sideBarWasVisible: {}", sideBarWasVisible)

			if sideBarWasVisible is false then -- let's try to simplify by getting the name from the window name
				set nameTokens to textUtil's split(windowTitle, unic's SEPARATOR)
				if number of items in nameTokens is 2 then -- There's a small risk that a current website has the same separator characters in its title and thus result in the wrong group name.
					logger's info("Returning group name from window title")
					return first item of nameTokens
				end if
			end if

			showSideBar()


			-- UI detects side bar is still hidden, so we wait, to make close work reliably.
			script SidebarWaiter
				if isSideBarVisible() is true then return true
			end script
			exec of retry on SidebarWaiter for 5

			tell application "System Events" to tell process "Safari"
				repeat with nextRow in rows of outline 1 of scroll area 1 of group 1 of splitter group 1 of front window
					if selected of nextRow is true then
						if not sideBarWasVisible then
							-- logger's debug("Closing Sidebar...")
							my closeSideBar()
						end if

						set groupDesc to description of UI element 1 of UI element 1 of nextRow
						set groupNameTokens to textUtil's split(groupDesc, ",")
						return first item of groupNameTokens
					end if
				end repeat
			end tell

			if not sideBarWasVisible then
				closeSideBar()
			end if
			missing value
		end getGroupName


		(*
			Will switch group by:
				1.  Closing the SideBar
				2.  Triggering the group switcher menu UI
				3.  Clicking the first (missing value) or the matching menu item.
				4.  Restore if SideBar wasn't initially closed.

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

			set sideBarWasVisible to isSideBarVisible()
			closeSideBar()

			activate application "Safari"
			script ToolBarWaiter
				tell application "System Events" to tell process "Safari"
					click menu button 1 of group 1 of toolbar 1 of window 1
				end tell
				true
			end script
			set waitResult to exec of retry on result for 3
			-- logger's debugf("WaitResult: {}", waitResult)

			tell application "System Events" to tell process "Safari"
				if groupName is missing value then
					click menu item 1 of menu 1 of group 1 of toolbar 1 of front window
				else
					try
						click menu item groupName of menu 1 of group 1 of toolbar 1 of window 1
					on error
						logger's warnf("Group: {} was not found", groupName)
						kb's pressKey("esc")
					end try
				end if
			end tell

			if sideBarWasVisible then showSideBar()
		end switchGroup
	end script
end decorate
