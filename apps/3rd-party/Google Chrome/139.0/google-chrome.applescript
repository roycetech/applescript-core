(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Google Chrome/139.0/google-chrome'
		
	@Change Logs:
		Wed, Aug 06, 2025 at 07:36:02 AM - Added #getApplicationVersion
*)
use scripting additions

use script "core/Text Utilities"

use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use winUtilLib : script "core/window"
use googleChromeTabLib : script "core/google-chrome-tab"
use decChromeTabFinder : script "core/dec-google-chrome-tab-finder"
use decChromeInspector : script "core/dec-google-chrome-inspector"

use retryLib : script "core/retry"

property winUtil : missing value
property logger : missing value
property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Info
		Manual: New Window
		Manual: New Tab
		Manual: Open the Developer tools
		Manual: JavaScript

		Manual: Close Tab By Index
	")
	
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	
	if caseIndex is 0 then
		return
	end if
	
	set sut to new()
	logger's infof("Application version: {}", sut's getApplicationVersion())
	logger's infof("Is playing: {}", sut's isPlaying())
	logger's infof("Dev tools active: {}", sut's isDevToolsActive())
	logger's infof("Is default group: {}", sut's isDefaultGroup())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's newWindow("https://www.example.com")
		
	else if caseIndex is 3 then
		set googleChromeTab to sut's newTab("https://www.example.com")
		googleChromeTab's waitForPageLoad()
		
	else if caseIndex is 4 then
		sut's openDeveloperTools()
		
	else if caseIndex is 5 then
		set googleChromeTab to sut's getFrontTab()
		if googleChromeTab is missing value then
			logger's info("Chrome window was not found")
		else
			googleChromeTab's runScript("alert('Hello Chrome AppleScript')")
		end if
		
	else if caseIndex is 6 then
		-- sut's closeTabByIndex(99)
		sut's closeTabByIndex(3)
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck

on new()
	loggerFactory's inject(me)
	
	set winUtil to winUtilLib's new()
	set retry to retryLib's new()
	
	script GoogleChromeInstance
		on getApplicationVersion()
			set chromePath to "/Applications/Google Chrome.app"
			set chromeInfo to (do shell script "defaults read \"" & chromePath & "/Contents/Info.plist\" CFBundleShortVersionString")
			set versionTokens to textUtil's split(result, ".")
			item 1 of versionTokens & "." & item 2 of versionTokens
		end getApplicationVersion
		
		on isPlaying()
			if not winUtil's hasWindow("Google Chrome") then return false
			
			tell application "System Events" to tell process "Google Chrome"
				try
					first radio button of tab group 1 of group 1 of group 1 of group 1 of group 1 of front window whose selected is true
					return exists (first button of result whose description is "Mute tab")
				end try
			end tell
			false
		end isPlaying
		
		
		on newWindow(targetUrl)
			tell application "Google Chrome"
				activate
				set newWindow to make new window
				set URL of active tab of newWindow to targetUrl
				
				tell front window
					googleChromeTabLib's new(its id, active tab index)
				end tell
			end tell
		end newWindow
		
		on newTab(targetUrl)
			tell application "Google Chrome"
				-- activate
				
				if (count of windows) is 0 then
					do shell script "open -a 'Google Chrome'"
				end if
			end tell
			
			script WindowWaiter
				if exists (front window of application "Google Chrome") then return true
			end script
			exec of retry on result for 10 by 0.5
			
			tell application "Google Chrome" to tell front window
				if title of active tab is "New Tab" then
					logger's info("Re-using existing New Tab")
					set newTab to active tab
				else
					set newTab to make new tab at end of tabs
				end if
				set URL of newTab to targetUrl
				googleChromeTabLib's new(its id, active tab index)
			end tell
		end newTab
		
		
		on getFrontTab()
			if not winUtil's hasWindow("Google Chrome") then return missing value
			
			tell application "Google Chrome" to tell first window
				googleChromeTabLib's new(its id, active tab index)
			end tell
		end getFrontTab
		
		
		on openDeveloperTools()
			tell application "Google Chrome"
				activate
				tell active tab of window 1 to activate
				tell application "System Events"
					keystroke "i" using {option down, command down}
				end tell
			end tell
		end openDeveloperTools
		
		on closeTabByIndex(tabIndex)
			-- logger's debugf("tabIndex: {}", tabIndex)			
			if not winUtil's hasWindow("Google Chrome") then return
			
			tell application "Google Chrome"
				tell front window
					if (count of tabs) is greater than or equal to tabIndex then
						close tab tabIndex
					else
						logger's fatalf("Tab index {} is out of range.", tabIndex)
					end if
				end tell
			end tell
		end closeTabByIndex
		
		
		on focusTabWithIndex(tabIndex)
			if running of application "Google Chrome" is false then return
			
			tell application "Google Chrome"
				set totalTabs to (count of tabs in window 1) -- Get the number of tabs in the first window
				
				if tabIndex is less than or equal to the totalTabs and tabIndex > 0 then
					tell window 1 to set active tab index to tabIndex
				else
					logger's debugf("The desired tab index ({}) is out of range. There are only {} tabs.", {tabIndex, totalTabs})
					
				end if
			end tell
		end focusTabWithIndex
		
		(* Handler defined to make it uniform with Safari. *)
		on isDefaultGroup()
			true
		end isDefaultGroup
		
		
		(* This probably shouldn't be here, move to google-chrome instead. *)
		on focusTabIndex(tabIndex)
			if running of application "Google Chrome" is false then return
			
			tell application "Google Chrome"
				set totalTabs to (count of tabs in front window) -- Get the number of tabs in the first window, CHANGED to the front window.
				
				if tabIndex is less than or equal to the totalTabs and tabIndex > 0 then
					tell window 1 to set active tab index to tabIndex
				else
					logger's debugf("The desired tab index ({}) is out of range. There are only {} tabs.", {tabIndex, totalTabs})
					
				end if
			end tell
		end focusTabIndex
	end script
	
	decChromeTabFinder's decorate(result)
	decChromeInspector's decorate(result)
end new
