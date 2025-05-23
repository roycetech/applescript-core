(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Google Chrome/136.0/google-chrome-tab'

	@TODO: 
		Mon, Sep 30, 2024 at 10:46:55 AM - Review all handlers and verify they are converted to work with Google Chrome.
		
	@Created: Fri, Jan 17, 2025 at 9:30:20 AM
	@Last Modified: 2023-12-27 10:41:51
	
	@Change Logs:
		Fri, Jan 17, 2025 at 9:30:32 AM - Fix getURL to get the indexed URL, not the active tab.
*)

use scripting additions

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"

property logger : missing value
property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		INFO:
		Manual: Open Google Translate
		Manual: Closed Tab
		Manual: Move tab to index
		Manual: Run a Script
		
		Manual: Switch Tab
		Manual: Debug: getURL
		Manual: Reload
	")
	
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	tell application "Google Chrome"
		tell front window
			set sut to my new(its id, active tab index)
			
		end tell
	end tell
	
	logger's infof("Title: {}", sut's getTitle())
	logger's infof("Name: {}", sut's getWindowName())
	logger's infof("URL: {}", sut's getURL())
	logger's infof("Tab Index: {}", sut's getTabIndex())
	logger's infof("Window ID: {}", sut's getWindowID())
	logger's infof("Has alert: {}", sut's hasAlert())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
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
		set sutNewTabIndex to 1
		-- set sutNewTabIndex to 2
		-- set sutNewTabIndex to 3
		-- set sutNewTabIndex to 7 -- last
		logger's infof("sutNewTabIndex: {}", sutNewTabIndex)
		
		sut's moveTabToIndex(sutNewTabIndex)
		
	else if caseIndex is 5 then
		sut's runScript("alert('Hello')")
		
	else if caseIndex is 6 then
		sut's focusTabIndex(99)
		-- sut's focusTabIndex(2)
		
	else if caseIndex is 7 then
		set googleChromeLib to script "core/google-chrome"
		set googleChrome to googleChromeLib's new()
		
		tell application "Google Chrome"
			if (count of tabs of front window) is less than 2 then
				error "You need to have at least 2 tabs to test this."
			end if
			
			googleChrome's focusTabIndex(1)
			
			tell front window
				set sut to my new(its id, 1)
			end tell
			
			googleChrome's focusTabIndex(2)
			delay 1
			
			-- 			log sut's tabIndex
			logger's infof("Handler result: {} ", sut's getURL())
			
		end tell
		
	else if caseIndex is 8 then
		sut's reload()
		
	end if
	
	activate
	
	spot's finish()
	logger's finish()
end spotCheck


