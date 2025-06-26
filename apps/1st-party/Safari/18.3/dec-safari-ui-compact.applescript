(*
	@Purpose:
		The original safari script is quite big and we want to improve its manageability by breaking it down into smaller pieces.
		This decorator will contain the handlers that deal with the UI aspect of Safari.
		The handlers are specifically designed to handle when the Safari app is set to compact mode.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/18.3/dec-safari-ui-compact

	@Created: Wed, Feb 12, 2025 at 11:23:10 AM
	@Last Modified: 2025-06-26 06:31:38
	@Change Logs:
*)
use listUtil : script "core/list"
use loggerFactory : script "core/logger-factory"

use spotScript : script "core/spot-test"
use kbLib : script "core/keyboard"

property logger : missing value
property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		General
		Manual: Loading State
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

	logger's infof("Is Playing: {}", sut's isPlaying())
	logger's infof("Is page loading: {}", sut's isLoading())
	logger's infof("HTML Content Found?: {}", sut's getHtmlUi() is not missing value)

	if caseIndex is 1 then

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

	script SafariUICompactDecorator
		property parent : mainScript

		(*
			Determine loading state by clicking on the more options button in the address bar, and checking the resulting menu items for indication of the loading state.

			This handler grabs focus and send a keystroke.

			This operation is VERY SLOW. Takes about 8s to complete.
			Fails when there are too many tabs open

			@Known Issues:
				Thu, Jun 26, 2025 at 06:30:19 AM - Won't be able to tell if the tool bar is not present.
		*)
		on isLoading()
			if isCompact() is false then return continue isLoading()

			logger's warn("This isLoading() implementation is very slow to be deemed reliable. ")
			set addressBarGroup to _getAddressBarGroup()
			if addressBarGroup is missing value then return false

			tell application "System Events" to tell process "Safari"
				try
					set targetTabRadio to the first radio button of UI element 1 of addressBarGroup whose value is true
				on error the errorMessage number the errorNumber
					logger's warn(errorMessage)
					return false
				end try

				set addressField to the text field 1 of targetTabRadio
				set moreOptionsButton to button "More options" of targetTabRadio

				logger's info("Clicking the More options button...")
				click moreOptionsButton
				delay 0.1
				set stopMenuPresent to false
				try
					logger's info("Looking for the Stop menu item...")
					set stopMenuPresent to exists menu item "Stop" of menu 1 of addressBarGroup
				on error the errorMessage number the errorNumber
					logger's warn(errorMessage)
				end try
				-- click moreOptionsButton -- does not work. Let's try sending escape key instead.
				set frontmost to true
				kb's pressKey("esc")
			end tell
			stopMenuPresent
		end isLoading


		(*
			@Known Issues:
				Won't be able to tell if tool bar is not present in the window.
		*)
		on isPlaying()
			if running of application "Safari" is false then return false
			if isCompact() is false then
				logger's debug("continuing...")
				return continue isPlaying()
			end if



			tell application "System Events" to tell process "Safari"
				if (count of windows) is 0 then return false

				set addressBarGroup to my _getAddressBarGroup()
				if addressBarGroup is missing value then return false

				return exists (first button of (first radio button of UI element 1 of addressBarGroup whose value of attribute "AXValue" is true) whose description contains "Mute")
			end tell
		end isPlaying


		on getHtmlUi()
			if running of application "Safari" is false then return missing value
			if isCompact() is false then return continue getHtmlUi()

			tell application "System Events" to tell process "Safari"
				if (count of windows) is 0 then return missing value

				UI element 1 of scroll area 1 of group 1 of group 1 of tab group 1 of splitter group 1 of front window
			end tell
		end getHtmlUi


		(*
			Finds the address bar group by iterating from last to first, returning the first group with a text field.

			Note: Iteration is not slow, it's the client call to this that is actually slow.
		*)
		on _getAddressBarGroup()
			if running of application "Safari" is false then return missing value
			if isCompact() is false then return continue _getAddressBarGroup()

			tell application "System Events" to tell process "Safari"
				try
					return last group of toolbar 1 of (first window whose (name does not start with "Web Inspector" and name is not ""))
				end try
			end tell

			missing value
		end _getAddressBarGroup
	end script
end decorate
