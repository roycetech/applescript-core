(*
	This script library is a wrapper to Safari Technology Preview application.
	Copied from safari.applescript
	

	@Prerequisites
		This library is designed initially to handle when new windows are opened 
		with Start Page. To support other configurations.
		You may need to re-toggle on/off the use of Touch ID for auto filling passwords.
		It is expected that Touch ID is disabled for auto filling passwords.

	@Installation:
		
	This library creates 2 instances:
		SafariInstance - this library
		SafariTechnologyPreviewTabInstance - wrapper to a Safari tab.

	Debugging existing tab:
		use loggerLib : script "core/logger"
		use safariTechPreviewLib : script "core/safari-technology-preview"
		
		property logger : loggerLib's new("ad hoc")
		property safariTechPreview : safariTechPreviewLib's new()
		set theTab to safariTechPreview's getFrontTab()
		tell theTab
			log name of its appWindow as text
			return
			setValueById("comment_msn_description", "you
			
		13")
		end tell

	@Last Modified: July 5, 2023 3:53 PM
*)

use script "core/Text Utilities"
use scripting additions

use textUtil : script "core/string"
use listUtil : script "core/list"
use regex : script "core/regex"
use unic : script "core/unicodes"
use safariJavaScript : script "core/safari-javascript"
use jsSafariTechPreviewDecorator : script "core/dec-safari-technology-preview-javascript"

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"
use dockLib : script "core/dock"
use kbLib : script "core/keyboard"
use uiutilLib : script "core/ui-util"
use winUtilLib : script "core/window"

use spotScript : script "core/spot-test"

property logger : missing value
property retry : missing value
property dock : missing value
property kb : missing value
property uiutil : missing value
property winUtil : missing value

property javaScriptSupport : false
property jQuerySupport : false

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: Front Tab
		Manual: First Tab		
		Manual: Show Side Bar (Visible,Hidden)
		Manual: Close Side Bar (Visible,Hidden)		
		Manual: Get Group Name(default, group selected)
		
		Manual: Switch Group(not found, found)
		Manual: New Window
		Manual: Find Tab With Name ()
		New Tab - Manually Check when no window is present in current space.
		Open in Cognito
		
		Get Tab by Window ID - Manual
		Manual: Address Bar is Focused
		Manual: Select OTP
	")
	
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
		
		activate application "Safari Technology Preview"
		delay 1
		
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
			logger's infof("Sidebar Visible: {}", sut's isSideBarVisible())
			logger's infof("Is Loading: {}", sut's isLoading())
			
			delay 3 -- Manually check below when in/visible.
			logger's infof("Address Bar is focused: {}", frontTab's isAddressBarFocused())
			logger's infof("Keychain Form Visible: {}", sut's isKeychainFormVisible())
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
		logger's info("Passed.")
		
	else if caseIndex is 4 then
		sut's closeSideBar()
		assertThat of std given condition:sut's isSideBarVisible() is false, messageOnFail:"Failed spot check"
		logger's info("Passed.")
		
	else if caseIndex is 5 then
		logger's infof("Current Group Name: {}", sut's getGroupName())
		
	else if caseIndex is 6 then
		-- sut's switchGroup("Unicorn") -- not found
		sut's switchGroup("Music")
		
	else if caseIndex is 7 then
		sut's newWindow("https://www.example.com")
		log name of appWindow of result as text
		
		-- BELOW FOR REVIEW.
		
	else if caseIndex is 3 then
		
		
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
		
	else if caseIndex is 8 then
		sut's newWindow("https://www.example.com")
		
		
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
		activate application "Safari Technology Preview"
		set adhocCredKey to "core.keychain" -- DO NOT COMMIT!
		sut's selectKeychainItem(adhocCredKey)
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's injectBasic(me)

	set retry to retryLib's new()
	set dock to dockLib's new()
	set kb to kbLib's new()
	set uiutil to uiutilLib's new()
	set winUtil to winUtilLib's new()

	script SafariTechnologyPreviewInstance
		on isLoading()
			if running of application "Safari Technology Preview" is false then return false
			
			(*
				-- For testing
				activate application "Safari Technology Preview"
				kb's pressCommandKey("r")
			*)
			tell application "System Events" to tell process "Safari Technology Preview"
				try
					return exists (first button of (my _getAddressBarGroup()) whose description is "Stop loading this page")
				end try
			end tell
			
			false
		end isLoading
		
		on selectKeychainItem(itemName)
			if running of application "Safari Technology Preview" is false then return
			
			logger's debugf("itemName: {}", itemName)
			
			set itemIndex to 0
			tell application "System Events" to tell process "Safari Technology Preview"
				repeat with nextRow in rows of table 1 of scroll area 1
					set itemIndex to itemIndex + 1
					if value of static text 1 of UI element 1 of nextRow is equal to itemName then
						repeat itemIndex times
							kb's pressKey("down")
						end repeat
						kb's pressKey("enter")
						return
					end if
				end repeat
			end tell
		end selectKeychainItem
		
		on isKeychainFormVisible()
			tell application "System Events" to tell process "Safari Technology Preview"
				exists (scroll area 1)
			end tell
		end isKeychainFormVisible
		
		(* Slow operation, 3s. *)
		on isAddressBarFocused()
			if running of application "Safari Technology Preview" is false then return missing value
			
			tell application "System Events" to tell process "Safari Technology Preview"
				value of attribute "AXSelectedText" of text field 1 of (my _getAddressBarGroup()) is not missing value
				-- value of attribute "AXSelectedText" of text field 1 of group 6 of toolbar 1 of front window is not missing value
				
			end tell
		end isAddressBarFocused
		
		
		on getGroupName()
			if running of application "Safari Technology Preview" is false then return missing value
			
			tell application "System Events" to tell process "Safari Technology Preview"
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
			
			tell application "System Events" to tell process "Safari Technology Preview"
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
		
		
		on showSideBar()
			if running of application "Safari Technology Preview" is false then return
			tell application "System Events" to tell process "Safari Technology Preview"
				if (count of windows) is 0 then return
			end tell
			if isSideBarVisible() then return
			
			tell application "System Events" to tell application process "Safari Technology Preview"
				set groupOneButtons to buttons of group 1 of toolbar 1 of front window
			end tell
			
			set sideBarButton to uiutil's new(groupOneButtons)'s findById("SidebarButton")
			tell application "System Events" to click sideBarButton
		end showSideBar
		
		
		on closeSideBar()
			if not isSideBarVisible() then return return
			
			if running of application "Safari Technology Preview" is false then return
			
			tell application "System Events" to tell process "Safari Technology Preview"
				if (count of windows) is 0 then return
			end tell
			
			tell application "System Events" to tell application process "Safari Technology Preview"
				set groupOneButtons to buttons of group 1 of toolbar 1 of front window
			end tell
			
			set sideBarButton to uiutil's new(groupOneButtons)'s findById("SidebarButton")
			script CloseWaiter
				tell application "System Events" to click sideBarButton
				if isSideBarVisible() is false then return true
			end script
			exec of retry on result for 3
		end closeSideBar
		
		
		on isSideBarVisible()
			if running of application "Safari Technology Preview" is false then return false
			
			tell application "System Events" to tell process "Safari Technology Preview"
				try
					return get value of attribute "AXIdentifier" of menu button 1 of group 1 of toolbar 1 of window 1 is "NewTabGroupButton"
				end try
			end tell
			false
		end isSideBarVisible
		
		
		(*
			@requires app focus.
		*)
		on switchGroup(groupName)
			if running of application "Safari Technology Preview" is false then
				activate application "Safari Technology Preview"
			end if
			
			set sideBarWasVisible to isSideBarVisible()
			closeSideBar()
			
			script ToolBarWaiter
				tell application "System Events" to tell process "Safari Technology Preview"
					click menu button 1 of group 1 of toolbar 1 of window 1
				end tell
				true
			end script
			set waitResult to exec of retry on result for 3
			logger's debugf("WaitResult: {}", waitResult)
			
			tell application "System Events" to tell process "Safari Technology Preview"
				try
					click menu item groupName of menu 1 of group 1 of toolbar 1 of window 1
				on error
					logger's warnf("Group: {} was not found", groupName)
					kb's pressKey("esc")
				end try
			end tell
			
			if sideBarWasVisible then showSideBar()
		end switchGroup
		
		
		(* 
			@return  missing value of tab if not found, else a SafariTechnologyPreviewTabInstance .
		*)
		on findTabWithName(targetName)
			tell application "Safari Technology Preview"
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
			tell application "Safari Technology Preview"
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
			tell application "Safari Technology Preview"
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
			tell application "Safari Technology Preview"
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
			tell application "Safari Technology Preview"
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
			
			tell application "Safari Technology Preview"
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
			tell application "Safari Technology Preview"
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
			if not winUtil's hasWindow("Safari Technology Preview") then return missing value
			
			tell application "Safari Technology Preview" to tell first window
				my _new(its id, index of current tab)
			end tell
		end getFrontTab
		
		
		(* Gets the first tab across spaces. NOTE: This may not be the user expected front window so use this handler with care. *)
		on getFirstTab()
			if running of application "Safari Technology Preview" is false then return missing value
			
			tell application "Safari Technology Preview"
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
	if running of application "Safari Technology Preview" is false then
		do shell script (format {"open -a Safari {}", theUrl})
		
		script WindowWaiter
			if (count of (windows of application "Safari Technology Preview")) is not 0 then return true
		end script
		exec of retry on result
	else
		tell application "Safari Technology Preview" to make new document with properties {URL:theUrl}
	end if
