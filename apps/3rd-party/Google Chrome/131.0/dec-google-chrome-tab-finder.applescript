(*
	@Purpose:
		This decorator will contain the handlers relating tab finding. 
		
		This script was retrofitted from the Safari version.
			current tab -> active tab

	@Project:
		applescript-core
 
	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Google Chrome/131.0/dec-google-chrome-tab-finder'

	NOTES:
		Could not use the shortcut "find tab whose property" because we need to get the index
		and the only why I found to do this is via manual iteration.

	@Created: Thu, Jan 16, 2025 at 8:45:23 AM
	@Last Modified: Saturday, March 16, 2024 at 11:13:11 AM
	@Change Logs:
		Fri, Jan 17, 2025 at 9:26:21 AM - Refactored to use generic window/tab iterator.
		Thu, Jan 16, 2025 at 8:45:39 AM - Migrated from v110.0 - TODO: Test the other methods, only findTabStartingWithUrl was tested.
*)
use loggerFactory : script "core/logger-factory"

use chromeTabLib : script "core/google-chrome-tab"

property logger : missing value

property ASC : 1
property DEFAULT : 0 -- Check active tab first then, check from first to last.
property DESC : -1
property TopLevel : me

if {"Script Editor", "Script Debugger", "osascript"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set configLib to script "core/config"
	set spotScript to script "core/spot-test"
	set listUtil to script "core/list"
	
	set cases to listUtil's splitByLine("
		NOOP:
		
		Manual: Find Tab by Title
		Manual: Find First Tab by Title
		Manual: Find Last Tab by Title

		Manual: Find Tab by Title Prefix
		Manual: Find First Tab by Title Prefix
		Manual: Find Last Tab by Title Prefix

		Manual: Find Tab by Title Substring
		Manual: Find First Tab by Title Substring
		Manual: Find Last Tab by Title Substring

		Manual: Find Tab by URL
		Manual: Find First Tab by URL
		Manual: Find Last Tab by URL

		Manual: Find Tab by URL Prefix
		Manual: Find First Tab by URL Prefix
		Manual: Find Last Tab by URL Prefix

		Manual: Find Tab by URL Substring
		Manual: Find First Tab by URL Substring
		Manual: Find Last Tab by URL Substring
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)

	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	
	-- activate application ""
	set sutLib to script "core/google-chrome"
	set sut to sutLib's new()
	set sut to decorate(sut)
	set configBusiness to configLib's new("business")
	set domain to configBusiness's getValue("Domain Key") & ".com"
	
	-- 	logger's infof("Is Loading: {}", sut's isLoading())
	logger's infof("Tab Count: {}", sut's getTabCount())
	
	if caseIndex is 2 then
		set sutName to "unicorn"
		set sutName to "Example Domain"
		logger's debugf("sutName: {}", sutName)
		
		set foundTab to sut's findTabByTitle(sutName)
		if foundTab is missing value then
			logger's info("Not found")
		else
			logger's info("Tab was found")
			foundTab's focus()
		end if

	else if caseIndex is 3 then
		set sutName to "unicorn"
		set sutName to "Example Domain"
		logger's debugf("sutName: {}", sutName)
		
		set foundTab to sut's findFirstTabByTitle(sutName)
		if foundTab is missing value then
			logger's info("Not found")
		else
			logger's info("Tab was found")
			foundTab's focus()
		end if
		
	else if caseIndex is 4 then
		set sutName to "unicorn"
		set sutName to "Example Domain"
		logger's debugf("sutName: {}", sutName)
		
		set foundTab to sut's findLastTabByTitle(sutName)
		if foundTab is missing value then
			logger's info("Not found")
		else
			logger's info("Tab was found")
			foundTab's focus()
		end if 

	else if caseIndex is 5 then
		set sutName to "unicorn"
		set sutName to "Example"
		logger's debugf("sutName: {}", sutName)
		
		set foundTab to sut's findTabByTitlePrefix(sutName)
		if foundTab is missing value then
			logger's info("Not found")
		else
			logger's info("Tab was found")
			foundTab's focus()
		end if 

	else if caseIndex is 6 then
		set sutName to "unicorn"
		set sutName to "Example"
		logger's debugf("sutName: {}", sutName)
		
		set foundTab to sut's findFirstTabByTitlePrefix(sutName)
		if foundTab is missing value then
			logger's info("Not found")
		else
			logger's info("Tab was found")
			foundTab's focus()
		end if

	else if caseIndex is 7 then
		set sutName to "unicorn"
		set sutName to "Example"
		logger's debugf("sutName: {}", sutName)
		
		set foundTab to sut's findLastTabByTitlePrefix(sutName)
		if foundTab is missing value then
			logger's info("Not found")
		else
			logger's info("Tab was found")
			foundTab's focus()
		end if

	else if caseIndex is 8 then
		set sutSubstring to "unicorn"
		set sutSubstring to "ample"
		logger's debugf("sutSubstring: {}", sutSubstring)
		
		set foundTab to sut's findTabByTitleSubstring(sutSubstring)
		if foundTab is missing value then
			logger's info("Not found")
		else
			logger's info("Tab was found")
			foundTab's focus()
		end if

	else if caseIndex is 9 then
		set sutSubstring to "unicorn"
		set sutSubstring to "ample"
		logger's debugf("sutSubstring: {}", sutSubstring)
		
		set foundTab to sut's findFirstTabByTitleSubstring(sutSubstring)
		if foundTab is missing value then
			logger's info("Not found")
		else
			logger's info("Tab was found")
			foundTab's focus()
		end if

	else if caseIndex is 10 then
		set sutSubstring to "unicorn"
		set sutSubstring to "ample"
		logger's debugf("sutSubstring: {}", sutSubstring)
		
		set foundTab to sut's findLastTabByTitleSubstring(sutSubstring)
		if foundTab is missing value then
			logger's info("Not found")
		else
			logger's info("Tab was found")
			foundTab's focus()
		end if


	else if caseIndex is 11 then
		set sutName to "unicorn"
		set sutName to "https://example.com"
		logger's debugf("sutName: {}", sutName)
		
		set foundTab to sut's findTabByUrl(sutName)
		if foundTab is missing value then
			logger's info("Not found")
		else
			logger's info("Tab was found")
			foundTab's focus()
		end if

	else if caseIndex is 12 then
		set sutName to "unicorn"
		set sutName to "https://example.com"
		logger's debugf("sutName: {}", sutName)
		
		set foundTab to sut's findFirstTabByUrl(sutName)
		if foundTab is missing value then
			logger's info("Not found")
		else
			logger's info("Tab was found")
			foundTab's focus()
		end if
		
	else if caseIndex is 13 then
		set sutName to "unicorn"
		set sutName to "https://example.com"
		logger's debugf("sutName: {}", sutName)
		
		set foundTab to sut's findLastTabByUrl(sutName)
		if foundTab is missing value then
			logger's info("Not found")
		else
			logger's info("Tab was found")
			foundTab's focus()
		end if 

	else if caseIndex is 14 then
		set sutName to "unicorn"
		set sutName to "https://example"
		logger's debugf("sutName: {}", sutName)
		
		set foundTab to sut's findTabByUrlPrefix(sutName)
		if foundTab is missing value then
			logger's info("Not found")
		else
			logger's info("Tab was found")
			foundTab's focus()
		end if 

	else if caseIndex is 15 then
		set sutName to "unicorn"
		set sutName to "https://example"
		logger's debugf("sutName: {}", sutName)
		
		set foundTab to sut's findFirstTabByUrlPrefix(sutName)
		if foundTab is missing value then
			logger's info("Not found")
		else
			logger's info("Tab was found")
			foundTab's focus()
		end if

	else if caseIndex is 16 then
		set sutName to "unicorn"
		set sutName to "https://example"
		logger's debugf("sutName: {}", sutName)
		
		set foundTab to sut's findLastTabByUrlPrefix(sutName)
		if foundTab is missing value then
			logger's info("Not found")
		else
			logger's info("Tab was found")
			foundTab's focus()
		end if

	else if caseIndex is 17 then
		set sutSubstring to "unicorn"
		set sutSubstring to "ample.com"
		logger's debugf("sutSubstring: {}", sutSubstring)
		
		set foundTab to sut's findTabByUrlSubstring(sutSubstring)
		if foundTab is missing value then
			logger's info("Not found")
		else
			logger's info("Tab was found")
			foundTab's focus()
		end if

	else if caseIndex is 18 then
		set sutSubstring to "unicorn"
		set sutSubstring to "ample.com"
		logger's debugf("sutSubstring: {}", sutSubstring)
		
		set foundTab to sut's findFirstTabByUrlSubstring(sutSubstring)
		if foundTab is missing value then
			logger's info("Not found")
		else
			logger's info("Tab was found")
			foundTab's focus()
		end if

	else if caseIndex is 19 then
		set sutSubstring to "unicorn"
		set sutSubstring to "ample.com"
		logger's debugf("sutSubstring: {}", sutSubstring)
		
		set foundTab to sut's findLastTabByUrlSubstring(sutSubstring)
		if foundTab is missing value then
			logger's info("Not found")
		else
			logger's info("Tab was found")
			foundTab's focus()
		end if
	end if
	
	spot's finish()
	logger's finish()
