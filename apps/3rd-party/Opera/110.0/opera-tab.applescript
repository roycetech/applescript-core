(*
	Retrofitted from safari-tab.applescript.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Opera/110.0/opera-tab'

	@Created: December 25, 2023 3:30 PM
	@Last Modified: 2024-06-07 11:57:21
*)

use scripting additions

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"

use operaJavaScript : script "core/opera-javascript"

use spotScript : script "core/spot-test"

property logger : missing value
property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Manual: Open Google Translate
		Manual: Closed Tab
		Manual: Move tab to index
		Manual: Run a Script
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	tell application "Opera"
		tell front window
			set sut to my new(its id, active tab index)

		end tell
	end tell

	logger's infof("Title: {}", sut's getTitle())
	logger's infof("Name: {}", sut's getWindowName())
	logger's infof("Window ID: {}", sut's getWindowID())
	logger's infof("Has alert: {}", sut's hasAlert())

	if caseIndex is 1 then
		sut's newTab("https://www.google.com/search?q=translate+german+to+english")

	else if caseIndex is 2 then
		(* Prepare a test tab, then close it.*)
		logger's info("Close the test tab.")
		delay 8

		logger's infof("Title after closing: {}", sut's getTitle())
		logger's infof("Has alert: {}", sut's hasAlert())
		logger's infof("Name: {}", sut's getWindowName())
		logger's infof("Window ID: {}", sut's getWindowID())

	else if caseIndex is 3 then
		sut's moveTabToIndex(5)

	else if caseIndex is 4 then
		sut's runScript("alert('Hello')")

	end if

	activate

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

	script operaTabInstance
		property appWindow : missing value -- app window, not syseve window.
		property maxTryTimes : 60
		property sleepSec : 1
		property closeOtherTabsOnFocus : false
		property tabIndex : pTabIndex
		-- property safari : pSafari

		property _tab : missing value
		property _url : missing value


		on moveTabToIndex(newIndex)
			if running of application "Opera" is false then return

			tell application "Opera"
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
				set active tab of front window to my _tab
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

		on hasAlert()
			tell application "System Events" to tell process "Opera" to tell my getSystemEventsWindow()
				try
					button "Close" of group 1 of tab group 1 of splitter group 1 exists
				on error
					false
				end try
			end tell
		end hasAlert

		on dismissAlert()
			tell application "System Events" to tell process "Opera" to tell my getSystemEventsWindow()
				try
					(click button "Close" of group 1 of tab group 1 of splitter group 1) exists
				end try
			end tell
		end dismissAlert

		(* Creates a new tab at the end of the window (not next to the tab) *)
		on newTab(targetUrl)
			tell application "Opera"
				tell front window
					set newTab to make new tab at end of tabs
					set URL of newTab to targetUrl
					set activeTabIndex to the active tab index of appWindow
				end tell
			end tell

			tell application "Opera"
				-- tell my appWindow to set active tab to (make new tab with properties {URL:targetUrl})
				-- set miniaturized of appWindow to false
				-- set tabTotal to count of tabs of appWindow
			end tell

			-- set newInstance to new(windowId, tabTotal, safari)
			set newInstance to new(windowId, activeTabIndex)
			set _url of newInstance to targetUrl
			the newInstance
		end newTab


		(* It checks the starting characters to match because Safari trims it in the menu when then name is more than 30 characters. *)
		on focus()
			tell application "Opera" to set active tab of my appWindow to _tab
		end focus

		on closeTab()
			tell application "Opera" to close _tab
		end closeTab

		on closeWindow()
			tell application "Opera" to close my appWindow()
		end closeWindow

		on reload()
			focus()
			tell application "Opera"
				set currentUrl to URL of my getDocument()
				set URL of my getDocument() to currentUrl
			end tell
			delay 0.01
		end reload

		on waitForPageToLoad()
			waitForPageLoad()
		end waitForPageToLoad

		on waitForPageLoad()
			script LoadingWaiter
				tell application "Opera"
					if my getWindowName() is equal to "Failed to open page" then return "failed"
					return loading of active tab of front window is false
				end tell
			end script
			exec of retry on result for maxTryTimes by sleepSec
		end waitForPageLoad


		on isDocumentLoading()
			tell application "Opera"
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
			tell application "Opera"
				try
					return (source of my getDocument()) as text
				end try
			end tell

			missing value
		end getSource

		on getURL()
			tell application "Opera"
				try
					return URL of my getDocument()
				end try
			end tell

			missing value
		end getURL

		on getAddressBarValue()
			if hasToolBar() is false then return missing value

			tell application "System Events" to tell process "Opera"
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

				-- tell application "Opera" to set URL of document (name of my appWindow) to targetUrl
				tell application "Opera" to set URL of my getDocument() to targetUrl
				true
			end script
			exec of retry on result for 2
			delay 0.1 -- to give waitForPageLoad ample time to enter a loading state.
		end goto


		(* Note: Will dismiss the prompt of the*)
		on dismissPasswordSavePrompt()
			focus()
			script PasswordPrompt
				tell application "System Events" to tell process "Opera"
					click button "Not Now" of sheet 1 of front window
					-- we need system event window, appWindow is app Safari window so it would not work here.
					true
				end tell
			end script
			exec of retry on result for 5 -- let's try click it 5 times, ignoring outcomes.
		end dismissPasswordSavePrompt


		on getWindowID()
			try
				return id of appWindow
			end try
			0
		end getWindowID

		on getWindowName()
			try
				return name of appWindow
			end try
			missing value
		end getWindowName


		on getSystemEventsWindow()
			tell application "System Events" to tell process "Opera"
				try
					return first window whose name is equal to (name of appWindow)
				end try
			end tell
			missing value
		end getSystemEventsWindow

		on getHtmlUI()
			tell application "System Events" to tell process "Opera"
				first UI element of group 1 of group 1 of group 1 of group 1 of front window whose role description is "HTML Content"
			end tell
		end getHtmlUI
	end script

	tell application "Opera"
		set appWindow of operaTabInstance to window id windowId
		set _url of operaTabInstance to URL of active tab of window id windowId
		set _tab of operaTabInstance to item pTabIndex of tabs of appWindow of operaTabInstance
	end tell

	operaJavaScript's decorate(operaTabInstance)
end new
