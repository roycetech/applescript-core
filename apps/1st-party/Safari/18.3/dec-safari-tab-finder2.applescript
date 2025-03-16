(*
	@Purpose:
		This decorator will contain the handlers relating tab finding.
		Added suffix to keep the existing tab finder handlers so existing codes
		don't break.

		NOTE: With the naming convention exception, this will decorate the main
		Safari script, and not the tab.

		This script was retrofitted from the Google Chrome version.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/18.3/dec-safari-tab-finder2

	NOTES:
		Could not use the shortcut "find tab whose property" because we need to get the index
		and the only why I found to do this is via manual iteration. - TODO: Verify if this is the same case with Safari.

	@Created: Thu, Feb 20, 2025 at 07:12:25 AM
	@Last Modified: 2025-02-20 07:15:15
	@Change Logs:

*)
use loggerFactory : script "core/logger-factory"

use safariTabLib : script "core/safari-tab"

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
	set sutLib to script "core/safari"
	set sut to sutLib's new()
	set sut to decorate(sut)
	set configBusiness to configLib's new("business")
	set domain to configBusiness's getValue("Domain Key") & ".com"

	-- 	logger's infof("Is Loading: {}", sut's isLoading())
	logger's infof("First Window Tab Count: {}", sut's getFirstWindowTabCount())

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
		on accept(safariTab)
			tell application "Safari"
				name of safariTab is tabTitle
			end tell
		end accept
	end script
end newTabByTitleFinder

on newTabByTitlePrefixFinder(titlePrefix)
	script TabByTitlePrefixFinder
		on accept(safariTab)
			tell application "Safari"
				name of safariTab starts with titlePrefix
			end tell
		end accept
	end script
end newTabByTitlePrefixFinder

on newTabByTitleSuffixFinder(titleSuffix)
	script TabByTitleSuffixFinder
		on accept(safariTab)
			tell application "Safari"
				name of safariTab ends with titleSuffix
			end tell
		end accept
	end script
end newTabByTitleSuffixFinder

on newTabByTitleSubstringFinder(titleSubstring)
	script TabByTitleSubstringFinder
		on accept(safariTab)
			tell application "Safari"
				name of safariTab contains titleSubstring
			end tell
		end accept
	end script
end newTabByTitleSubstringFinder


on newTabByUrlFinder(tabUrl)
	script TabByUrlFinder
		on accept(safariTab)
			tell application "Safari"
				URL of safariTab is tabUrl
			end tell
		end accept
	end script
end newTabByUrlFinder

on newTabByUrlPrefixFinder(UrlPrefix)
	script TabByUrlPrefixFinder
		on accept(safariTab)
			tell application "Safari"
				URL of safariTab starts with UrlPrefix
			end tell
		end accept
	end script
end newTabByUrlPrefixFinder

on newTabByUrlSuffixFinder(UrlSuffix)
	script TabByUrlSuffixFinder
		on accept(safariTab)
			tell application "Safari"
				URL of safariTab ends with UrlSuffix
			end tell
		end accept
	end script
end newTabByUrlSuffixFinder

on newTabByUrlSubstringFinder(UrlSubstring)
	script TabByUrlSubstringFinder
		on accept(safariTab)
			tell application "Safari"
				URL of safariTab contains UrlSubstring
			end tell
		end accept
	end script
end newTabByUrlSubstringFinder


