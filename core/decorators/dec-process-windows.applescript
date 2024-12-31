(*
	@Purpose:
		Window-related handlers of a macOS process.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/decorators/dec-process-windows

	@Created: Friday, September 13, 2024 at 2:05:42 PM
	@Last Modified: 2024-12-31 19:34:02
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Main
		Manual: Move Window with Title Containing
		Manual: Move Window with Title Not Containing
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	-- activate application ""
	set sutLib to script "core/process"
	set sut to sutLib's new("Safari")
	set sut to decorate(sut)

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's moveWindowsWithTitleContaining("Document", 0, 0)

	else if caseIndex is 3 then
		sut's moveWindowsWithTitleNotContaining("Document", 0, 0)

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
