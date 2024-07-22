(*
	@Purpose:
		The original safari script is quite big and we want to improve its manageability by breaking it down into smaller pieces.
		This decorator will contain the handlers that deal with the UI aspect of Safari.
		The handlers are specifically designed to handle when the Safari app is set to compact mode.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/17.4.1/dec-safari-ui-noncompact

	@Created: Wednesday, September 20, 2023 at 10:13:11 AM
	@Last Modified: 2024-07-22 12:54:10
	@Change Logs:
		Sat, Jun 29, 2024 at 10:59:40 AM - Added isMuted() and implemented isPlaying()
*)
use listUtil : script "core/list"
use textUtil : script "core/string"
use unic : script "core/unicodes"

use loggerFactory : script "core/logger-factory"

use spotScript : script "core/spot-test"
use retryLib : script "core/retry"

property retry : missing value
property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set kbLib to script "core/keyboard"
	set kb to kbLib's new()

	set cases to listUtil's splitByLine("
		NOOP
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

	logger's infof("Is Loading: {}", sut's isLoading())
	logger's infof("isDefaultGroup: {}", sut's isDefaultGroup())
	logger's infof("Is Playing: {}", sut's isPlaying())
	logger's infof("Is Muted: {}", sut's isMuted())

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


on newSpotBase()
	script SpotBaseInstance
		property template : missing value
	end script
end newSpotBase


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	set retry to retryLib's new()

	script SafariUiNoncompactDecorator
		property parent : mainScript

		(*
			Determine loading state by clicking on the more options button in the address bar, and checking the resulting menu items for indication of the loading state.

			This handler grabs focus and send a keystroke.

			This operation is very slow. Takes about 8s to complete.
		*)
		on isLoading()
			if running of application "Safari" is false then return false

			set addressBarGroup to _getAddressBarGroup()
			if addressBarGroup is missing value then return false

			tell application "System Events" to tell process "Safari"
				try
					return exists (first button of addressBarGroup whose description is "Stop loading this page")
				end try
			end tell

			false
		end isLoading

		(*
			Determine if on default group when:
				SideBar Visible: first row is selected.
				SideBar Hidden: the tab picker is small, without any labels

		*)
		on isDefaultGroup()
			if running of application "Safari" is false then return false
				tell application "System Events" to tell process "Safari"
					if (count of windows) is 0 then return false
					end tell

			if isSideBarVisible() then
				tell application "System Events" to tell process "Safari"
					return value of attribute "AXSelected" of row 1 of outline 1 of scroll area 1 of group 1 of splitter group 1 of front window
				end tell
			end if

			-- else: SideBar not visible.
			script GroupPickerWaiter
				tell application "System Events" to tell process "Safari"
					first menu button of group 1 of toolbar 1 of front window whose help is "Tab Group Picker"
				end tell
			end script
			set groupPicker to exec of retry on result for 40 by 0.2 -- 2 seconds max.
			if groupPicker is missing value then error "Unable to find the group picker UI"

			(*
			-- Old implementation, checks the size of the UI
			tell application "System Events" to tell process "Safari"
				set wh to the size of groupPicker
				(first item of wh) is less than 40
			end tell
			*)


			tell application "System Events" to tell process "Safari"
				set tabGroupId to get value of attribute "AXIdentifier" of menu button 1 of group 1 of toolbar 1 of front window
			end tell
			tabGroupId does not contain "TabGroup="
		end isDefaultGroup


		(* @returns true if an video or music is playing. *)
		on isPlaying()
			if running of application "Safari" is false then return false

			tell application "System Events" to tell process "Safari"
				if (count of windows) is 0 then return false

				set windowTitle to the last item of textUtil's split(title of front window, unic's SEPARATOR)
				exists (first button of radio button windowTitle of UI element 1 of group 3 of toolbar 1 of front window whose description contains "Mute This Tab") -- case insensitive
			end tell
		end isPlaying


		(*
			@returns true if a sound is playing in the browser but muted in the browser.
		*)
		on isMuted()
			if running of application "Safari" is false then return false

			tell application "System Events" to tell process "Safari"
				if (count of windows) is 0 then return false

				set windowTitle to the last item of textUtil's split(title of front window, unic's SEPARATOR)
				exists (first button of radio button windowTitle of UI element 1 of group 3 of toolbar 1 of front window whose description contains "Unmute This Tab") -- case insensitive
			end tell
		end isMuted


		on focusAddressBar()
			if running of application "Safari" is false then return

			tell application "System Events" to tell process "Safari"
				if (count of windows) is 0 then return

				try
					click (the first menu item of menu 1 of menu bar item "File" of menu bar 1 whose title starts with "Open Location")
				end try
			end tell
		end focusAddressBar


		(* Took 8s on the first run, 0-1s on subsequent runs. *)
		on getHtmlUI()
			if running of application "Safari" is false then return missing value

			_getHtmlUI(missing value)
		end getHtmlUI

		on _getHtmlUI(targetUI)
			if running of application "Safari" is false then return missing value

			if targetUI is missing value then
				tell application "System Events" to tell process "Safari"
					if (count of windows) is 0 then return missing value

					try
						set targetUI to splitter group 1 of front window
					end try
				end tell
			end if
			if targetUI is missing value then return missing value

			set matchingUiElement to missing value
			try

				tell application "System Events" to tell process "Safari"
					set matchingUiElement to the first UI element of targetUI whose role description is equal to "HTML Content"
				end tell
			end try
			if matchingUiElement is not missing value then return matchingUiElement

			tell application "System Events" to tell process "Safari"
				set subuis to entire contents of targetUI
			end tell

			repeat with nextSubUi in subuis
				set nextUiElement to _getHtmlUI(nextSubUi)
				if nextUiElement is not missing value then return nextUiElement
			end repeat

			missing value
		end _getHtmlUI

		(*
			Finds the address bar group by iterating from last to first, returning the first group with a text field.

			TODO: Can fail intermittently when getting the groups of toolbar 1 of front window. Rarely so it's a little hard to catch.

			Note: Iteration is not slow, it's the client call to this that is actually slow.
		*)
		on _getAddressBarGroup()
			if running of application "Safari" is false then return missing value

			set addressBarGroupIndex to 0
			tell application "System Events" to tell process "Safari"
				if (count of windows) is 0 then return missing value

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
end decorate