*)
			
			set safariAppRunning to running of application "Safari Technology Preview"
			tell application "System Events" to tell process "Safari Technology Preview"
				if (not safariAppRunning) or not (exists window "Start Page") then
					dock's newSafariWindow()
					-- delay 1 -- trying to solve issue with page load.
				end if
			end tell
			
			script StartPageWaiter
				tell application "Safari Technology Preview" to set windowId to id of window "Start Page" -- New window will not always start with "Start Page"
				-- tell application "Safari Technology Preview" 
				-- 	if name of front window is not "Start Page" then return missing value
				
				-- 	set windowId to id of front window
				-- end tell
				
				windowId
			end script
			set windowId to exec of retry on result for 3
			assertThat of std given condition:windowId is not missing value, messageOnFail:"Failed to initialize safari window to a valid state"
			
			tell application "Safari Technology Preview"
				set newSafariTechnologyPreviewTabInstance to my _new(windowId, count of tabs of window "Start Page")
			end tell
			newSafariTechnologyPreviewTabInstance's focus()
			
			-- script Resilient
			-- 	tell application "Safari Technology Preview" to set URL of front document to targetUrl -- can't avoid focusing the address bar for fresh pages.
			-- 	true
			-- end script
			-- exec of retry on result for 3
			
			-- retry causing double visit to the URL
			tell application "Safari Technology Preview" to set URL of front document to targetUrl -- can't avoid focusing the address bar for fresh pages.
			
			newSafariTechnologyPreviewTabInstance
		end newWindow
		
		(* 
			Note: On Safari 15, you have to configure General > New tabs open with blank 
			page. Doing otherwise like setting it to 'Start Page' have problems where
			the url passed will be ignored and you are left with a Start Page. *)
		on newTab(targetUrl)
			if running of application "Safari Technology Preview" is false then
				logger's debug("new window due to absence of Safari")
				
				return newWindow(targetUrl)
			end if
			
			tell application "Safari Technology Preview"
				try
					if (count of (windows whose visible is true)) is 0 then return my newWindow(targetUrl) -- battlescar
				on error
					return my newWindow(targetUrl)
				end try
			end tell
			
			-- main's focusWindowWithToolbar()
			focusWindowWithToolbar()
			
			-- logger's debugf("theUrl: {}", theUrl)
			tell application "Safari Technology Preview"
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
			
			_new(id of appWindow, tabTotal)
		end newTab
		
		on newCognito(targetUrl)
			if running of application "Safari Technology Preview" is false then activate application "Safari Technology Preview"
			
			tell application "System Events" to tell application process "Safari Technology Preview"
				click menu item "New Private Window" of menu "File" of menu bar 1
			end tell
			
			tell application "Safari Technology Preview"
				set the URL of current tab of front window to targetUrl
				set windowId to id of front window as integer
			end tell
			_new(windowId, 1)
		end newCognito
		
		
		on focusWindowWithToolbar()
			if running of application "Safari Technology Preview" is false then return
			
			set toolbarredWindow to missing value
			tell application "System Events" to tell process "Safari Technology Preview"
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


		-- Private Codes below =======================================================
		(*
			@windowId app window ID
			@pTabIndex the Safari tab index
		*)
		on _new(windowId, pTabIndex)
			-- logger's debugf("Window ID: {}, TabIndex: {}", {windowId, pTabIndex}) -- wished the name or the url can be included in the log, not easy to do.

			script SafariTechnologyPreviewTabInstance
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
					tell application "System Events" to tell process "Safari Technology Preview"
						try
							return exists toolbar 1 of my getSysEveWindow()
						end try
					end tell
					false
				end hasToolBar

				on hasAlert()
					tell application "System Events" to tell process "Safari Technology Preview" to tell getSysEveWindow()
						try
							button "Close" of group 1 of tab group 1 of splitter group 1 exists
						on error
							false
						end try
					end tell
				end hasAlert

				on dismissAlert()
					tell application "System Events" to tell process "Safari Technology Preview" to tell getSysEveWindow()
						try
							(click button "Close" of group 1 of tab group 1 of splitter group 1) exists
						end try
					end tell
				end dismissAlert

				(* Creates a new tab at the end of the window (not next to the tab) *)
				on newTab(targetUrl)
					tell application "Safari Technology Preview"
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
					tell application "Safari Technology Preview" to set current tab of my appWindow to _tab
				end focus

				on closeTab()
					tell application "Safari Technology Preview" to close _tab
				end closeTab

				on _getTab()
					_tab
				end _getTab

				on closeWindow()
					tell application "Safari Technology Preview" to close my appWindow()
				end closeWindow

				on reload()
					focus()
					tell application "Safari Technology Preview"
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
						tell application "Safari Technology Preview"
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
					tell application "Safari Technology Preview"
						try
							return (source of my getDocument()) as text
						end try
					end tell

					missing value
				end getSource

				on getURL()
					tell application "Safari Technology Preview"
						try
							return URL of my getDocument()
						end try
					end tell

					missing value
				end getURL

				on getAddressBarValue()
					if hasToolBar() is false then return missing value

					tell application "System Events" to tell process "Safari Technology Preview"
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

						-- tell application "Safari Technology Preview" to set URL of document (name of my appWindow) to targetUrl
						tell application "Safari Technology Preview" to set URL of my getDocument() to targetUrl
						true
					end script
					exec of retry on result for 2
					delay 0.1 -- to give waitForPageLoad ample time to enter a loading state.
				end goto


				(* Note: Will dismiss the prompt of the*)
				on dismissPasswordSavePrompt()
					focus()
					script PasswordPrompt
						tell application "System Events" to tell process "Safari Technology Preview"
							click button "Not Now" of sheet 1 of front window
							-- we need system event window, appWindow is app Safari window so it would not work here.
							true
						end tell
					end script
					exec of retry on result for 5 -- let's try click it 5 times, ignoring outcomes.
				end dismissPasswordSavePrompt

				on extractUrlParam(paramName)
					tell application "Safari Technology Preview" to set _url to URL of my getDocument()
					set pattern to format {"(?<={}=)\\w+", paramName}
					set matchedString to regex's findFirst(_url, pattern)
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
					tell application "Safari Technology Preview"
						document (my getWindowName())
					end tell
				end getDocument


				on getSysEveWindow()
					tell application "System Events" to tell process "Safari Technology Preview"
						return window (name of appWindow)
					end tell
				end getSysEveWindow
			end script

			tell application "Safari Technology Preview"
				set appWindow of SafariTechnologyPreviewTabInstance to window id windowId
				set _url of SafariTechnologyPreviewTabInstance to URL of document of window id windowId
				set _tab of SafariTechnologyPreviewTabInstance to item pTabIndex of tabs of appWindow of SafariTechnologyPreviewTabInstance
			end tell
			safariJavaScript's decorate(SafariTechnologyPreviewTabInstance)
			jsSafariTechPreviewDecorator's decorate(result)
		end _new

		(*
			Finds the address bar group by iterating from last to first, returning the first group with a text field.

			Note: Iteration is not slow, it's the client call to this that is actually slow.
		*)
		on _getAddressBarGroup()
			if running of application "Safari Technology Preview" is false then return missing value

			set addressBarGroupIndex to 0
			tell application "System Events" to tell process "Safari Technology Preview"
				set toolbarGroups to groups of toolbar 1 of front window
				repeat with i from (count of toolbarGroups) to 1 by -1
					set nextGroup to item i of toolbarGroups

					if exists text field 1 of nextGroup then
						set addressBarGroupIndex to i
						exit repeat
					end if
				end repeat
				group addressBarGroupIndex of toolbar 1 of front window
			end tell
		end _getAddressBarGroup

	end script
end new
