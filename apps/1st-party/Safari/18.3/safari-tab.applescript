(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/18.3/safari-tab

	@Created: Tue, Feb 18, 2025 at 10:21:55 AM
	@Last Tue, Feb 18, 2025 at 10:21:58 AM

	@Change Logs:
		Tue, Apr 08, 2025 at 11:41:12 AM - Fix #focus to trigger via menu.
		Fri, Feb 28, 2025 at 09:15:44 AM - Added #isUnableToConnect
		Tue, Feb 18, 2025 at 10:21:41 AM - Add #waitForAlert
*)

use scripting additions

use unic : script "core/unicodes"
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"

use safariJavaScript : script "core/safari-javascript"

property logger : missing value
property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		INFO
		Manual: Closed Tab
		Manual: Move tab to index
		Manual: Go to Path
		Manual: Raise Window

		Manual: Move to New Window
	")

	set usrLib to script "core/user"
	set usr to usrLib's new()
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	tell application "Safari"
		tell front window
			set sut to my new(its id, index of its current tab, missing value)

		end tell
	end tell

	logger's infof("Title: {}", sut's getTitle())
	logger's infof("Name: {}", sut's getWindowName())
	logger's infof("Window ID: {}", sut's getWindowID())
	logger's infof("Has toolbar: {}", sut's hasToolBar())
	logger's infof("Has alert: {}", sut's hasAlert())
	logger's infof("Current URL: {}", sut's getURL())
	logger's infof("Base URL: {}", sut's getBaseURL())
	-- logger's infof("Is page Loading: {}", sut's isLoading())  -- I think this is on the safari instance, not the safari tab instance.
	logger's infof("Is unable to connect: {}", sut's isUnableToConnect())

	if caseIndex is 2 then
		(* Prepare a test tab, then close it.*)
		logger's info("Close the test tab.")
		delay 8

		logger's infof("Title after closing: {}", sut's getTitle())
		logger's infof("Has toolbar: {}", sut's hasToolBar())
		logger's infof("Has alert: {}", sut's hasAlert())
		logger's infof("Name: {}", sut's getWindowName())
		logger's infof("Window ID: {}", sut's getWindowID())

	else if caseIndex is 3 then
		sut's moveTabToIndex(5)
		logger's infof("Current Title: {}", sut's getTitle())

	else if caseIndex is 4 then
		sut's goto("https://www.apple.com")
		sut's waitForPageLoad()

		set sutPath to missing value
		set sutPath to "airpods"

		logger's debugf("sutPath: {}", sutPath)

		sut's gotoPath(sutPath)

	else if caseIndex is 5 then
		(*
			Prerequisite:
				1. Open 2 windows, one of which points to apple.com.
		*)
		logger's info("Manually focus on the non-apple window...")
		usr's afplay("Tink.aiff")
		delay 2

		tell application "Safari" to tell second window -- Use a different SUT
			set sut to my new(its id, index of its current tab, missing value)
		end tell

		sut's raiseWindow()

	else if caseIndex is 6 then
		sut's moveToNewWindow()

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*
		@windowId app window ID
		@pTabIndex the Safari tab index
	*)
