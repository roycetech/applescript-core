(*
	@Purpose:
		Windows-related handlers for a process.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/decorators/dec-process-bundle-windows

	@Created: Thursday, September 12, 2024 at 5:27:09 PM
	@Last Modified: 2024-12-31 19:33:52
	@Change Logs:
*)

use std : script "core/std"
use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Matched Windows by Name
		Manual: Mismatched Windows by Name
		Manual: Windows with Name Equal
		Manual: Windows with Name Not Equal

		Manual: First Window
		Manual: Windows
		Manual: Non-Minimized Windows
		Manual: Has Windows
		Manual: Has Window With Title

		Manual: Move First Window
		Manual: Move Windows
		Manual: Resize First Window
		Manual: Resize Windows
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sutAppKey to "com.github.Electron"
	set sutLib to script "core/process"
	set sut to sutLib's new(sutAppKey)
	set sut to decorate(sut)

	if caseIndex is 1 then

	else if caseIndex is 2 then
		assertThat of std given condition:(count of sut's getWindowsMatchingName("Unicorn")) is 0, messageOnFail:"Expected no windows matched failed"

		assertThat of std given condition:(count of sut's getWindowsMatchingName("React")) is 1, messageOnFail:"Expected windows matched failed"

	else if caseIndex is 3 then
		assertThat of std given condition:(count of sut's getWindowsNotMatchingName("Unicorn")) is 1, messageOnFail:"Expected no windows matched failed"

		assertThat of std given condition:(count of sut's getWindowsNotMatchingName("React Developer Tools")) is 0, messageOnFail:"Expected windows matched failed"

	else if caseIndex is 4 then
		assertThat of std given condition:(count of sut's getWindowsEqualName("Unicorn")) is 0, messageOnFail:"Expected no windows matched failed"

		assertThat of std given condition:(count of sut's getWindowsEqualName("React Developer Tools")) is 1, messageOnFail:"Expected windows with name failed"

	else if caseIndex is 5 then
		assertThat of std given condition:(count of sut's getWindowsNotEqualName("Unicorn")) is 1, messageOnFail:"Expected no windows matched failed"

		assertThat of std given condition:(count of sut's getWindowsNotEqualName("React Developer Tools")) is 0, messageOnFail:"Expected windows with name failed"

	else if caseIndex is 6 then
		assertThat of std given condition:sut's getFirstWindow() is not missing value, messageOnFail:"Expected no windows matched failed"

	else if caseIndex is 7 then
		assertThat of std given condition:(count of sut's getWindows()) is 1, messageOnFail:"Expected no windows matched failed"

	else if caseIndex is 8 then
		assertThat of std given condition:(count of sut's getNonMinimizedWindows()) is 1, messageOnFail:"Expected non minimized windows count failed"

	else if caseIndex is 9 then
		assertThat of std given condition:sut's hasWindows(), messageOnFail:"Expected window detection failed"

	else if caseIndex is 10 then
		assertThat of std given condition:sut's hasWindowsWithTitle("Unicorn") is false, messageOnFail:"Expected window with title absence failed"
		assertThat of std given condition:sut's hasWindowsWithTitle("React Developer Tools"), messageOnFail:"Expected window with title presence failed"

	else if caseIndex is 11 then
		sut's moveFirstWindow(0, 0)

	else if caseIndex is 12 then
		sut's moveWindows(100, 100)

	else if caseIndex is 13 then
		sut's resizeFirstWindow(300, 300)

	else if caseIndex is 14 then
		sut's resizeWindows(600, 600)



	else

	end if

	logger's info("Passed")

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script ProcessBundleWindowsDecorator
		property parent : mainScript

		(* @windowName is case-insensitive. *)
		on getWindowsMatchingName(windowName)
			if isRunning() is false then return {}

			tell application "System Events" to tell (first process whose bundle identifier is my bundleId)
				try
					return windows whose name contains windowName
				end try
			end tell

			missing value
		end getWindowsMatchingName


		on getWindowsNotMatchingName(windowName)
			if isRunning() is false then return {}

			tell application "System Events" to tell (first process whose bundle identifier is my bundleId)
				try
					return windows whose name does not contain windowName
				end try
			end tell

			missing value
		end getWindowsNotMatchingName


		on getWindowsEqualName(windowName)
			if isRunning() is false then return {}

			tell application "System Events" to tell (first process whose bundle identifier is my bundleId)
				try
					return windows whose name is equal to windowName
				end try
			end tell
			missing value
		end getWindowsEqualName


		on getWindowsNotEqualName(windowName)
			if isRunning() is false then return {}

			tell application "System Events" to tell (first process whose bundle identifier is my bundleId)
				try
					return windows whose name is not equal to windowName
				end try
			end tell
			missing value
		end getWindowsNotEqualName


		on getFirstWindow()
			if isRunning() is false then return missing value

			set appWindows to getWindows()
			if the number of appWindows is 0 then return missing value

			first item of appWindows
		end getFirstWindow


		on getWindows()
			if isRunning() is false then return {}

			tell application "System Events" to tell (first process whose bundle identifier is my bundleId)
				windows
			end tell
		end getWindows


		on getNonMinimizedWindows()
			if isRunning() is false then return {}

			tell application "System Events" to tell (first process whose bundle identifier is my bundleId)
				try
					windows whose value of attribute "AXMinimized" is false
				on error
					windows
				end try
			end tell
		end getNonMinimizedWindows

		on hasWindows()
			if isRunning() is false then return false

			return the number of items in getWindows() is greater than 0
		end hasWindows


		on hasWindowsWithTitle(targetTitle)
			if isRunning() is false then return false

			return the number of items in getWindowsEqualName(targetTitle) is greater than 0
		end hasWindowsWithTitle


		on moveFirstWindow(x, y)
			if isRunning() is false then return

			tell application "System Events" to tell (first process whose bundle identifier is my bundleId)
				try
					set position of first window to {x, y}
				end try
			end tell
		end moveFirstWindow


		on moveWindows(x, y)
			if isRunning() is false then return

			tell application "System Events" to tell (first process whose bundle identifier is my bundleId)
				try
					set position of windows to {x, y}
				end try
			end tell
		end moveWindows


		on resizeFirstWindow(w, h)
			if isRunning() is false then return

			tell application "System Events" to tell (first process whose bundle identifier is my bundleId)
				try
					set size of first window to {w, h}
				end try
			end tell
		end resizeFirstWindow


		on resizeWindows(w, h)
			if isRunning() is false then return

			tell application "System Events" to tell (first process whose bundle identifier is my bundleId)
				try
					set size of windows to {w, h}
				end try
			end tell
		end resizeWindows
	end script
end decorate