end spotCheck



on newTabByTitleFinder(tabTitle)
	script TabByTitleFinder
		on accept(googleChromeTab)
			tell application "Google Chrome"
				title of googleChromeTab is tabTitle
			end tell
		end accept
	end script
end newTabByTitleFinder

on newTabByTitlePrefixFinder(titlePrefix)
	script TabByTitlePrefixFinder
		on accept(googleChromeTab)
			tell application "Google Chrome"
				title of googleChromeTab starts with titlePrefix
			end tell
		end accept
	end script
end newTabByTitlePrefixFinder

on newTabByTitleSuffixFinder(titleSuffix)
	script TabByTitleSuffixFinder
		on accept(googleChromeTab)
			tell application "Google Chrome"
				title of googleChromeTab ends with titleSuffix
			end tell
		end accept
	end script
end newTabByTitleSuffixFinder

on newTabByTitleSubstringFinder(titleSubstring)
	script TabByTitleSubstringFinder
		on accept(googleChromeTab)
			tell application "Google Chrome"
				title of googleChromeTab contains titleSubstring
			end tell
		end accept
	end script
end newTabByTitleSubstringFinder


on newTabByUrlFinder(tabUrl)
	script TabByUrlFinder
		on accept(googleChromeTab)
			tell application "Google Chrome"
				URL of googleChromeTab is tabUrl
			end tell
		end accept
	end script
