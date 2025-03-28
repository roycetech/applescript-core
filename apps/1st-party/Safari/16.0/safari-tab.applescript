(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/16.0/safari-tab

	@Created: Wednesday, September 20, 2023 at 3:23:31 PM
	@Last Modified: 2024-11-26 07:05:45
*)

use scripting additions

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"

use safariJavaScript : script "core/safari-javascript"

property logger : missing value
property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set spotScript to script "core/spot-test"
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Manual: Closed Tab
		Manual: Move tab to index
	")

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
	if caseIndex is 1 then
		(* Prepare a test tab, then close it.*)
		logger's info("Close the test tab.")
		delay 8

		logger's infof("Title after closing: {}", sut's getTitle())
		logger's infof("Has toolbar: {}", sut's hasToolBar())
		logger's infof("Has alert: {}", sut's hasAlert())
		logger's infof("Name: {}", sut's getWindowName())
		logger's infof("Window ID: {}", sut's getWindowID())

	else if caseIndex is 2 then
		sut's moveTabToIndex(5)

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

	script SafariTabInstance
		property appWindow : missing value -- app window, not syseve window.
		property maxTryTimes : 60
		property sleepSec : 1
		-- property closeOtherTabsOnFocus : false
		property tabIndex : pTabIndex
		-- property safari : pSafari

		property _tab : missing value
		property _url : missing value


		on moveTabToIndex(newIndex)
			if running of application "Safari" is false then return

			tell application "Safari"
				set tabCount to (count of tabs in front window)
				set sourceTabIndex to tabIndex -- the index of the tab you want to move
				set targetTabIndex to newIndex -- the index where you want to move the tab

				if (sourceTabIndex > tabCount) or (targetTabIndex > tabCount) then
					display dialog "Invalid tab index."
				else if targetTabIndex - sourceTabIndex is 1 then
					move tab targetTabIndex of front window to before tab sourceTabIndex of front window
				else
					move tab sourceTabIndex of front window to before tab targetTabIndex of front window
				end if
				set my tabIndex to newIndex
				set my _tab to tab newIndex of front window
				set current tab of front window to my _tab
			end tell
		end moveTabToIndex


		on getTabIndex()
			tabIndex
		end getTabIndex

		on getTitle()
			try
				return name of _tab -- This returns the title of the front tab.
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
			tell application "System Events" to tell process "Safari" to tell my getSysEveWindow()
				try
					(click button "Close" of group 1 of tab group 1 of splitter group 1) exists
				end try
			end tell
		end dismissAlert

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
				set currentUrl to URL of my getDocument()
				set URL of my getDocument() to currentUrl
			end tell
			delay 0.01
		end reload

		on waitForPageToLoad()
			waitForPageLoad()
		end waitForPageToLoad

		on waitForPageLoad()
			script SourceWaiter
				tell application "Safari"
					if my getWindowName() is equal to "Failed to open page" then return "failed"
					if source of my getDocument() is not "" then return true
				end tell
			end script
			exec of retry on result for maxTryTimes by sleepSec
		end waitForPageLoad


		on isDocumentLoading()
			tell application "Safari"
				if my getWindowName() is equal to "Failed to open page" then return false
				if source of my getDocument() is not "" then return true
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
					return (source of my getDocument()) as text
				end try
			end tell

			missing value
		end getSource

		on getURL()
			tell application "Safari"
				try
					return URL of my getDocument()
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
				tell application "Safari" to set URL of my getDocument() to targetUrl
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

		on getDocument()
			tell application "Safari"
				document (my getWindowName())
			end tell
		end getDocument


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
	set theInstance to safariJavaScript's decorate(SafariTabInstance)

	theInstance
end new
