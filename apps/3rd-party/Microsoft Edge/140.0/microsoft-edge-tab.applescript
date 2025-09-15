(*
	Retrofitted from chrome-tab.applescript.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Microsoft Edge/140.0/microsoft-edge-tab'

	@Created: December 31, 2023 4:22 PM
	@Last Modified: 2023-12-27 10:41:51
*)

use scripting additions

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"
use microsoftEdgeJavaScript : script "core/microsoft-edge-javascript"
use javascript : script "core/javascript"
use decoratorLib : script "core/decorator"

property logger : missing value
property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Open Google Translate
		Manual: Closed Tab
		Manual: Move tab to index
		Manual: Run a Script
		
		Manual: Reload
		Manual: Goto
		Dummy
		Dummy
		Dummy
	")
	
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	tell application "Microsoft Edge"
		tell front window
			set sut to my new(its id, active tab index)
			
		end tell
	end tell
	
	logger's infof("Title: {}", sut's getTitle())
	logger's infof("URL: {}", sut's getURL())
	logger's infof("Name: {}", sut's getWindowName())
	logger's infof("Window ID: {}", sut's getWindowID())
	logger's infof("Has alert: {}", sut's hasAlert())
	logger's infof("Is loading: {}", sut's isDocumentLoading())
	log "Source: " & sut's getSource() -- Comment out to reduce clutter.
	
	if caseIndex is 2 then
		sut's newTab("https://www.google.com/search?q=translate+german+to+english")
		
	else if caseIndex is 3 then
		(* Prepare a test tab, then close it.*)
		logger's info("Close the test tab.")
		delay 8
		
		logger's infof("Title after closing: {}", sut's getTitle())
		logger's infof("Has alert: {}", sut's hasAlert())
		logger's infof("Name: {}", sut's getWindowName())
		logger's infof("Window ID: {}", sut's getWindowID())
		
	else if caseIndex is 4 then
		sut's moveTabToIndex(5)
		
	else if caseIndex is 5 then
		sut's runScript("alert('Hello')")
		
	else if caseIndex is 6 then
		sut's reload()
		
	else if caseIndex is 7 then
		sut's goto("https://www.apple.com")
		
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
	
	script MicrosoftEdgeTabInstance
		property appWindow : missing value -- app window, not syseve window.
		property maxTryTimes : 60
		property sleepSec : 1
		property closeOtherTabsOnFocus : false
		property tabIndex : pTabIndex
		-- property safari : pSafari
		
		property _tab : missing value
		property _tabIndex : pTabIndex
		property _url : missing value
		
		
		on moveTabToIndex(newIndex)
			if running of application "Microsoft Edge" is false then return
			
			tell application "Microsoft Edge"
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
			tell application "System Events" to tell process "Microsoft Edge" to tell my getSystemEventsWindow()
				try
					button "Close" of group 1 of tab group 1 of splitter group 1 exists
				on error
					false
				end try
			end tell
		end hasAlert
		
		on dismissAlert()
			tell application "System Events" to tell process "Microsoft Edge" to tell my getSystemEventsWindow()
				try
					(click button "Close" of group 1 of tab group 1 of splitter group 1) exists
				end try
			end tell
		end dismissAlert
		
		(* Creates a new tab at the end of the window (not next to the tab) *)
		on newTab(targetUrl)
			tell application "Microsoft Edge"
				tell front window
					set newTab to make new tab at end of tabs
					set URL of newTab to targetUrl
					set activeTabIndex to the active tab index of appWindow
				end tell
			end tell
			
			tell application "Microsoft Edge"
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
			tell application "Microsoft Edge" to set active tab index of my appWindow to _tabIndex
		end focus
		
		on closeTab()
			tell application "Microsoft Edge" to close _tab
		end closeTab
		
		on closeWindow()
			tell application "Microsoft Edge" to close my appWindow()
		end closeWindow
		
		on reload()
			focus()
			tell application "Microsoft Edge"
				reload _tab
			end tell
			
			delay 0.01
		end reload
		
		on waitForPageToLoad()
			waitForPageLoad()
		end waitForPageToLoad
		
		on waitForPageLoad()
			script LoadingWaiter
				tell application "Microsoft Edge"
					if my getWindowName() is equal to "Failed to open page" then return "failed"
					return loading of active tab of front window is false
				end tell
			end script
			exec of retry on result for maxTryTimes by sleepSec
		end waitForPageLoad
		
		
		on isDocumentLoading()
			tell application "Microsoft Edge"
				if my getWindowName() is equal to "Failed to open page" then return false
				return loading of active tab of front window
			end tell
		end isDocumentLoading
		
		
		on waitInSource(substring)
			script SubstringWaiter
				if getSource() contains substring then return true
			end script
			exec of retry on result for maxTryTimes by sleepSec
		end waitInSource
		
		
		on getSource()
			tell application "Microsoft Edge"
				set tabObj to my _tab
				set pageHTML to execute tabObj javascript "document.documentElement.outerHTML"
			end tell
		end getSource
		
		
		on getURL()
			tell application "Microsoft Edge"
				try
					return URL of my _tab
				end try
			end tell
			
			missing value
		end getURL
		
		on getAddressBarValue()
			if hasToolBar() is false then return missing value
			
			tell application "System Events" to tell process "Microsoft Edge"
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
				tell application "Microsoft Edge" to set URL of my _tab to targetUrl
				true
			end script
			exec of retry on result for 2
			delay 0.1 -- to give waitForPageLoad ample time to enter a loading state.
		end goto
		
		
		(* Note: Will dismiss the prompt of the*)
		on dismissPasswordSavePrompt()
			focus()
			script PasswordPrompt
				tell application "System Events" to tell process "Microsoft Edge"
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
			tell application "System Events" to tell process "Microsoft Edge"
				try
					return first window whose name is equal to (name of appWindow)
				end try
			end tell
			missing value
		end getSystemEventsWindow
	end script
	
	tell application "Microsoft Edge"
		set appWindow of MicrosoftEdgeTabInstance to window id windowId
		set _url of MicrosoftEdgeTabInstance to URL of active tab of window id windowId
		set _tab of MicrosoftEdgeTabInstance to item pTabIndex of tabs of appWindow of MicrosoftEdgeTabInstance
	end tell
	
	microsoftEdgeJavaScript's decorate(MicrosoftEdgeTabInstance)
	javascript's decorate(result)
	
	set decorator to decoratorLib's new(result)
	decorator's decorateByName("MicrosoftEdgeTabInstance")
	
end new
