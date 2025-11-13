(*
	This script library is a wrapper to Safari application.

	@Prerequisites
		This library is designed initially to handle when new windows are opened
		with Start Page. To support other configurations.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/18.6/safari

	This library creates 2 instances:
		SafariInstance - this library
		SafariTabInstance - wrapper to a Safari tab.

	Debugging existing tab:
		use loggerFactory : script "core/logger-factory"
		use safariLib : script "core/safari"

		set safari to safariLib's new()

		set theTab to safari's getFrontTab()
		tell theTab
			log name of its appWindow as text
			return
			setValueById("comment_msn_description", "you

		13")
		end tell

	@Created: Mon, Feb 10, 2025 at 7:30:44 AM
	@Last Modified: 2025-10-27 07:37:28
*)

use scripting additions

use script "core/Text Utilities"

use std : script "core/std"

use unic : script "core/unicodes"

use loggerFactory : script "core/logger-factory"

use safariTabLib : script "core/safari-tab"
use retryLib : script "core/retry"
use dockLib : script "core/dock"

use winUtilLib : script "core/window"

property TopLevel : me

property logger : missing value
property winUtil : missing value
property retry : missing value
property dock : missing value

property KEYWORD_FORM_SUBMIT_PROMPT : "send a form again"
property KEYWORD_FORM_NON_PRIVATE_CONNECTION : "connection that is not private"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		INFO
		Manual: Front Tab
		Manual: Show Side Bar (Visible,Hidden)
		Manual: Close Side Bar (Visible,Hidden)
		Manual: New Window

		Manual: First Tab
		Manual: Get Group Name(default, group selected)
		Manual: Switch Group(not found, found, no app, no window, missing value for default)
		Manual: Find Tab With Name ()
		New Tab - Manually Check when no window is present in current space.

		Open in Cognito
		Get Tab by Window ID - Manual
		Manual: Address Bar is Focused
		Manual: Select OTP
		Manual: Cancel Form Submit Again

		Manual: Send Form Submit Again
		Manual: Non Private - Cancel
		Manual: Non Private - Visit Website
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
	logger's infof("Selection: {}", sut's getSelectedText())
	logger's infof("Integration: Is Location Prompt Present: {}", sut's isLocationPromptPresent())
	logger's infof("Integration: Current Group Name: {}", sut's getGroupName())
	logger's infof("Is form submit again prompt present: {}", sut's isFormSubmitAgainPresent())
	logger's infof("Non private connection prompt present: {}", sut's isNonPrivateConnectionPromptPresent())

	if caseIndex is 2 then
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
			logger's infof("Is Fullscreen: {}", sut's isFullscreen())
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
			logger's infof("Sidebar Visible: {}", sut's isSideBarVisible())
			logger's infof("Is Loading: {}", sut's isLoading())
			logger's infof("Is Playing: {}", sut's isPlaying())
			logger's infof("Is Default Group: {}", sut's isDefaultGroup())
			logger's infof("Is Downloads Popup Present: {}", sut's isDownloadsPopupPresent())

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

		sut's showSideBar()
		assertThat of std given condition:sut's isSideBarVisible(), messageOnFail:"Failed spot check"
		logger's info("Sidebar detected.")

	else if caseIndex is 4 then
		sut's closeSideBar()
		assertThat of std given condition:sut's isSideBarVisible() is false, messageOnFail:"Failed spot check"
		logger's info("Sidebar not detected.")

	else if caseIndex is 5 then
		sut's newWindow("https://www.example.com")

	else if caseIndex is 5 then
		set frontTab to getFrontTab()

		if frontTab is missing value then
			log "Front Tab not found"
		else
			set newTab to frontTab's newTab("https://www.example.com")
			newTab's waitForPageLoad()
			log _url of newTab
		end if

	else if caseIndex is 5 then

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

	else if caseIndex is 15 then
		sut's cancelFormSubmitAgain()

	else if caseIndex is 16 then
		sut's confirmFormSubmitAgain()

	else if caseIndex is 17 then
		sut's cancelNonPrivateConnection()

	else if caseIndex is 18 then
		sut's visitNonPrivateConnection()

	end if

	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's inject(me)
	set winUtil to winUtilLib's new()
	set retry to retryLib's new()
	set dock to dockLib's new()

	script SafariInstance
		if running of application "Safari" is false then return false

		on isDownloadsPopupPresent()
			tell application "System Events" to tell process "Safari"
				exists (button "Clear downloads" of pop over 1 of toolbar 1 of front window)
			end tell
		end isDownloadsPopupPresent


		on hideOtherWindows()
			tell application "System Events" to tell process "Safari"
				set nonMatchedWindows to windows whose title does not contain my getTitle()
				repeat with nextUnmatched in nonMatchedWindows
					click (first button of nextUnmatched whose description is "minimize button")
				end repeat
			end tell
		end hideOtherWindows


		on isFormSubmitAgainPresent()
			run TopLevel's newPromptPresenceLambda(KEYWORD_FORM_SUBMIT_PROMPT)
		end isFormSubmitAgainPresent

		on confirmFormSubmitAgain()
			_respondToAccessRequest(TopLevel's newPromptPresenceLambda(KEYWORD_FORM_SUBMIT_PROMPT), TopLevel's newPromptButtonFactory("Send"))
		end confirmFormSubmitAgain

		on cancelFormSubmitAgain()
			_respondToAccessRequest(TopLevel's newPromptPresenceLambda(KEYWORD_FORM_SUBMIT_PROMPT), TopLevel's newPromptButtonFactory("Cancel"))
		end cancelFormSubmitAgain


		on isNonPrivateConnectionPromptPresent()
			run TopLevel's newPromptPresenceLambda(KEYWORD_FORM_NON_PRIVATE_CONNECTION)
		end isNonPrivateConnectionPromptPresent

		on cancelNonPrivateConnection()
			_respondToAccessRequest(TopLevel's newPromptPresenceLambda(KEYWORD_FORM_NON_PRIVATE_CONNECTION), TopLevel's newPromptButtonFactory("Cancel"))
		end cancelNonPrivateConnection

		on visitNonPrivateConnection()
			_respondToAccessRequest(TopLevel's newPromptPresenceLambda(KEYWORD_FORM_NON_PRIVATE_CONNECTION), TopLevel's newPromptButtonFactory("Visit Website"))
		end visitNonPrivateConnection

		(*
			NOTE: App window must already be at the frontmost. Recommend the
			user use dock's triggerAppMenu to accomplish this. setting to
			frontmost will bring all Safari windows to the front.
		*)
		on reload()
			if running of application "Safari" is false then return

			tell application "System Events" to tell process "Safari"
				try
					click menu item "Reload Page" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
		end reload

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

		on isFullscreen()
			if running of application "Safari" is false then return false

			tell application "System Events" to tell process "Safari"
				value of attribute "AXFullScreen" of front window
			end tell
		end isFullscreen

		on hasToolBar()
			if running of application "Safari" is false then return false

			tell application "System Events" to tell process "Safari"
				try
					return exists toolbar 1 of front window
				end try
			end tell

			false
		end hasToolBar


		(* Slow operation, 3s. *)
		on isAddressBarFocused()
			if not hasToolBar() then return false

			if isCompact() then
				tell application "System Events" to tell process "Safari"
					try
						return value of attribute "AXSelectedText" of text field 1 of (first radio button of UI element 1 of last group of toolbar 1 of front window whose value of attribute "AXValue" is true) is not missing value

					on error the errorMessage number the errorNumber -- When there's a single web page (tab) on a window.
						return focused of text field 1 of last group of toolbar 1 of front window
					end try
				end tell
			end if

			tell application "System Events" to tell process "Safari"
				value of attribute "AXSelectedText" of text field 1 of (my _getAddressBarGroup()) is not missing value
			end tell
		end isAddressBarFocused


		on getFrontTab()
			if not winUtil's hasWindow("Safari") then return missing value

			set firstWindow to missing value
			tell application "Safari"
				try
					set firstWindow to first window -- Error when only a settings window is available.
				end try

				if firstWindow is missing value then return missing value

				tell firstWindow
					if current tab is missing value then return missing value -- When on full screen.

					safariTabLib's new(its id, index of current tab, me)
				end tell
			end tell
		end getFrontTab


		(* Gets the first tab across spaces. NOTE: This may not be the user expected front window so use this handler with care. *)
		on getFirstTab()
			if running of application "Safari" is false then return missing value

			try
				firstWindow to first window -- Error when only a settings window is available.
			end try
			if firstWindow is missing value then return missing value

			tell application "Safari"
				if (count of windows) is 0 then return missing value

				tell firstWindow
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
			This is dependent on the user setting for new window/tabs, currently
			it is tested against when new window is on a "Start Page"
		*)
		on newWindow(targetUrl)
			newWindowWithProfile(targetUrl, missing value)
		end newWindow


		(*
			This is dependent on the user setting for new window/tabs, currently
			it is tested against when new window is on a "Start Page"
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
			if running of application "Safari" is false then
				activate application "Safari"
				delay 1

			else
				dock's triggerAppMenu("Safari", {"New Window", "New " & windowProfileName & " Window"})
			end if

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

		(* Does not work with text selected inside frames. *)
		on getSelectedText()
			tell application "Safari"
				do JavaScript "window.getSelection().toString()"
			end tell
		end getSelectedText
	end script

	set decSafariTabFinder to script "core/dec-safari-tab-finder"
	set decSafariTabFinder2 to script "core/dec-safari-tab-finder2"
	set decSafariUiNoncompact to script "core/dec-safari-ui-noncompact"
	set decSafariUiCompact to script "core/dec-safari-ui-compact"
	set decSafariSideBar to script "core/dec-safari-side-bar"
	set decSafariKeychain to script "core/dec-safari-keychain"
	set decSafariInspector to script "core/dec-safari-inspector"
	set decSafariPreferences to script "core/dec-safari-preferences"
	set decSafariProfile to script "core/dec-safari-profile"
	set decSafariPrivaceAndSecurity to script "core/dec-safari-privacy-and-security"

	set decSafariSettings to script "core/dec-safari-settings"
	set decSafariSettingsGeneral to script "core/dec-safari-settings-general"
	set decSafariSettingsTabs to script "core/dec-safari-settings-tabs"
	set decSafariSettingsAdvanced to script "core/dec-safari-settings-advanced"

	try
		set decSafariTabGroup to script "core/dec-safari-tab-group"
	on error
		set decSafariTabGroup to missing value
	end try

	decSafariTabFinder's decorate(SafariInstance)
	decSafariTabFinder2's decorate(result)
	decSafariUiNoncompact's decorate(result)
	decSafariUiCompact's decorate(result)
	decSafariSideBar's decorate(result)
	decSafariKeychain's decorate(result)
	decSafariPreferences's decorate(result)
	decSafariProfile's decorate(result)
	decSafariPrivaceAndSecurity's decorate(result)
	decSafariSettings's decorate(result)
	decSafariSettingsGeneral's decorate(result)
	decSafariSettingsTabs's decorate(result)
	decSafariSettingsAdvanced's decorate(result)

	set baseInstance to decSafariInspector's decorate(result)

	(* Optionally add tab group handlers if the decorator is available. *)
	if decSafariTabGroup is not missing value then
		decSafariTabGroup's decorate(result)
	else
		baseInstance
	end if
end new


on newPromptButtonFactory(buttonLabel)
	script FormSubmitAgainButtonFactory
		on run {} -- NOTE: This needs to be called explicitly.
			tell application "System Events" to tell process "Safari"
				try
					return button buttonLabel of sheet 1 of front window
				end try
			end tell
			missing value
		end run
	end script
end newPromptButtonFactory


on newPromptPresenceLambda(promptKeyword)
	script PromptPresenceLambda
		on run {}
			if running of application "Safari" is false then return false

			tell application "System Events" to tell process "Safari"
				try
					return value of static text 1 of sheet 1 of front window contains promptKeyword
				end try
			end tell

			false
		end run
	end script
end newPromptPresenceLambda
