(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/decorators/dec-process-window-mover

	@Created: Sun, Oct 26, 2025 at 01:16:46 PM
	@Last Modified: 2025-10-26 13:25:13
	@Change Logs:
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
		Manual: Move Window
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

	set sutRunningAppName to "Script Editor"
	logger's debugf("sutRunningAppName: {}", sutRunningAppName)
	sutLib's new(sutRunningAppName)
	set sutRunningApp to decorate(result)

	set sutNotRunningAppName to "App Store"
	logger's debugf("sutNotRunningAppName: {}", sutNotRunningAppName)
	sutLib's new(sutNotRunningAppName)
	set sutNotRunningApp to decorate(result)

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sutRunningApp's moveWindow(100, 100)

	else if caseIndex is 3 then

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script ProcessWindowMoverDecorator
		property parent : mainScript

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
	end script
end decorate
