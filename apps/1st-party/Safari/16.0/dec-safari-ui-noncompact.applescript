(*
	@Purpose:
		The original safari script is quite big and we want to improve its manageability by breaking it down into smaller pieces.
		This decorator will contain the handlers that deal with the UI aspect of Safari.
		The handlers are specifically designed to handle when the Safari app is set to compact mode.

	@Project:
		applescript-core

	@Build:
		make install-safari

	@Created: Wednesday, September 20, 2023 at 10:13:11 AM
	@Last Modified: 2023-09-24 10:54:01
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
			if isSideBarVisible() then
				tell application "System Events" to tell process "Safari"
					return value of attribute "AXSelected" of row 1 of outline 1 of scroll area 1 of group 1 of splitter group 1 of front window
				end tell
			end if

			-- else: SideBar not visible.
			set groupPicker to missing value
			tell application "System Events" to tell process "Safari"
				try
					set groupPicker to first menu button of group 1 of toolbar 1 of front window whose help is "Tab Group Picker"
				end try
			end tell
			if groupPicker is missing value then error "Unable to find the group picker UI"

			tell application "System Events" to tell process "Safari"
				set wh to the size of groupPicker
				(first item of wh) is less than 40
			end tell
		end isDefaultGroup


		(* TODO: Implement. *)
		on isPlaying()
			if running of application "Safari" is false then return missing value

			false
		end isPlaying


		(*
			Finds the address bar group by iterating from last to first, returning the first group with a text field.

			Note: Iteration is not slow, it's the client call to this that is actually slow.
		*)
		on _getAddressBarGroup()
			if running of application "Safari" is false then return missing value

			set addressBarGroupIndex to 0
			tell application "System Events" to tell process "Safari"
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