(*
	@windowId app window ID
	@pTabIndex the browser tab index
*)
on new(windowId, pTabIndex)
	-- on new(windowId, pTabIndex, pSafari)
	loggerFactory's inject(me)
	
	set retry to retryLib's new()
	
	-- logger's debugf("Window ID: {}, TabIndex: {}", {windowId, pTabIndex}) -- wished the name or the url can be included in the log, not easy to do.
	
	script GoogleChromeTabInstance
		property appWindow : missing value -- app window, not syseve window.
		property maxTryTimes : 60
		property sleepSec : 1
		property tabIndex : pTabIndex
		property waitSecondsAfterPageLoad : 0
		
		property _tab : missing value
		property _url : missing value
		
		(*
			Test Cases:
				Move 1 to 2 - ok
				Move 1 to 3 - ok
				Move 1 to Last
				Move 3 to 2
				Move 3 to 1
			@newIndex - starts at 1.
		*)
		on moveTabToIndex(newIndex)			
			if running of application "Google Chrome" is false then return
			if newIndex is equal to my tabIndex then
				logger's debug("Same spot")
				return
			end if
			
			tell application "Google Chrome"
				set tabCount to (count of tabs in front window)
				set sourceTabIndex to my tabIndex -- the index of the tab you want to move
				logger's debugf("sourceTabIndex: {}", sourceTabIndex)
				
				set targetTabIndex to newIndex -- the index where you want to move the tab				
				logger's debugf("targetTabIndex: {}", targetTabIndex)
				
				set urlOfTabToMove to URL of tab sourceTabIndex of front window
				
				set isSwapTabRight to targetTabIndex - sourceTabIndex is 1
				set isMoveTabLeft to sourceTabIndex - targetTabIndex is greater than 0
				set isMoveTabRight to not isMoveTabLeft
				
				if (sourceTabIndex > tabCount) or (targetTabIndex > tabCount) then
					display dialog "Invalid tab index."
					
				else if targetTabIndex - sourceTabIndex is 1 then
					move tab sourceTabIndex of front window to before tab (targetTabIndex + 1) of front window
					delay 0.1 -- Fails without this.
					
					log "swap tab right"
					
				else if isMoveTabLeft then
					move tab sourceTabIndex of front window to before tab targetTabIndex of front window
					delay 0.1
					
					log "move tab left"
				else
					move tab sourceTabIndex of front window to after tab targetTabIndex of front window
					delay 0.1
					log "move tab right"
				end if
				
				set URL of tab targetTabIndex of front window to urlOfTabToMove
				set my tabIndex to newIndex
				set my _tab to tab newIndex of front window
				set active tab index of front window to my tabIndex
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
			tell application "System Events" to tell process "Google Chrome" to tell my getSystemEventsWindow()
				try
					button "Close" of group 1 of tab group 1 of splitter group 1 exists
				on error
					false
				end try
			end tell
		end hasAlert
		
		on dismissAlert()
			tell application "System Events" to tell process "Google Chrome" to tell my getSystemEventsWindow()
				try
					(click button "Close" of group 1 of tab group 1 of splitter group 1) exists
				end try
			end tell
		end dismissAlert
		
		(* Creates a new tab at the end of the window (not next to the tab) *)
		on newTab(targetUrl)
			tell application "Google Chrome"
				tell front window
					set newTab to make new tab at end of tabs
					set URL of newTab to targetUrl
					set activeTabIndex to the active tab index of appWindow
				end tell
			end tell
			
			tell application "Google Chrome"
				-- tell my appWindow to set active tab to (make new tab with properties {URL:targetUrl})
				-- set miniaturized of appWindow to false
				-- set tabTotal to count of tabs of appWindow
			end tell
			
			-- set newInstance to new(windowId, tabTotal, safari)
			set newInstance to new(windowId, activeTabIndex)
			set _url of newInstance to targetUrl
			the newInstance
		end newTab
		
		(*
		on focus()
			tell application "Google Chrome" to set active tab of my appWindow to my _tab
		end focus
		*)
		on focus()
			tell application "Google Chrome"
				set active tab index of my appWindow to my tabIndex
			end tell
		end focus
		
		on closeTab()
			tell application "Google Chrome" to close _tab
		end closeTab
		
		on closeWindow()
			tell application "Google Chrome" to close my appWindow()
		end closeWindow
		
		on reload()
			focus()
			tell application "Google Chrome"
				set currentUrl to URL of my _tab
				set URL of my _tab to currentUrl
			end tell
			delay 0.01
		end reload
		
		on waitForPageToLoad()
			waitForPageLoad()
		end waitForPageToLoad
		
		on waitForPageLoad()
			script LoadingWaiter
				tell application "Google Chrome"
					if my getWindowName() is equal to "Failed to open page" then return "failed"
					return loading of active tab of front window is false
				end tell
			end script
			exec of retry on result for maxTryTimes by sleepSec
			delay waitSecondsAfterPageLoad
		end waitForPageLoad
		
		
		on isDocumentLoading()
			tell application "Google Chrome"
				if my getWindowName() is equal to "Failed to open page" then return false
				if source of my _tab is not "" then return true
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
			tell application "Google Chrome"
				try
					return (source of my _tab) as text
				end try
			end tell
			
			missing value
		end getSource
		
		on getURL()
			tell application "Google Chrome"
				try
					return URL of my _tab
				end try
			end tell
			
			missing value
		end getURL
		
		
		on getAddressBarValue()
			if hasToolBar() is false then return missing value
			
			tell application "System Events" to tell process "Google Chrome"
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
				tell application "Google Chrome" to set URL of my _tab to targetUrl
				true
			end script
			exec of retry on result for 2
			delay 0.1 -- to give waitForPageLoad ample time to enter a loading state.
		end goto
		
		
		(* Note: Will dismiss the prompt of the*)
		on dismissPasswordSavePrompt()
			focus()
			script PasswordPrompt
				tell application "System Events" to tell process "Google Chrome"
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
			tell application "System Events" to tell process "Google Chrome"
				try
					return first window whose name is equal to (name of appWindow)
				end try
			end tell
			missing value
		end getSystemEventsWindow
		
		on getHtmlUI()
			tell application "System Events" to tell process "Google Chrome"
				first UI element of group 1 of group 1 of group 1 of group 1 of front window whose role description is "HTML Content"
			end tell
		end getHtmlUI
	end script
	
	tell application "Google Chrome"
		set appWindow of GoogleChromeTabInstance to window id windowId
		-- 		set _url of GoogleChromeTabInstance to URL of active tab of window id windowId
		set _url of GoogleChromeTabInstance to URL of item pTabIndex of tabs of window id windowId
		set _tab of GoogleChromeTabInstance to item pTabIndex of tabs of appWindow of GoogleChromeTabInstance
	end tell
	
	set googleChromeJavaScript to script "core/google-chrome-javascript"
	googleChromeJavaScript's decorate(GoogleChromeTabInstance)
end new
