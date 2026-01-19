(*
	@Purpose:
		The original safari script is quite big and we want to improve its manageability by breaking it down into smaller pieces.
		This decorator will contain the handlers relating to tab groups.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/16.0/dec-safari-sidebar

	@Created: Wednesday, September 20, 2023 at 10:13:11 AM
	@Last Modified: 2024-12-31 19:29:33
	@Change Logs: .
*)
use loggerFactory : script "core/logger-factory"

use uiutilLib : script "core/ui-util"
use retryLib : script "core/retry"

property logger : missing value

property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Manual: Show Sidebar
		Manual: Hide Sidebar
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
	
	logger's infof("Sidebar visible before: {}", sut's isSidebarVisible())
	
	if caseIndex is 1 then
		sut's showSidebar()
		
	else if caseIndex is 2 then
		sut's closeSidebar()
		
	else if caseIndex is 3 then
		
	else
		
	end if
	logger's infof("Side bar visible after: {}", sut's isSidebarVisible())
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	set uiutil to uiutilLib's new()
	set retry to retryLib's new()
	
	script SafariSidebarDecorator
		property parent : mainScript
		
		on showSidebar()
			if running of application "Safari" is false then return
			tell application "System Events" to tell process "Safari"
				if (count of windows) is 0 then return
			end tell
			if isSidebarVisible() then return
			
			tell application "System Events" to tell application process "Safari"
				set groupOneButtons to buttons of group 1 of toolbar 1 of front window
			end tell
			
			set sideBarButton to uiutil's new()'s findUiContainingIdAttribute(groupOneButtons, "SidebarButton")
			tell application "System Events" to click sideBarButton
		end showSidebar
		
		
		on closeSidebar()
			if running of application "Safari" is false then return
			if not isSidebarVisible() then return
			
			tell application "System Events" to tell process "Safari"
				if (count of windows) is 0 then return
			end tell
			
			tell application "System Events" to tell application process "Safari"
				set groupOneButtons to buttons of group 1 of toolbar 1 of front window
			end tell
			
			set sideBarButton to uiutil's new()'s findUiContainingIdAttribute(groupOneButtons, "SidebarButton")
			script CloseWaiter
				tell application "System Events" to click sideBarButton
				if isSidebarVisible() is false then return true
			end script
			exec of retry on result for 3
		end closeSidebar
		
		
		on isSidebarVisible()
			if running of application "Safari" is false then return false
			
			tell application "System Events" to tell process "Safari"
				try
					return get value of attribute "AXIdentifier" of menu button 1 of group 1 of toolbar 1 of window 1 is "NewTabGroupButton"
				end try
			end tell
			false
		end isSidebarVisible
	end script
end decorate
