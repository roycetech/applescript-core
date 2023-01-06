global std, retry, regex, dock, winUtil

(*
	This script library is a wrapper to Safari application.

	@Installation:
		

	This library creates 2 instances:
		SafariInstance - this library
		SafariTabInstance - wrapper to a Safari tab.

	Debugging existing tab:
		set std to script "std"
		set logger to std's import("logger")'s new("adhoc")

		set safari to std's import("safari")'s new()
		set javascriptSupport of safTabLib to true

		set theTab to safTabLib's getFrontTab()
		tell theTab
			log name of its theWindow as text
			return
			setValueById("comment_msn_description", "you
			
		13")
		end tell
*)

use script "Core Text Utilities"
use scripting additions

property initialized : false
property logger : missing value

property javaScriptSupport : false
property jQuerySupport : false

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "safari-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Manual: Front Tab
		Manual: First Tab
		Manual: New Window
		
		Manual: Find Tab With Name ()
		New Window
		New Tab - Manually Check when no window is present in current space.
		
		Open in Cognito
		Get Tab by Window ID - Manual
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
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
		
		set frontTab to sut's getFrontTab()
		if frontTab is missing value then
			logger's info("A front tab was not found")
		else
			logger's infof("URL: {}", frontTab's getURL())
			logger's infof("URL Class: {}", class of frontTab's getURL())
			logger's infof("Has Toolbar: {}", frontTab's hasToolBar())
			logger's infof("Address Bar Value: {}", frontTab's getAddressBarValue())
			logger's infof("Title: {}", frontTab's getTitle())
			logger's infof("Window Name: {}", frontTab's getWindowName())
			logger's infof("Window ID: {}", frontTab's getWindowId())
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
		sut's newWindow("https://www.example.com")
		
		
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
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	script SafariInstance
		(* 
			@return  missing value of tab if not found, else a SafariTabInstance .
		*)
		on findTabWithName(targetName)
			tell application "Safari"
				repeat with nextWindow in windows
					try
						set matchedTab to (first tab of nextWindow whose name is equal to targetName)
						return my _new(id of nextWindow, index of matchedTab as integer)
					end try
				end repeat
			end tell
			return missing value
		end findTabWithName
		
		
		(* @return  missing value of tab is not found. TabInstance *)
		on findTabStartingWithName(targetName)
			tell application "Safari"
				repeat with nextWindow in windows
					try
						set matchedTab to (first tab of nextWindow whose name starts with targetName)
						return my _new(id of nextWindow, index of matchedTab as integer)
					end try
				end repeat
			end tell
			missing value
		end findTabStartingWithName
		
		
		(* @return  missing value of tab is not found. TabInstance *)
		on findTabContainingInName(nameSubstring)
			tell application "Safari"
				repeat with nextWindow in windows
					try
						set matchedTab to (first tab of nextWindow whose name contains nameSubstring)
						return my _new(id of nextWindow, index of matchedTab as integer)
					end try
				end repeat
			end tell
			return missing value
		end findTabContainingInName
		
		
		(* @return  missing value of tab is not found. TabInstance *)
		on findTabEndingWithName(targetName)
			tell application "Safari"
				repeat with nextWindow in windows
					try
						set matchedTab to (first tab of nextWindow whose name ends with targetName)
						return my _new(id of nextWindow, index of matchedTab as integer)
					end try
				end repeat
			end tell
			missing value
		end findTabEndingWithName
		
		
		(* @return  missing value of tab is not found. *)
		on findTabWithUrl(targetUrl)
			tell application "Safari"
				repeat with nextWindow in windows
					try
						set matchedTab to (first tab of nextWindow whose URL is equal to the targetUrl)
						return my _new(id of nextWindow, index of matchedTab as integer)
					end try
				end repeat
			end tell
			missing value
		end findTabWithUrl
		
		
		(* @return  missing value of tab is not found. *)
		on findTabStartingWithUrl(urlPrefix)
			if urlPrefix does not start with "http" then set urlPrefix to "https://" & urlPrefix
			
			tell application "Safari"
				repeat with nextWindow in windows
					try
						set matchedTab to (first tab of nextWindow whose URL starts with urlPrefix)
						return my _new(id of nextWindow, index of matchedTab as integer)
					end try
				end repeat
			end tell
			missing value
		end findTabStartingWithUrl
		
		
		(* 
			@return  missing value of tab is not found. 
		*)
		on findTabWithUrlContaining(urlSubstring)
			tell application "Safari"
				repeat with nextWindow in windows
					try
						set matchedTab to (first tab of nextWindow whose URL contains urlSubstring)
						return my _new(id of nextWindow, index of matchedTab as integer)
					end try
				end repeat
			end tell
			missing value
		end findTabWithUrlContaining
		
		
		on getFrontTab()
			if not winUtil's hasWindow("Safari") then return missing value
			
			tell application "Safari" to tell first window
				my _new(its id, index of current tab)
			end tell
		end getFrontTab
		
		
		(* Gets the first tab across spaces. NOTE: This may not be the user expected front window so use this handler with care. *)
		on getFirstTab()
			if running of application "Safari" is false then return missing value
			
			tell application "Safari"
				if (count of windows) is 0 then return missing value
				
				tell first window
					my _new(its id, index of current tab)
				end tell
			end tell
		end getFirstTab
		
		
		(* 
			TODO: Test for when Safari is not running. 
			This is dependent on the user setting for new window/tabs, currently it is tested against when new window is on a "Start Page"
		*)
		on newWindow(targetUrl)
			(*
	if running of application "Safari" is false then
		do shell script (format {"open -a Safari {}", theUrl})
		
		script WindowWaiter
			if (count of (windows of application "Safari")) is not 0 then return true
		end script
		exec of retry on result
	else
		tell application "Safari" to make new document with properties {URL:theUrl}
	end if
*)
			
			set safariAppRunning to running of application "Safari"
			tell application "System Events" to tell process "Safari"
				if (not safariAppRunning) or not (exists window "Start Page") then
					dock's newSafariWindow()
				end if
			end tell
			
			script StartPageWaiter
				-- tell application "Safari" to set windowId to id of window "Start Page" -- New window will not always start with "Start Page"
				tell application "Safari" to set windowId to id of front window
				windowId
			end script
			set windowId to exec of retry on result for 3
			
			set newSafariTabInstance to _new(windowId, 1)
			newSafariTabInstance's focus()
			
			script Resilient
				tell application "Safari" to set URL of front document to targetUrl -- can't avoid focusing the address bar for fresh pages.
				true
			end script
			exec of retry on result for 3
			
			newSafariTabInstance
		end newWindow
		
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
			
			main's focusWindowWithToolbar()
			
			-- logger's debugf("theUrl: {}", theUrl)
			tell application "Safari"
				set theWindow to first window
				tell theWindow to set current tab to (make new tab with properties {URL:theUrl})
				set miniaturized of theWindow to false
				set tabTotal to count of tabs of theWindow
				
				(* Safari 15 Fix to intermittent loading bug. *)
				(* 
		script BugWaiter
			tell document of theWindow
				if its name is "Start Page" then return missing value

				if its name is not "Untitled" then return true
				
				if its source is not "" then return true 
			end tell
		end script
		set waitResult to waiter's exec on result for 3
		if waitResult is missing value then set URL of document of theWindow to theUrl
		*)
			end tell
			
			_new(id of theWindow, tabTotal)
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
			_new(windowId, 1)
		end newCognito
		
		
		-- Private Codes below =======================================================
		(*
			@windowId app window ID
			@pTabIndex the Safari tab index
		*)
		on _new(windowId, pTabIndex)
			-- logger's debugf("Window ID: {}, TabIndex: {}", {windowId, pTabIndex}) -- wished the name or the url can be included in the log, not easy to do.
			
			script SafariTabInstance
				property appWindow : missing value -- app window, not syseve window.
				property maxTryTimes : 60
				property sleepSec : 1
				property closeOtherTabsOnFocus : false
				property tabIndex : pTabIndex
				
				property _tab : missing value
				property _url : missing value
				
				on getTitle()
					name of appWindow
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
					tell application "System Events" to tell process "Safari" to tell getSysEveWindow()
						try
							button "Close" of group 1 of tab group 1 of splitter group 1 exists
						on error
							false
						end try
					end tell
				end hasAlert
				
				on dismissAlert()
					tell application "System Events" to tell process "Safari" to tell getSysEveWindow()
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
					
					set newInstance to _new(windowId, tabTotal)
					set _url of newInstance to targetUrl
					the newInstance
				end newTab
				
				(* It checks the starting characters to match because Safari trims it in the menu when then name is more than 30 characters. *)
				on focus()
					tell application "Safari" to set current tab of my appWindow to _tab
				end focus
				
				on closeTab()
					tell application "Safari" to close _tab
				end closeTab
				
				to closeWindow()
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
					script retry
						
						-- tell application "Safari" to set URL of document (name of my theWindow) to targetUrl
						tell application "Safari" to set URL of my getDocument() to targetUrl
						true
					end script
					exec of retry on retry for 2
					delay 0.1 -- to give waitForPageLoad ample time to enter a loading state.
				end goto
				
				
				(* Note: Will dismiss the prompt of the*)
				on dismissPasswordSavePrompt()
					focus()
					script PasswordPrompt
						tell application "System Events" to tell process "Safari"
							click button "Not Now" of sheet 1 of front window
							-- we need system event window, theWindow is app Safari window so it would not work here.
							true
						end tell
					end script
					exec of retry on result for 5 -- let's try click it 5 times, ignoring outcomes.
				end dismissPasswordSavePrompt
				
				on extractUrlParam(paramName)
					tell application "Safari" to set theUrl to URL of my getDocument()
					set pattern to format {"(?<={}=)\\w+", paramName}
					set matchedString to regex's findFirst(theUrl, pattern)
					if matchedString is "nil" then return missing value
					
					matchedString
				end extractUrlParam
				
				
				on getWindowId()
					id of appWindow
				end getWindowId
				
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
			set theInstance to SafariTabInstance
			
			if javaScriptSupport then
				set js_tab to std's import("javascript-next")
				set theInstance to js_tab's newInstance(theInstance)
			end if
			
			if jQuerySupport then
				set jq to std's import("jquery")
				set theInstance to jq's newInstance(theInstance)
			end if
			
			theInstance
		end _new
	end script
end new


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("safari")
	set retry to std's import("retry")'s new()
	set regex to std's import("regex")
	set dock to std's import("dock")'s new()
	set winUtil to std's import("window")'s new()
end init