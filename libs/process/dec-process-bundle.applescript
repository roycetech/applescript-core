(*
	@Purpose:
		Support bundle id like com.github.Electron.  Electron apps behave differently in a macOS
		environment and the goal of this script is to tackle that difference.

		This decorator handles the four states of a process window:
			- running
			- hidden
			- minimized
			- fullscreen

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/decorators/dec-process-bundle

	@Created: Wednesday, September 11, 2024 at 2:06:22 PM
	@Last Modified: 2025-05-21 11:46:26
	@Change Logs:
*)
use scripting additions

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		INFO
		Manual: Raise Windows (Not working)
		Manual: Hide
		Manual: Unhide
		Manual: Minimize

		Manual: Unminimize
		Manual: Minimize All
		Manual: Terminate
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

		sut's raiseWindows()

	else if caseIndex is 3 then
		sut's hide()

	else if caseIndex is 4 then
		sut's unhide()

	else if caseIndex is 5 then
		sut's minimize()

	else if caseIndex is 6 then
		sut's unminimize()

	else if caseIndex is 7 then
		sut's minimizeAll()

	else if caseIndex is 8 then
		sut's terminate()

	else

	end if

	if sutAppKey is not missing value then
		logger's infof("Is running: {}", sut's isRunning())
		logger's infof("Is minimized: {}", sut's isMinimized())
		logger's infof("Is fullscreen: {}", sut's isFullscreen())
		logger's infof("Is hidden: {}", sut's isHidden())
	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script ProcessBundleDecorator
		property parent : mainScript

		on isRunning()
			running of application id (my bundleId)
		end isRunning


		on isMinimized()
			if not isRunning() then return false

			tell application "System Events" to tell (first process whose bundle identifier is my bundleId)
				try
					return value of attribute "AXMinimized" of window 1
				end try
			end tell

			false
		end isMinimized


		on isFullscreen()
			if not isRunning() then return false

			tell application "System Events" to tell (first process whose bundle identifier is my bundleId)
				return exists (first window whose value of attribute "AXFullScreen" is true)
			end tell

			false
		end isFullscreen

		on isFrontMost()
			if not isRunning() then return false

			tell application "System Events" to tell process processName
				frontmost
			end tell
		end isFrontMost

		(* Fails to work for React DevTools. *)
		on raiseWindows()
			if not isRunning() then return

			tell application "System Events" to tell (first process whose bundle identifier is equal to my bundleId)
				if (count of windows) is 1 then set frontmost to true

				-- perform action on windows fail thus the loop.
				repeat with nextWindow in windows
					try
						perform action "AXRaise" of nextWindow
					end try
				end repeat
			end tell
		end raiseWindows


		(* Appears incorrect, perhaps this is not supported *)
		on isHidden()
			if not isRunning() then return false

			tell application "System Events" to tell (first process whose bundle identifier is my bundleId)
				not visible
			end tell
		end isHidden


		on hide()
			if not isRunning() then return

			tell application "System Events" to tell (first process whose bundle identifier is my bundleId)
				set visible to false
			end tell
		end hide


		on unhide()
			if not isRunning() then return

			tell application "System Events" to tell (first process whose bundle identifier is my bundleId)
				set visible to true
			end tell
		end unhide

		(* In this example, the window doesn't have any buttons like the usual windows. *)
		on minimize()
			if not isRunning() then return

			set minimizeButton to missing value
			tell application "System Events" to tell (first process whose bundle identifier is my bundleId)
				try
					set minimizeButton to first button of front window whose description contains "minimize"
				end try
				if minimizeButton is not missing value then
					click minimizeButton
					return
				end if

				if not frontmost then set frontmost to true
				try
					click menu item "Minimize" of menu 1 of menu bar item "Window" of menu bar 1
				end try
			end tell
		end minimize


		on unminimize()
			if my bundleId is missing value then
				continue unminimize()
				return
			end if
			if not isRunning() then return

			tell application "System Events" to tell (first process whose bundle identifier is my bundleId)
				try
					set value of attribute "AXMinimized" of window 1 to false
				end try
			end tell

		end unminimize


		on minimizeAll()
			if my bundleId is missing value then
				continue minimizeAll()
				return
			end if

			if not isRunning() then return

			set minimizeButtons to missing value
			tell application "System Events" to tell (first process whose bundle identifier is my bundleId)
				try
					set minimizeButtons to first button of windowswindow whose description contains "minimize"
				end try
				if minimizeButtons is not missing value then
					click minimizeButtons
					return
				end if
			end tell

			minimize()
		end minimizeAll


		(*  *)
		on terminate()
			if my bundleId is missing value then
				continue terminate()
				return
			end if

			if not isRunning() then return

			try
				tell application id (my bundleId) to quit
			on error
				try
					do shell script (format("killall '{}'", processName))
				end try
			end try
			set maxRetry to 10000
			set retryCount to 0
			repeat while isRunning() and retryCount is less than maxRetry
				set retryCount to retryCount + 1
				delay 0.01
			end repeat
		end terminate
	end script
end decorate