end newTabByUrlFinder

on newTabByUrlPrefixFinder(UrlPrefix)
	script TabByUrlPrefixFinder
		on accept(googleChromeTab)
			tell application "Google Chrome"
				URL of googleChromeTab starts with UrlPrefix
			end tell
		end accept
	end script
end newTabByUrlPrefixFinder

on newTabByUrlSuffixFinder(UrlSuffix)
	script TabByUrlSuffixFinder
		on accept(googleChromeTab)
			tell application "Google Chrome"
				URL of googleChromeTab ends with UrlSuffix
			end tell
		end accept
	end script
end newTabByUrlSuffixFinder

on newTabByUrlSubstringFinder(UrlSubstring)
	script TabByUrlSubstringFinder
		on accept(googleChromeTab)
			tell application "Google Chrome"
				URL of googleChromeTab contains UrlSubstring
			end tell
		end accept
	end script
end newTabByUrlSubstringFinder


(*
	find* handlers returns  missing value of tab if not found, otherwise it 
	returns a GoogleChromeTabInstance .
*)
on decorate(mainScript)
	loggerFactory's inject(me)

	script GoogleChromeFinderDecorator
		property parent : mainScript
		
		on getTabCount()
			if running of application "Google Chrome" is false then return 0
			
			tell application "Google Chrome"
				try
					return count every tab of (first window whose title does not start with "Web Inspector")
				end try
			end tell
			
			0
		end getTabCount


		on findTabByTitle(tabTitle)
			_findWindowTab(TopLevel's newTabByTitleFinder(tabTitle), DEFAULT)
		end findFirstTabByTitle
		
		on findFirstTabByTitle(tabTitle)
			_findWindowTab(TopLevel's newTabByTitleFinder(tabTitle), ASC)
		end findFirstTabByTitle
		
		on findLastTabByTitle(tabTitle) 
			_findWindowTab(TopLevel's newTabByTitleFinder(tabTitle), DESC)
		end findLastTabByTitle
		
		on findTabByTitlePrefix(titlePrefix)
			_findWindowTab(TopLevel's newTabByTitlePrefixFinder(titlePrefix), DEFAULT)
		end findFirstTabByTitlePrefix

		on findFirstTabByTitlePrefix(titlePrefix) 
			_findWindowTab(TopLevel's newTabByTitlePrefixFinder(titlePrefix), ASC)
		end findFirstTabByTitlePrefix

		on findLastTabByTitlePrefix(titlePrefix) 
			_findWindowTab(TopLevel's newTabByTitlePrefixFinder(titlePrefix), DESC)
		end findLastTabByTitlePrefix 

		on findTabByTitleSubstring(titleSubstring)
			_findWindowTab(TopLevel's newTabByTitleSubstringFinder(titleSubstring), DEFAULT)
		end findFirstTabStartingWithTitle

		on findFirstTabByTitleSubstring(titleSubstring)
			_findWindowTab(TopLevel's newTabByTitleSubstringFinder(titleSubstring), ASC)
		end findFirstTabStartingWithTitle 

		on findLastTabByTitleSubstring(titleSubstring)
			_findWindowTab(TopLevel's newTabByTitleSubstringFinder(titleSubstring), DESC)
		end findLastTabStartingWithTitle
		

		on findTabByUrl(tabUrl)
			_findWindowTab(TopLevel's newTabByUrlFinder(tabUrl), DEFAULT)
		end findFirstTabByUrl
		
		on findFirstTabByUrl(tabUrl)
			_findWindowTab(TopLevel's newTabByUrlFinder(tabUrl), ASC)
		end findFirstTabByUrl
		
		on findLastTabByUrl(tabUrl) 
			_findWindowTab(TopLevel's newTabByUrlFinder(tabUrl), DESC)
		end findLastTabByUrl
		
		on findTabByUrlPrefix(titlePrefix)
			_findWindowTab(TopLevel's newTabByUrlPrefixFinder(urlPrefix), DEFAULT)
		end findFirstTabByUrlPrefix

		on findFirstTabByUrlPrefix(urlPrefix) 
			_findWindowTab(TopLevel's newTabByUrlPrefixFinder(urlPrefix), ASC)
		end findFirstTabByUrlPrefix

		on findLastTabByUrlPrefix(urlPrefix) 
			_findWindowTab(TopLevel's newTabByUrlPrefixFinder(urlPrefix), DESC)
		end findLastTabByUrlPrefix 

		on findTabByUrlSubstring(urlSubstring)
			_findWindowTab(TopLevel's newTabByUrlSubstringFinder(urlSubstring), DEFAULT)
		end findFirstTabStartingWithUrl

		on findFirstTabByUrlSubstring(urlSubstring)
			_findWindowTab(TopLevel's newTabByUrlSubstringFinder(urlSubstring), ASC)
		end findFirstTabStartingWithUrl 

		on findLastTabByUrlSubstring(urlSubstring)
			_findWindowTab(TopLevel's newTabByUrlSubstringFinder(urlSubstring), DESC)
		end findLastTabStartingWithUrl

		
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
						
						set matchedTab to missing value
						set calculatedTabIndex to 0
						repeat with nextTab in tabs of nextWindow
							set calculatedTabIndex to calculatedTabIndex + 1
							if URL of nextTab starts with urlPrefix then
								set matchedTab to nextTab
								exit repeat
							end if
						end repeat
						if matchedTab is missing value then return missing value
						
						return chromeTabLib's new(id of nextWindow, calculatedTabIndex, me)
					on error the errorMessage number the errorNumber
						log errorMessage
						
					end try
				end repeat
			end tell
			missing value
		end findTabStartingWithUrl
		
		
		(* @return  missing value of tab is not found. *)
		on findLastTabStartingWithUrl(urlPrefix)
			set calculatedUrlPrefix to urlPrefix
			if urlPrefix does not start with "http" then set calculatedUrlPrefix to "https://" & urlPrefix
			logger's debugf("calculatedUrlPrefix: {}", calculatedUrlPrefix)
			
			script LastTabStartingWithUrlScript
				on accept(googleChromeTab)
					tell application "Google Chrome"
						URL of googleChromeTab starts with calculatedUrlPrefix
					end tell
				end accept
			end script
			_findWindowTab(LastTabStartingWithUrlScript, 1)
		end findLastTabStartingWithUrl
		
		
		(*
			@return  missing value of tab is not found.
		*)
		on findTabWithUrlContaining(urlSubstring)
			if running of application "Google Chrome" is false then return missing value
			
			tell application "Google Chrome"
				tell front window
					if URL of active tab contains urlSubstring then
						return chromeTabLib's new(its id, active tab index as integer)
					end if
				end tell
				
				repeat with nextWindow in windows
					try
						set matchedTab to (first tab of nextWindow whose URL contains urlSubstring)
						return chromeTabLib's new(id of nextWindow, index of matchedTab as integer)
					end try
				end repeat
			end tell
			missing value
		end findTabWithUrlContaining
		
		(*
			Generic implementation with a script object that determines the rules for finding.
		
			@scriptObj - must handle the following:
				#accept(googleChromeTab)

			@direction - 1 for asc, -1 for descending, 0 to check active tab then ascending. 
		*)
		on _findWindowTab(scriptObj, direction)
			if running of application "Google Chrome" is false then return missing value
			if scriptObj is missing value then return missing value
			
			set tabIterateDirection to direction
			set isReverseIteration to direction is DESC
			
			tell application "Google Chrome"
				repeat with nextWindow in windows
					try
						if direction is DEFAULT and scriptObj's accept(active tab of nextWindow) then
							return chromeTabLib's new(id of nextWindow, active tab index of nextWindow)
						end if
						
						set tabsToIterate to the tabs of nextWindow
						if tabIterateDirection is DESC then set tabsToIterate to the reverse of tabsToIterate
						
						set matchedTab to missing value
						set calculatedTabIndex to 0
						if isReverseIteration then set calculatedTabIndex to (the count of tabsToIterate) + 1
						
						repeat with nextTab in tabsToIterate
							set step to 1
							if isReverseIteration then set step to -1
							set calculatedTabIndex to calculatedTabIndex + step
							if scriptObj's accept(nextTab) then
								set matchedTab to nextTab
								exit repeat
							end if
						end repeat 
						
						if matchedTab is missing value then return missing value
						
						return chromeTabLib's new(id of nextWindow, calculatedTabIndex)
					on error the errorMessage number the errorNumber
						logger's warn(errorMessage)
						
					end try
				end repeat
			end tell
			missing value
			
		end _findWindowTab
	end script
end decorate