on new(windowId, pTabIndex)
	-- on new(windowId, pTabIndex, pSafari)
	loggerFactory's inject(me)

	set retry to retryLib's new()

	-- logger's debugf("Window ID: {}, TabIndex: {}", {windowId, pTabIndex}) -- wished the name or the url can be included in the log, not easy to do.

	set decSafariProfile to script "core/dec-safari-profile"

	script SafariTabInstance
		property appWindow : missing value -- app window, not syseve window.
		property maxTryTimes : 60
		property sleepSec : 1
		property closeOtherTabsOnFocus : false
		property tabIndex : pTabIndex
		-- property safari : pSafari

		property _tab : missing value
		property _url : missing value


		on moveToNewWindow()
			if running of application "Safari" is false then return

			tell application "System Events" to tell process "Safari"
				set frontmost to true
				try
					click menu item "Move Tab to New Window" of menu 1 of menu bar item "Window" of menu bar 1
				end try
			end tell
		end moveToNewWindow

		on isUnableToConnect()
			if running of application "Safari" is false then return false

			getWindowName() is equal to getProfile() & unic's SEPARATOR & "Failed to open page"
		end isUnableToConnect


		on raiseWindow()
			if running of application "Safari" is false then return

			set targetTitle to getTitle()
			tell application "System Events" to tell process "Safari"
				set frontmost to true
				try
					click (first menu item of menu 1 of menu bar item "Window" of menu bar 1 whose title ends with targetTitle)
				on error the errorMessage number the errorNumber
					log errorMessage

				end try
			end tell
		end raiseWindow


		on gotoPath(urlPath)
			if running of application "Safari" is false then return
			if getBaseURL() is missing value then return

			if urlPath is missing value then
				goto(getBaseURL())
				return
			end if

			set calcSubPath to urlPath
			if urlPath does not start with "/" then set calcSubPath to "/" & urlPath

			goto(getBaseURL() & calcSubPath)
		end gotoPath


		on getBaseURL()
			if running of application "Safari" is false then return

			tell application "Safari"
				set baseUrl to do JavaScript "location.origin" in front document
			end tell
			if baseUrl is equal to "null" then return missing value

			baseUrl
		end getBaseURL

		(*
			@returns void
		*)
		on moveTabToIndex(newIndex)
			if running of application "Safari" is false then return

			tell application "Safari"
				set tabCount to (count of tabs in front window)
				set sourceTabIndex to my tabIndex -- the index of the tab you want to move
				set targetTabIndex to newIndex -- the index where you want to move the tab
				if sourceTabIndex is equal to targetTabIndex then return

				set nextToTarget to targetTabIndex - sourceTabIndex is 1
				if (sourceTabIndex > tabCount) or (targetTabIndex > tabCount) then
					display dialog "Invalid tab index."

				else if nextToTarget then
					move tab targetTabIndex of front window to before tab sourceTabIndex of front window

				else
					move tab sourceTabIndex of front window to before tab targetTabIndex of front window
				end if
				set my tabIndex to newIndex
				set my _tab to tab newIndex of front window
				set current tab of front window to my _tab
			end tell
			script NameWaiter
				if name of my _tab is not "Untitled" then return true
			end script
			exec of retry on result for 20 by 0.2
		end moveTabToIndex


		on getTabIndex()
			tabIndex
		end getTabIndex

		on getTitle()
			try
				return name of my _tab -- This returns the title of the front tab.
			end try -- When the tab is closed.
			missing value
		end getTitle

		on hasToolBar()
			tell application "System Events" to tell process "Safari"
				try
					return exists toolbar 1 of my getSysEveWindow()
				end try
			end tell
			false
		end hasToolBar

		on hasAlert()
			tell application "System Events" to tell process "Safari" to tell my getSysEveWindow()
				try
					button "Close" of group 1 of tab group 1 of splitter group 1 exists
				on error
					false
				end try
			end tell
		end hasAlert

		on dismissAlert()
			if running of application "Safari" is false then return
			if not hasAlert() then return

			script AlertDismissalScript
				tell application "System Events" to tell process "Safari" to tell my getSysEveWindow()
					try
						(click button "Close" of group 1 of tab group 1 of splitter group 1) exists
					end try
					if not my hasAlert() then return true
				end tell
			end script
			exec of retry on result for 3
		end dismissAlert


		on waitForAlert()
			if running of application "Safari" is false then return

			script AlertWaiter
				if hasAlert() then return true
			end script
			exec of retry on result for 3
		end waitForAlert


		(* Creates a new tab at the end of the window (not next to the tab) *)
		on newTab(targetUrl)
			tell application "Safari"
				tell my appWindow to set current tab to (make new tab with properties {URL:targetUrl})
				set miniaturized of appWindow to false
				set tabTotal to count of tabs of appWindow
			end tell

			-- set newInstance to new(windowId, tabTotal, safari)
			set newInstance to new(windowId, tabTotal)
			set _url of newInstance to targetUrl
			the newInstance
		end newTab


		(* It checks the starting characters to match because Safari trims it in the menu when then name is more than 30 characters. *)
		on focus()
			try
				tell application "Safari" to set current tab of my appWindow to _tab
			end try -- When tab is manually closed


			set tabTitle to getTitle()

			tell application "System Events" to tell process "Safari"
				try
					set menuTitles to title of menu items of menu 1 of menu bar item "Window" of menu bar 1
				end try
			end tell

			set menuTitles to reverse of menuTitles

			repeat with nextMenuTitle in menuTitles
				if nextMenuTitle as text is "" then return

				set {prefix, suffix} to textUtil's split(nextMenuTitle, unic's ELLIPSIS)
				set prefix to textUtil's stringAfter(prefix, unic's SEPARATOR)
				if tabTitle starts with prefix and tabTitle ends with suffix then
					-- log "FOUND: " & nextMenuTitle
					exit repeat
				else
					-- log prefix
					-- log suffix
				end if
			end repeat
		end focus

		on closeTab()
			tell application "Safari" to close _tab
		end closeTab

		on closeWindow()
			tell application "Safari" to close my appWindow()
		end closeWindow

		on reload()
			focus()
			tell application "Safari"
				set currentUrl to URL of front document
				set URL of front document to currentUrl
			end tell
			delay 0.01
		end reload

		on waitForPageToLoad()
			waitForPageLoad()
		end waitForPageToLoad

		on waitForPageLoad()
			delay 0.5
			script SourceWaiter
				tell application "Safari"
					if my getWindowName() is equal to "Failed to open page" then return "failed"
					if source of front document is not "" then return true
				end tell
			end script
			exec of retry on result for maxTryTimes by sleepSec
		end waitForPageLoad


		on isDocumentLoading()
			tell application "Safari"
				if my getWindowName() is equal to "Failed to open page" then return false
				if source of front document is not "" then return true
			end tell
			false
		end isDocumentLoading


		on waitInSource(substring)
			script SubstringWaiter
				if getSource() contains substring then return true
			end script
			exec of retry on result for maxTryTimes by sleepSec
		end waitInSource

		on getSource()
			tell application "Safari"
				try
					return (source of front document) as text
				end try
			end tell

			missing value
		end getSource

		on getURL()
			tell application "Safari"
				try
					-- return URL of front document
					return URL of my _tab
				end try
			end tell

			missing value
		end getURL

		on getAddressBarValue()
			if hasToolBar() is false then return missing value

			tell application "System Events" to tell process "Safari"
				try
					set addressBarValue to value of text field 1 of last group of toolbar 1 of my getSysEveWindow()
					if addressBarValue is "" then return missing value
					return addressBarValue
				end try
			end tell
			missing value
		end getAddressBarValue

		on goto(targetUrl)
			script PageWaiter

				-- tell application "Safari" to set URL of document (name of my appWindow) to targetUrl
				tell application "Safari" to set URL of front document to targetUrl
				true
			end script
			exec of retry on result for 2
			delay 0.1 -- to give waitForPageLoad ample time to enter a loading state.
		end goto


		(* Note: Will dismiss the prompt of the*)
		on dismissPasswordSavePrompt()
			focus()
			script PasswordPrompt
				tell application "System Events" to tell process "Safari"
					click button "Not Now" of sheet 1 of front window
					-- we need system event window, appWindow is app Safari window so it would not work here.
					true
				end tell
			end script
			exec of retry on result for 5 -- let's try click it 5 times, ignoring outcomes.
		end dismissPasswordSavePrompt

		(* regex library is crappy.
				on extractUrlParam(paramName)
					tell application "Safari" to set _url to URL of my getDocument()
					set pattern to format {"(?<={}=)\\w+", paramName}
					set matchedString to regex's findFirst(_url, pattern)
					if matchedString is "nil" then return missing value

					matchedString
				end extractUrlParam
		*)

		on getWindowID()
			id of appWindow
		end getWindowID

		on getWindowName()
			name of appWindow
		end getWindowName

		on getSysEveWindow()
			tell application "System Events" to tell process "Safari"
				return window (name of appWindow)
			end tell
		end getSysEveWindow
	end script

	tell application "Safari"
		set appWindow of SafariTabInstance to window id windowId
		set _url of SafariTabInstance to URL of document of window id windowId
		set _tab of SafariTabInstance to item pTabIndex of tabs of appWindow of SafariTabInstance
	end tell
	safariJavaScript's decorate(SafariTabInstance)
	decSafariProfile's decorateTab(result)
end new
