(*
	@Purpose:
		Window-related handlers of a macOS process.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/decorators/dec-process-windows

	@Created: Friday, September 13, 2024 at 2:05:42 PM
	@Last Modified: 2025-10-25 13:57:43

	@Change Logs:
		Sat, Oct 25, 2025, at 01:57:32 PM - #closeWindow() handler
*)
use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Move Window with Title Containing
		Manual: Move Window with Title Not Containing
		Manual: Close Window
		Dummy

		Dummy
		Dummy
		Dummy
		Dummy
		Dummy
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
	set sutLib to script "core/process"
	set sutAppName to "Safari"
	set sutAppName to "Script Editor"
	set sutAppName to "Docker Desktop"
	logger's debugf("sutAppName: {}", sutAppName)

	set sut to sutLib's new(sutAppName)
	set sut to decorate(sut)

	logger's infof("First window height: {}", sut's getFirstSystemEventsWindowHeight())
	logger's infof("First window width: {}", sut's getFirstSystemEventsWindowWidth())
	logger's infof("First window horizontal position: {}", sut's getFirstSystemEventsHorizontalWindowPosition())
	logger's infof("First window vertical position: {}", sut's getFirstSystemEventsVerticalWindowPosition())

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's moveWindowsWithTitleContaining("Document", 0, 0)

	else if caseIndex is 3 then
		sut's moveWindowsWithTitleNotContaining("Document", 0, 0)

	else if caseIndex is 4 then
		sut's closeWindow()
	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script ProcessDecorator
		property parent : mainScript

		on closeWindow()
			if running of application (my processName) is false then return

			tell application "System Events" to tell process (my processName)
				try
					click (first button of window 1 whose description is "close button")
				end try
			end tell
		end closeWindow


		(* @windowName is case-insensitive. *)
		on getWindowsMatchingName(windowName)
			if running of application (my processName) is false then return missing value

			tell application "System Events" to tell process (my processName)
				try
					return windows whose name contains windowName
				end try
			end tell

			missing value
		end getWindowsMatchingName


		on getWindowsNotMatchingName(windowName)
			if running of application (my processName) is false then return missing value

			tell application "System Events" to tell process (my processName)
				try
					return first window whose name does not contain windowName
				end try
			end tell

			missing value
		end getWindowsNotMatchingName


		on getWindowsEqualName(windowName)
			if running of application (my processName) is false then return missing value

			tell application "System Events" to tell process (my processName)
				try
					return windows whose name is equal to windowName
				end try
			end tell
			missing value
		end getWindowsEqualName


		on getWindowsNotEqualName(windowName)
			if running of application (my processName) is false then return missing value

			tell application "System Events" to tell process (my processName)
				try
					return windows whose name is not equal to windowName
				end try
			end tell
			missing value
		end getWindowsNotEqualName


		on getFirstWindow()
			if running of application (my processName) is false then return missing value

			set appWindows to getWindows()
			if the number of appWindows is 0 then return missing value

			first item of appWindows
		end getFirstWindow


		on getSystemEventsWindows()
			getWindows()
		end getSystemEventsWindows


		on getFirstSystemEventsWindow()
			getFirstWindow()
		end getFirstSystemEventsWindow


		on getFirstSystemEventsWindowHeight()
			set firstWindow to getFirstSystemEventsWindow()
			if firstWindow is missing value then return 0

			tell application "System Events"
				size of firstWindow
				last item of result
			end tell
		end getFirstSystemEventsWindowHeight


		on getFirstSystemEventsVerticalWindowPosition()
			set firstWindow to getFirstSystemEventsWindow()
			if firstWindow is missing value then return 0

			tell application "System Events"
				position of firstWindow
				last item of result
			end tell
		end getFirstSystemEventsVerticalWindowPosition


		on getFirstSystemEventsHorizontalWindowPosition()
			set firstWindow to getFirstSystemEventsWindow()
			if firstWindow is missing value then return 0

			tell application "System Events"
				position of firstWindow
				first item of result
			end tell
		end getFirstSystemEventsHorizontalWindowPosition


		on getFirstSystemEventsWindowWidth()
			set firstWindow to getFirstSystemEventsWindow()
			if firstWindow is missing value then return 0

			tell application "System Events"
				size of firstWindow
				first item of result
			end tell
		end getFirstSystemEventsWindowWidth


		on getWindows()
			if running of application (my processName) is false then return missing value

			tell application "System Events" to tell process (my processName)
				windows
			end tell
		end getWindows

		on getNonMinimizedWindows()
			if running of application (my processName) is false then return missing value

			tell application "System Events" to tell process (my processName)
				try
					windows whose value of attribute "AXMinimized" is false
				on error
					windows
				end try
			end tell
		end getNonMinimizedWindows

		on hasWindows()
			if running of application (my processName) is false then return false

			return the number of items in getWindows() is greater than 0
		end hasWindows


		on hasWindowsWithTitle(targetTitle)
			if running of application (my processName) is false then return false

			return the number of items in getWindowsEqualName(targetTitle) is greater than 0
		end hasWindowsWithTitle


		on setFirstWindowDimension(w, h)
			if running of application (my processName) is false then return

			tell application "System Events" to tell process (my processName)
				try
					set size of first window to {w, h}
				end try
			end tell
		end setFirstWindowDimension


		on moveFirstWindow(x, y)
			if my processName is not "java" and running of application (my processName) is false then return

			tell application "System Events" to tell process (my processName)
				try
					set position of first window to {x, y}
				end try
			end tell
		end moveFirstWindow


		on moveWindows(x, y)
			if my processName is not "java" and running of application (my processName) is false then return

			tell application "System Events" to tell process (my processName)
				try
					set position of windows to {x, y}
				end try
			end tell
		end moveWindows


		on moveWindowsWithTitleContaining(titleKey, x, y)
			if my processName is not "java" and running of application (my processName) is false then return

			tell application "System Events" to tell process (my processName)
				try
					set position of windows whose title contains titleKey to {x, y}
				end try
			end tell
		end moveWindowsWithTitleContaining


		on moveWindowsWithTitleNotContaining(titleKey, x, y)
			if my processName is not "java" and running of application (my processName) is false then return

			tell application "System Events" to tell process (my processName)
				try
					set position of windows whose title does not contain titleKey to {x, y}
				end try
			end tell
		end moveWindowsWithTitleNotContaining


		on resizeWindowsWithTitleContaining(titleKey, w, h)
			if my processName is not "java" and running of application (my processName) is false then return

			tell application "System Events" to tell process (my processName)
				try
					set size of windows whose title contains titleKey to {w, h}
				end try
			end tell
		end resizeWindowsWithTitleContaining


		on resizeWindowsWithTitleNotContaining(titleKey, w, h)
			if my processName is not "java" and running of application (my processName) is false then return

			tell application "System Events" to tell process (my processName)
				try
					set size of windows whose title does not contain titleKey to {w, h}
				end try
			end tell
		end resizeWindowsWithTitleNotContaining


		on resizeFirstWindow(w, h)
			if my processName is not "java" and running of application (my processName) is false then return

			tell application "System Events" to tell process (my processName)
				try
					set size of first window to {w, h}
				end try
			end tell
		end resizeFirstWindow


		on resizeWindows(w, h)
			if my processName is not "java" and running of application (my processName) is false then return

			tell application "System Events" to tell process (my processName)
				try
					set size of windows to {w, h}
				end try
			end tell
		end resizeWindows
	end script
end decorate
