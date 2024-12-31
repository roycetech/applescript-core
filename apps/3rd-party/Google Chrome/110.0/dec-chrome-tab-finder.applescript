(*
	@Purpose:
		This decorator will contain the handlers relating tab finding. 
		
		This script was retrofitted from the Safari version.
			current tab -> active tab

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Google Chrome/110.0/dec-chrome-tab-finder'

	@Created: Saturday, March 16, 2024 at 11:13:08 AM
	@Last Modified: Saturday, March 16, 2024 at 11:13:11 AM
	@Change Logs:
*)
use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"

use chromeTabLib : script "core/chrome-tab"

use spotScript : script "core/spot-test"
use kbLib : script "core/keyboard"

property logger : missing value
property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: findTabStartingWithUrl
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	-- activate application ""
	set sutLib to script "core/chrome"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	-- 	logger's infof("Is Loading: {}", sut's isLoading())
	
	if caseIndex is 1 then
		sut's findTabStartingWithUrl("web.ankiapp.com/home")
		if result is missing value then
			logger's info("Not found")
		else
			logger's info("Tab was found")
		end if
		
	else if caseIndex is 2 then
		activate application "Google Chrome"
		kb's pressCommandKey("r")
		delay 1
		logger's infof("Is Loading: {}", sut's isLoading())
		
	else if caseIndex is 3 then
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	set kb to kbLib's new()
	
	script ChromeFinderDecorator
		property parent : mainScript
		
		on getTabCount()
			if running of application "Google Chrome" is false then return 0
			
			tell application "Google Chrome"
				count every tab of (first window whose title does not start with "Web Inspector")
			end tell
		end getTabCount
		
		(*
			@return  missing value of tab if not found, else a SafariTabInstance .
		*)
		on findTabWithName(targetName)
			if running of application "Google Chrome" is false then return missing value
			
			tell application "Google Chrome"
				repeat with nextWindow in windows
					try
						if title of active tab of nextWindow is equal to targetName then
							return chromeTabLib's new(id of nextWindow, active tab index of nextWindow, me)
						end if
						
						set matchedTab to (first tab of nextWindow whose title is equal to targetName)
						return chromeTabLib's new(id of nextWindow, index of matchedTab as integer, me)
					end try
				end repeat
			end tell
			return missing value
		end findTabWithName
		
		
		(* @return  missing value of tab is not found. TabInstance *)
		on findTabStartingWithName(targetName)
			if running of application "Google Chrome" is false then return missing value
			
			tell application "Google Chrome"
				repeat with nextWindow in windows
					try
						if title of active tab of nextWindow starts with targetName then
							return chromeTabLib's new(id of nextWindow, active tab index of nextWindow, me)
						end if
						
						set matchedTab to (first tab of nextWindow whose title starts with targetName)
						return chromeTabLib's new(id of nextWindow, index of matchedTab as integer, me)
					end try
				end repeat
			end tell
			missing value
		end findTabStartingWithName
		
		
		(* @return  missing value of tab is not found. TabInstance *)
		on findTabContainingInName(nameSubstring)
			if running of application "Google Chrome" is false then return missing value
			
			tell application "Google Chrome"
				repeat with nextWindow in windows
					try
						if title of active tab of nextWindow contains nameSubstring then
							return chromeTabLib's new(id of nextWindow, active tab index of nextWindow, me)
						end if
						
						set matchedTab to (first tab of nextWindow whose title contains nameSubstring)
						return chromeTabLib's new(id of nextWindow, index of matchedTab as integer, me)
					end try
				end repeat
			end tell
			return missing value
		end findTabContainingInName
		
		
		(* @return  missing value of tab is not found. TabInstance *)
		on findTabEndingWithName(targetName)
			if running of application "Google Chrome" is false then return missing value
			
			tell application "Google Chrome"
				repeat with nextWindow in windows
					try
						if title of active tab of nextWindow ends with targetName then
							return chromeTabLib's new(id of nextWindow, active tab index of nextWindow, me)
						end if
						
						set matchedTab to (first tab of nextWindow whose title ends with targetName)
						return chromeTabLib's new(id of nextWindow, index of matchedTab as integer, me)
					end try
				end repeat
			end tell
			missing value
		end findTabEndingWithName
		
		
		(* @return  missing value of tab is not found. *)
		on findTabWithUrl(targetUrl)
			if running of application "Google Chrome" is false then return missing value
			
			tell application "Google Chrome"
				repeat with nextWindow in windows
					try
						if URL of active tab of nextWindow is equal to targetUrl then
							return chromeTabLib's new(id of nextWindow, active tab index of nextWindow, me)
						end if
						
						set matchedTab to (first tab of nextWindow whose URL is equal to the targetUrl)
						return chromeTabLib's new(id of nextWindow, index of matchedTab as integer, me)
					end try
				end repeat
			end tell
			missing value
		end findTabWithUrl
		
		
		(* @return  missing value of tab is not found. *)
		on findTabStartingWithUrl(urlPrefix)
			if running of application "Google Chrome" is false then return missing value
			
			if urlPrefix does not start with "http" then set urlPrefix to "https://" & urlPrefix
			
			tell application "Google Chrome"
				repeat with nextWindow in windows
					try
						if URL of active tab of nextWindow starts with urlPrefix then
							return chromeTabLib's new(id of nextWindow, active tab index of nextWindow, me)
						end if
						
						set matchedTab to (first tab of nextWindow whose URL starts with urlPrefix)
						return chromeTabLib's new(id of nextWindow, index of matchedTab as integer, me)
					on error the errorMessage number the errorNumber
						log errorMessage
						
					end try
				end repeat
			end tell
			missing value
		end findTabStartingWithUrl
		
		
		(*
			@return  missing value of tab is not found.
		*)
		on findTabWithUrlContaining(urlSubstring)
			if running of application "Google Chrome" is false then return missing value
			
			tell application "Google Chrome"
				tell front window
					if URL of active tab contains urlSubstring then
						return chromeTabLib's new(its id, active tab index as integer, me)
					end if
				end tell
				
				repeat with nextWindow in windows
					try
						set matchedTab to (first tab of nextWindow whose URL contains urlSubstring)
						return chromeTabLib's new(id of nextWindow, index of matchedTab as integer, me)
					end try
				end repeat
			end tell
			missing value
		end findTabWithUrlContaining
	end script
end decorate
