(*
	This script library is a wrapper to Safari application.

	@Prerequisites
		This library is designed initially to handle when new windows are opened
		with Start Page. To support other configurations.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/17.4.1/safari

	This library creates 2 instances:
		SafariInstance - this library
		SafariTabInstance - wrapper to a Safari tab.

	Debugging existing tab:
		use loggerLib : script "core/logger"
		use safariLib : script "core/safari"

		set logger to loggerLib's new("ad hoc")
		set safari to safariLib's new()

		set theTab to safari's getFrontTab()
		tell theTab
			log name of its appWindow as text
			return
			setValueById("comment_msn_description", "you

		13")
		end tell

	@Created: Wednesday, April 24, 2024 at 1:03:10 PM
	@Last Modified: 2026-02-20 13:22:24
*)

use script "core/Text Utilities"
use scripting additions

use std : script "core/std"
use textUtil : script "core/string"
use unic : script "core/unicodes"

use loggerFactory : script "core/logger-factory"

use safariTabLib : script "core/safari-tab"
use decSafariTabFinder : script "core/dec-safari-tab-finder"
use decSafariUiNoncompact : script "core/dec-safari-ui-noncompact"
use decSafariUiCompact : script "core/dec-safari-ui-compact"
use decSafariSidebar : script "core/dec-safari-sidebar"
use decSafariKeychain : script "core/dec-safari-keychain"
use decSafariInspector : script "core/dec-safari-inspector"

use kbLib : script "core/keyboard"
use uiutilLib : script "core/ui-util"
use winUtilLib : script "core/window"
use dockLib : script "core/dock"
use retryLib : script "core/retry"

property logger : missing value

property kb : missing value
property uiutil : missing value
property winUtil : missing value
property dock : missing value
property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Manual: Front Tab
		Manual: First Tab
		Manual: Show Side Bar (Visible,Hidden)
		Manual: Close Side Bar (Visible,Hidden)
		Manual: Get Group Name(default, group selected)

		Manual: Switch Group(not found, found, no app, no window, missing value for default)
		Manual: New Window
		Manual: Find Tab With Name ()
		New Tab - Manually Check when no window is present in current space.
		Open in Cognito

		Get Tab by Window ID - Manual
		Manual: Address Bar is Focused
		Manual: Select OTP
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
	if caseIndex is 1 then
		(*
			Cases to check:
				Loading Page...	(Example: https://www.huffpost.com/entry/worst-website-load-times_n_571889)
				Favorites://
				Blank - Toggle which page to load in Safari preferences then trigger a new tab/window.
				Local HTML - Save a webpage then open it from Finder
				localhost
				Regular Website
				about:blank
				bookmarks://
				history://
				Safari Can't Connect to the Server (Failed to open page) - Connect to localhost while no local server is running.
				safari-resource:/ErrorPage.html (Title: Failed to open page,Address Bar Value: localhost:8080)
		*)
		activate application "Safari"
		set frontTab to sut's getFrontTab()
		if frontTab is missing value then
			logger's info("A front tab was not found")
		else
			logger's infof("Is Fullscreen: {}", sut's isFullScreen())
			logger's infof("Is MediaFullscreen: {}", sut's isMediaFullScreen())
			logger's infof("Keychain Form Visible: {}", sut's isKeychainFormVisible())
			logger's infof("Is Compact: {}", sut's isCompact())
			logger's infof("URL: {}", frontTab's getURL())
			logger's infof("URL Class: {}", class of frontTab's getURL())
			logger's infof("Has Toolbar: {}", frontTab's hasToolBar())
			logger's infof("Address Bar Value: {}", frontTab's getAddressBarValue())
			logger's infof("Title: {}", frontTab's getTitle())
			logger's infof("Window Name: {}", frontTab's getWindowName())
			logger's infof("Window ID: {}", frontTab's getWindowID())
			logger's infof("Sidebar Visible: {}", sut's isSidebarVisible())
			logger's infof("Is Loading: {}", sut's isLoading())
			logger's infof("Is Playing: {}", sut's isPlaying())
			logger's infof("Is Default Group: {}", sut's isDefaultGroup())

			delay 3 -- Manually check below when in/visible.
			logger's infof("Address Bar is focused: {}", sut's isAddressBarFocused())
		end if

	else if caseIndex is 2 then
		-- set youTab to findTabStartingWithUrl("www.youtube.com")
		-- log youTab
		set posTab to sut's findTabStartingWithName("Poseidon")
		if posTab is not missing value then
			posTab's focus()
		end if
		-- if youTab is not missing value then log name of theTab of youTab as text

	else if caseIndex is 3 then

		sut's showSidebar()
		assertThat of std given condition:sut's isSidebarVisible(), messageOnFail:"Failed spot check"
		logger's info("Passed.")

	else if caseIndex is 4 then
		sut's closeSidebar()
		assertThat of std given condition:sut's isSidebarVisible() is false, messageOnFail:"Failed spot check"
		logger's info("Passed.")

	else if caseIndex is 5 then
		logger's infof("Current Group Name: {}", sut's getGroupName())

	else if caseIndex is 6 then
		set newSutGroup to "Unicorn" -- not found
		set newSutGroup to "Music"
		set newSutGroup to missing value
		logger's infof("newSutGroup: {}", newSutGroup)

		sut's switchGroup(newSutGroup)

	else if caseIndex is 7 then
		-- sut's newWindow("https://www.example.com")
		-- sut's newWindowWithProfile("https://www.example.com", "Business")
		sut's newWindowWithProfile("https://www.example.com", "Unicorn")

		logger's infof("Window name: {}", name of appWindow of result)

		-- BELOW case handling FOR REVIEW.


	else if caseIndex is 3 then
		set firstTab to getFirstTab()
		if firstTab is missing value then
			log "not found"
		else
			log aurl of firstTab
		end if

	else if caseIndex is 4 then
		newWindow("https://www.example.com")

	else if caseIndex is 5 then
		set frontTab to getFrontTab()

		if frontTab is missing value then
			log "Front Tab not found"
		else
			set newTab to frontTab's newTab("https://www.example.com")
			newTab's waitForPageLoad()
			log _url of newTab
		end if

	else if caseIndex is 6 then
		sut's newTab("https://www.example.com")


	else if caseIndex is 7 then
		newCognito("https://www.example.com")


	else if caseIndex is 7 then
		set existingWindowID to 63731 -- Manually set this ID.
		set existingTab to getWindowTab(existingWindowID)
		if existingTab is missing value then
			logger's debugf("Window with ID: {} was not found", existingWindowID)

		else
			existingTab's focus()
			existingTab's reload()
			log _url of existingTab

		end if

	else if caseIndex is 13 then
		activate application "Safari"
		set adhocCredKey to "core.keychain"
		sut's selectKeychainItem(adhocCredKey)

	end if

	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's inject(me)
	set kb to kbLib's new()
	set uiutil to uiutilLib's new()
	set winUtil to winUtilLib's new()
	set dock to dockLib's new()
	set retry to retryLib's new()

	try
		set decSafariTabGroup to script "core/dec-safari-tab-group"
	on error
		set decSafariTabGroup to missing value
	end try

	script SafariInstance
		(*
			TOFIX: False positive detected when a dialog was detected.  The
			Developer settings window is not a dialog btw.
		*)
		on isMediaFullScreen()
			if running of application "Safari" is false then return false

			tell application "System Events" to tell process "Safari"
				exists (first window whose description is "dialog")
			end tell
		end isMediaFullScreen

		on isFullScreen()
			if running of application "Safari" is false then return false

			tell application "System Events" to tell process "Safari"
				value of attribute "AXFullScreen" of front window
			end tell
		end isFullScreen

		(* Slow operation, 3s. *)
		on isAddressBarFocused()
			if running of application "Safari" is false then return missing value

			if isCompact() then
				tell application "System Events" to tell process "Safari"
					return value of attribute "AXSelectedText" of text field 1 of (first radio button of UI element 1 of last group of toolbar 1 of front window whose value of attribute "AXValue" is true) is not missing value
				end tell
			end if

			tell application "System Events" to tell process "Safari"
				value of attribute "AXSelectedText" of text field 1 of (my _getAddressBarGroup()) is not missing value
			end tell
		end isAddressBarFocused


		on getFrontTab()
			if not winUtil's hasWindow("Safari") then return missing value

			tell application "Safari" to tell first window
				if current tab is missing value then return missing value -- When on full screen.

				safariTabLib's new(its id, index of current tab, me)
			end tell
		end getFrontTab


		(* Gets the first tab across spaces. NOTE: This may not be the user expected front window so use this handler with care. *)
		on getFirstTab()
			if running of application "Safari" is false then return missing value

			tell application "Safari"
				if (count of windows) is 0 then return missing value

				tell first window
					if current tab is missing value then return missing value -- When on full screen.

					safariTabLib's new(its id, index of current tab, me)
				end tell
			end tell
		end getFirstTab


		on isCompact()
			tell application "System Events" to tell process "Safari"
				not (exists group 1 of front window)
			end tell
		end isCompact

		(*
			TODO: Test for when Safari is not running.
			This is dependent on the user setting for new window/tabs, currently it is tested against when new window is on a "Start Page"
		*)
		on newWindow(targetUrl)
			newWindowWithProfile(targetUrl, missing value)
		end newWindow


		(*
			TODO: Test for when Safari is not running.
			This is dependent on the user setting for new window/tabs, currently it is tested against when new window is on a "Start Page"
		*)
		on newWindowWithProfile(targetUrl, profileName)
			set normalProfileName to normalizeProfileName(profileName)
			set startPageTitleWithProfile to normalProfileName & unic's SEPARATOR & "Start Page"

			set safariAppRunning to running of application "Safari"
			tell application "System Events" to tell process "Safari"
				if (not safariAppRunning) or not (exists window startPageTitleWithProfile) then
					my _newSafariWindow(profileName)
				end if
			end tell

			script StartPageWaiter
				tell application "Safari" to set windowId to id of window startPageTitleWithProfile -- New window will not always start with "Start Page"
				windowId
			end script
			set windowId to exec of retry on result for 3
			assertThat of std given condition:windowId is not missing value, messageOnFail:"Failed to initialize safari window to a valid state"

			tell application "Safari"
				set newSafariTabInstance to safariTabLib's new(windowId, count of tabs of window startPageTitleWithProfile, me)
			end tell
			newSafariTabInstance's focus()
			if targetUrl is not missing value then
				tell application "Safari" to set URL of front document to targetUrl -- can't avoid focusing the address bar for fresh pages.
			end if

			newSafariTabInstance
		end newWindowWithProfile


		(* @returns "Personal" as the default profile name if passed a missing value. *)
		on normalizeProfileName(profileName)
			if profileName is missing value then return "Personal"

			profileName
		end normalizeProfileName

		on _newSafariWindow(profileName)
			set windowProfileName to normalizeProfileName(profileName)
			dock's triggerAppMenu("Safari", {"New Window", "New " & windowProfileName & " Window"})

			script BlankDocumentWaiter
				tell application "Safari"
					if (source of front document) is "" then return true
				end tell
			end script
			exec of retry on result for 3
		end _newSafariWindow


		(*
			Note: On Safari 15, you have to configure General > New tabs open with blank
			page. Doing otherwise like setting it to 'Start Page' have problems where
			the url passed will be ignored and you are left with a Start Page. *)
		on newTab(targetUrl)
			if running of application "Safari" is false then
				logger's debug("new window due to absence of Safari")

				return newWindow(targetUrl)
			end if

			tell application "Safari"
				try
					if (count of (windows whose visible is true)) is 0 then return my newWindow(targetUrl) -- battlescar
				on error
					return my newWindow(targetUrl)
				end try
			end tell

			-- main's focusWindowWithToolbar()
			focusWindowWithToolbar()

			-- logger's debugf("theUrl: {}", theUrl)
			tell application "Safari"
				set appWindow to first window
				tell appWindow to set current tab to (make new tab with properties {URL:targetUrl})
				set miniaturized of appWindow to false
				set tabTotal to count of tabs of appWindow

				(* Safari 15 Fix to intermittent loading bug. *)
				(*
		script BugWaiter
			tell document of appWindow
				if its name is "Start Page" then return missing value

				if its name is not "Untitled" then return true

				if its source is not "" then return true
			end tell
		end script
		set waitResult to retry's exec on result for 3
		if waitResult is missing value then set URL of document of appWindow to theUrl
		*)
			end tell

			safariTabLib's new(id of appWindow, tabTotal, me)
		end newTab

		on newCognito(targetUrl)
			if running of application "Safari" is false then activate application "Safari"

			tell application "System Events" to tell application process "Safari"
				click menu item "New Private Window" of menu "File" of menu bar 1
			end tell

			tell application "Safari"
				set the URL of current tab of front window to targetUrl
				set windowId to id of front window as integer
			end tell
			safariTabLib's new(windowId, 1)
		end newCognito


		on focusWindowWithToolbar()
			if running of application "Safari" is false then return

			set toolbarredWindow to missing value
			tell application "System Events" to tell process "Safari"
				if (count of windows) is 0 then return

				repeat with nextWindow in windows
					if exists (toolbar 1 of nextWindow) then
						set toolbarredWindow to nextWindow
						exit repeat
					end if
				end repeat

				if toolbarredWindow is not missing value then
					set focusWindowName to the name of toolbarredWindow as text
					try
						click menu item focusWindowName of menu 1 of menu bar item "Window" of menu bar 1
					end try
				end if
			end tell
		end focusWindowWithToolbar
	end script

	decSafariTabFinder's decorate(result)
	decSafariUiNoncompact's decorate(result)
	decSafariUiCompact's decorate(result)
	decSafariSidebar's decorate(result)
	decSafariKeychain's decorate(result)
	set baseInstance to decSafariInspector's decorate(result)

	(* Optionally add tab group handlers if the decorator is available. *)
	if decSafariTabGroup is not missing value then
		decSafariTabGroup's decorate(result)
	else
	baseInstance
	end if
end new
