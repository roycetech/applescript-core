(*

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/18.0/dec-safari-profile

	@Created: Sunday, October 6, 2024 at 7:27:33 PM
	@Last Modified: 2025-02-20 06:42:51
	@Change Logs:
*)
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use safariTabLib : script "core/safari-tab"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Main
		Manual: New Business Tab
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

	logger's infof("Has profile Unicorn: {}", sut's hasWindowWithProfile("Unicorn"))
	logger's infof("Has profile Personal: {}", sut's hasWindowWithProfile("Personal"))
	logger's infof("Has profile Business: {}", sut's hasWindowWithProfile("Business"))

	set safariTab to sut's getFrontTab()
	if safariTab is not missing value then
		set sutTab to decorateTab(safariTab)
		logger's infof("Front tab profile: {}", sutTab's getProfile())
	end if

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's newTabOnProfile("Business", "https://www.example.com")
	else if caseIndex is 3 then

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck



on decorateTab(safariTabScript)
	loggerFactory's inject(me)

	script SafariTabProfileDecorator
		property parent : safariTabScript

		on getProfile()
			if running of application "Safari" is false then return missing value

			tell application "System Events" to tell process "Safari"
				menu button 1 of group 1 of toolbar 1 of front window
				textUtil's stringBetween(value of attribute "AXIdentifier" of result, "Profile=", "&")
			end tell
		end getProfile
	end script
end decorateTab


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script SafariProfileDecorator
		property parent : mainScript


		(* Checks available profiles via the Safari icon in the Dock. *)
		on hasWindowWithProfile(profileName)
			if running of application "Safari" is false then
				return false

				(*
				launch application "Safari" -- Run the app and not show any window.
				delay 0.5
*)
			end if

			tell application "System Events" to tell process "Safari"
				try
					return exists (first window whose title starts with profileName)
				end try
			end tell

			false
		end hasWindowWithProfile


		on newTabOnProfile(profileName, targetUrl)
			if running of application "Safari" is false then
				_newSafariWindow(profileName)
			end if

			tell application "Safari"
				try
					if (count of (windows whose visible is true)) is 0 then
						return my newWindowWithProfile(targetUrl, profileName)
					end if
				on error
					return my newWindowWithProfile(targetUrl, profileName)
				end try
			end tell

			-- main's focusWindowWithToolbar()
			focusWindowWithToolbar()

			-- logger's debugf("theUrl: {}", theUrl)
			tell application "Safari"
				try
					set appWindow to (first window whose name starts with profileName) -- Error on missing profile.
				on error the errorMessage number the errorNumber
					logger's warn(errorMessage)
					logger's fatalf("Profile {} was not found", profileName)
					return missing value
				end try

				tell appWindow to set current tab to (make new tab with properties {URL:targetUrl})
				set miniaturized of appWindow to false
				set tabTotal to count of tabs of appWindow
			end tell

			safariTabLib's new(id of appWindow, tabTotal, me)

		end newTabOnProfile
	end script
end decorate
