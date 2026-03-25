(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh libs/process/dec-process-window-resizer

	@Created: Sun, Oct 26, 2025 at 01:18:16 PM
	@Last Modified: 2026-03-24 17:31:26
	@Change Logs:

*)
use Math : script "core/math"

use loggerFactory : script "core/logger-factory"


property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		Main
		Manual: Resize Window
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

	set sutAppName to "Script Editor"
	set sutAppName to "iTerm2"
	logger's debugf("sutAppName: {}", sutAppName)

	sutLib's new(sutAppName)
	set sut to decorate(result)

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's setFirstWindowDimension(500, 500)

	else if caseIndex is 3 then

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script ProcessWindowResizerDecorator
		property parent : mainScript
		property resizeThreshold : 100  -- Resizing too small is being ignored.

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
					set {currentW, currentH} to the size of first window
					set delta to Math's abs(currentH - h)
					-- logger's debugf("delta: {}", delta)

					if delta is less than resizeThreshold then
						set size of first window to {100, 100}
						delay 0.5
					end if
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


		on setFirstWindowDimension(w, h)
			if running of application (my processName) is false then return

			tell application "System Events" to tell process (my processName)
				try
					set size of first window to {w, h}
				end try
			end tell
		end setFirstWindowDimension


		on getFirstSystemEventsWindowWidth()
			set firstWindow to getFirstSystemEventsWindow()
			if firstWindow is missing value then return 0

			tell application "System Events"
				size of firstWindow
				first item of result
			end tell
		end getFirstSystemEventsWindowWidth


		on getFirstSystemEventsWindowHeight()
			set firstWindow to getFirstSystemEventsWindow()
			if firstWindow is missing value then return 0

			tell application "System Events"
				size of firstWindow
				last item of result
			end tell
		end getFirstSystemEventsWindowHeight
	end script
end decorate
