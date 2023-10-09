(*
	@Purpose:
		The original safari script is quite big and we want to improve its manageability by breaking it down into smaller pieces.
		This decorator will contain the handlers that deal with the UI aspect of Safari.
		The handlers are specifically designed to handle when the Safari app is set to compact mode.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/16.0/dec-safari-ui-compact

	@Created: Wednesday, September 20, 2023 at 10:13:11 AM
	@Last Modified: 2023-10-09 10:47:02
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

	script SafariUICompactDecorator
		property parent : mainScript

		(*
			Determine loading state by clicking on the more options button in the address bar, and checking the resulting menu items for indication of the loading state.

			This handler grabs focus and send a keystroke.

			This operation is VERY SLOW. Takes about 8s to complete.
			Fails when there are too many tabs open
		*)
		on isLoading()
			if isCompact() is false then return continue isLoading()

			logger's warn("This isLoading() implementation is very slow to be deemed reliable. ")
			set addressBarGroup to _getAddressBarGroup()
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


		on isPlaying()
			if running of application "Safari" is false then return missing value
			if isCompact() is false then return continue isPlaying()

			tell application "System Events" to tell process "Safari"
				return exists (first button of (first radio button of UI element 1 of my _getAddressBarGroup() whose value of attribute "AXValue" is true) whose description contains "Mute")
			end tell
		end isPlaying


		(*
			Finds the address bar group by iterating from last to first, returning the first group with a text field.

			Note: Iteration is not slow, it's the client call to this that is actually slow.
		*)
		on _getAddressBarGroup()
			if running of application "Safari" is false then return missing value
			if isCompact() is false then return continue _getAddressBarGroup()

			tell application "System Events" to tell process "Safari"
				last group of toolbar 1 of front window
			end tell
		end _getAddressBarGroup
	end script
end decorate
