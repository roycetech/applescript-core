(*
	@Purpose:
		The original safari script is quite big and we want to improve its manageability by breaking it down into smaller pieces.
		This decorator will contain the handlers relating tab finding.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/17.5/dec-safari-tab-finder

	@Created: Mon, Jul 22, 2024 at 12:28:44 PM
	@Last Modified: 2026-02-20 13:23:01
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

use safariTabLib : script "core/safari-tab"
use kbLib : script "core/keyboard"

property logger : missing value

property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Manual: findTabStartingWithUrl
	")

	set spotScript to script "core/spot-test"
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

	-- 	logger's infof("Is Loading: {}", sut's isLoading())
	logger's infof("Tab Count: {}", sut's getTabCount())

	if caseIndex is 1 then
		sut's findTabStartingWithUrl("app.pluralsight.com/ilx/video-courses")
		if result is missing value then
			logger's info("Not found")
		else
			logger's info("Tab was found")
		end if

	else if caseIndex is 2 then
		activate application "Safari"
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

	script SafariFinderDecorator
		property parent : mainScript

		on getTabCount()
			if running of application "Safari" is false then return 0


			tell application "Safari"
				try
					return count every tab of (first window whose name does not start with "Web Inspector")
				end try
			end tell

			0
		end getTabCount

		(*
			@return  missing value of tab if not found, else a SafariTabInstance .
		*)
		on findTabWithName(targetName)
			if running of application "Safari" is false then return missing value

			tell application "Safari"
				repeat with nextWindow in windows
					try
						if name of current tab of nextWindow is equal to targetName then
							return safariTabLib's new(id of nextWindow, index of current tab of nextWindow, me)
						end if

						set matchedTab to (first tab of nextWindow whose name is equal to targetName)
						return safariTabLib's new(id of nextWindow, index of matchedTab as integer, me)
					end try
				end repeat
			end tell
			return missing value
		end findTabWithName


		(* @return  missing value of tab is not found. TabInstance *)
		on findTabStartingWithName(targetName)
			if running of application "Safari" is false then return missing value

			tell application "Safari"
				repeat with nextWindow in windows
					try
						if name of current tab of nextWindow starts with targetName then
							return safariTabLib's new(id of nextWindow, index of current tab of nextWindow, me)
						end if

						set matchedTab to (first tab of nextWindow whose name starts with targetName)
						return safariTabLib's new(id of nextWindow, index of matchedTab as integer, me)
					end try
				end repeat
			end tell
			missing value
		end findTabStartingWithName


		(* @return  missing value of tab is not found. TabInstance *)
		on findTabContainingInName(nameSubstring)
			if running of application "Safari" is false then return missing value

			tell application "Safari"
				repeat with nextWindow in windows
					try
						if name of current tab of nextWindow contains nameSubstring then
							return safariTabLib's new(id of nextWindow, index of current tab of nextWindow, me)
						end if

						set matchedTab to (first tab of nextWindow whose name contains nameSubstring)
						return safariTabLib's new(id of nextWindow, index of matchedTab as integer, me)
					end try
				end repeat
			end tell
			return missing value
		end findTabContainingInName


		(* @return  missing value of tab is not found. TabInstance *)
		on findTabEndingWithName(targetName)
			if running of application "Safari" is false then return missing value

			tell application "Safari"
				repeat with nextWindow in windows
					try
						if name of current tab of nextWindow ends with targetName then
							return safariTabLib's new(id of nextWindow, index of current tab of nextWindow, me)
						end if

						set matchedTab to (first tab of nextWindow whose name ends with targetName)
						return safariTabLib's new(id of nextWindow, index of matchedTab as integer, me)
					end try
				end repeat
			end tell
			missing value
		end findTabEndingWithName


		(* @return  missing value of tab is not found. *)
		on findTabWithUrl(targetUrl)
			if running of application "Safari" is false then return missing value

			tell application "Safari"
				repeat with nextWindow in windows
					try
						if URL of current tab of nextWindow is equal to targetUrl then
							return safariTabLib's new(id of nextWindow, index of current tab of nextWindow, me)
						end if

						set matchedTab to (first tab of nextWindow whose URL is equal to the targetUrl)
						return safariTabLib's new(id of nextWindow, index of matchedTab as integer, me)
					end try
				end repeat
			end tell
			missing value
		end findTabWithUrl


		(* @return  missing value of tab is not found. *)
		on findTabStartingWithUrl(urlPrefix)
			if running of application "Safari" is false then return missing value

			if urlPrefix does not start with "http" then set urlPrefix to "https://" & urlPrefix

			tell application "Safari"
				repeat with nextWindow in windows
					try
						if URL of current tab of nextWindow starts with urlPrefix then
							return safariTabLib's new(id of nextWindow, index of current tab of nextWindow, me)
						end if

						set matchedTab to (first tab of nextWindow whose URL starts with urlPrefix)
						return safariTabLib's new(id of nextWindow, index of matchedTab as integer, me)
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
			if running of application "Safari" is false then return missing value

			tell application "Safari"
				tell front window
					if URL of current tab contains urlSubstring then
						return safariTabLib's new(its id, index of current tab as integer, me)
					end if
				end tell

				repeat with nextWindow in windows
					try
						set matchedTab to (first tab of nextWindow whose URL contains urlSubstring)
						return safariTabLib's new(id of nextWindow, index of matchedTab as integer, me)
					end try
				end repeat
			end tell
			missing value
		end findTabWithUrlContaining
	end script
end decorate
