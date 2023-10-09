(*
	@Purpose:
		The original safari script is quite big and we want to improve its manageability by breaking it down into smaller pieces.
		This decorator will contain the handlers relating tab finding.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/16.0/dec-safari-tab-finder

	@Created: Wednesday, September 20, 2023 at 10:13:11 AM
	@Last Modified: 2023-10-09 10:46:32
	@Change Logs: .
*)
use listUtil : script "core/list"
use loggerFactory : script "core/logger-factory"

use safariTabLib : script "core/safari-tab"

use spotScript : script "core/spot-test"
use kbLib : script "core/keyboard"

property logger : missing value
property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual:
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	-- activate application ""
	set sutLib to script "safari"
	set sut to sutLib's new()
	set sut to decorate(sut)

	-- 	logger's infof("Is Loading: {}", sut's isLoading())

	if caseIndex is 1 then
		activate application "Safari"
		kb's pressCommandKey("r")
		delay 1
		logger's infof("Is Loading: {}", sut's isLoading())

	else if caseIndex is 2 then

	else if caseIndex is 3 then

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


on newSpotBase()
	script SpotBaseInstance
		property template : missing value
	end script
end newSpotBase


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	set kb to kbLib's new()

	script SafariFinderDecorator
		property parent : mainScript

		(*
			@return  missing value of tab if not found, else a SafariTabInstance .
		*)
		on findTabWithName(targetName)
			if running of application "Safari" is false then return missing value

			tell application "Safari"
				repeat with nextWindow in windows
					try
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
						set matchedTab to (first tab of nextWindow whose URL starts with urlPrefix)
						return safariTabLib's new(id of nextWindow, index of matchedTab as integer, me)
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