(*
	find* handlers returns  missing value of tab if not found, otherwise it
	returns a safariTabInstance .
*)
on decorate(mainScript)
	loggerFactory's inject(me)

	script SafariTabFinderDecorator
		property parent : mainScript

		on getFirstWindowTabCount()
			if running of application "Safari" is false then return 0

			tell application "Safari"
				try
					return count every tab of (first window whose name does not start with "Web Inspector")
				end try
			end tell

			0
		end getFirstWindowTabCount


		on findTabByTitle(tabTitle)
			_findWindowTab(TopLevel's newTabByTitleFinder(tabTitle), DEFAULT)
		end findTabByTitle

		on findFirstTabByTitle(tabTitle)
			_findWindowTab(TopLevel's newTabByTitleFinder(tabTitle), ASC)
		end findFirstTabByTitle

		on findLastTabByTitle(tabTitle)
			_findWindowTab(TopLevel's newTabByTitleFinder(tabTitle), DESC)
		end findLastTabByTitle

		on findTabByTitlePrefix(titlePrefix)
			_findWindowTab(TopLevel's newTabByTitlePrefixFinder(titlePrefix), DEFAULT)
		end findTabByTitlePrefix

		on findFirstTabByTitlePrefix(titlePrefix)
			_findWindowTab(TopLevel's newTabByTitlePrefixFinder(titlePrefix), ASC)
		end findFirstTabByTitlePrefix

		on findLastTabByTitlePrefix(titlePrefix)
			_findWindowTab(TopLevel's newTabByTitlePrefixFinder(titlePrefix), DESC)
		end findLastTabByTitlePrefix

		on findTabByTitleSubstring(titleSubstring)
			_findWindowTab(TopLevel's newTabByTitleSubstringFinder(titleSubstring), DEFAULT)
		end findTabByTitleSubstring

		on findFirstTabByTitleSubstring(titleSubstring)
			_findWindowTab(TopLevel's newTabByTitleSubstringFinder(titleSubstring), ASC)
		end findFirstTabByTitleSubstring

		on findLastTabByTitleSubstring(titleSubstring)
			_findWindowTab(TopLevel's newTabByTitleSubstringFinder(titleSubstring), DESC)
		end findLastTabByTitleSubstring


		on findTabByUrl(tabUrl)
			_findWindowTab(TopLevel's newTabByUrlFinder(tabUrl), DEFAULT)
		end findTabByUrl

		on findFirstTabByUrl(tabUrl)
			_findWindowTab(TopLevel's newTabByUrlFinder(tabUrl), ASC)
		end findFirstTabByUrl

		on findLastTabByUrl(tabUrl)
			_findWindowTab(TopLevel's newTabByUrlFinder(tabUrl), DESC)
		end findLastTabByUrl

		on findTabByUrlPrefix(UrlPrefix)
			_findWindowTab(TopLevel's newTabByUrlPrefixFinder(UrlPrefix), DEFAULT)
		end findTabByUrlPrefix

		on findFirstTabByUrlPrefix(UrlPrefix)
			_findWindowTab(TopLevel's newTabByUrlPrefixFinder(UrlPrefix), ASC)
		end findFirstTabByUrlPrefix

		on findLastTabByUrlPrefix(UrlPrefix)
			_findWindowTab(TopLevel's newTabByUrlPrefixFinder(UrlPrefix), DESC)
		end findLastTabByUrlPrefix

		on findTabByUrlSubstring(UrlSubstring)
			_findWindowTab(TopLevel's newTabByUrlSubstringFinder(UrlSubstring), DEFAULT)
		end findTabByUrlSubstring

		on findFirstTabByUrlSubstring(UrlSubstring)
			_findWindowTab(TopLevel's newTabByUrlSubstringFinder(UrlSubstring), ASC)
		end findFirstTabByUrlSubstring

		on findLastTabByUrlSubstring(UrlSubstring)
			_findWindowTab(TopLevel's newTabByUrlSubstringFinder(UrlSubstring), DESC)
		end findLastTabByUrlSubstring

		(*
			Generic implementation with a script object that determines the rules for finding.

			@scriptObj - must handle the following:
				#accept(safariTab)

			@direction - 1 for asc, -1 for descending, 0 to check active tab then ascending.
		*)
		on _findWindowTab(scriptObj, direction)
			if running of application "Safari" is false then return missing value
			if scriptObj is missing value then return missing value

			set tabIterateDirection to direction
			set isReverseIteration to direction is DESC

			tell application "Safari"
				repeat with nextWindow in windows
					try
						if direction is DEFAULT and scriptObj's accept(current tab of nextWindow) then
							return safariTabLib's new(id of nextWindow, index of current tab of nextWindow)
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

						return safariTabLib's new(id of nextWindow, calculatedTabIndex)
					on error the errorMessage number the errorNumber
						logger's warn(errorMessage)

					end try
				end repeat
			end tell
			missing value

		end _findWindowTab
	end script
end decorate
