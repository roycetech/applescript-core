(*
	This library is a wrapper to a running process. Error is raised if the app don't exist upon instantiation of this component.

	Notes:
		Process is synonymous to app in this context.
		Supports two types of apps derivation: traditional by app name and by bundle id.

	Testing Notes:
		Debug in logging must be on to see spot check object introspection.
		Have 3 Script Editor windows, this window plus 2 Untitled windows.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/process


	@Limitations:
		Doesn't support Electron apps which can be referenced via its bundle identifier com.github.Electron.

	@Change Logs:
		Sun, Sep 21, 2025, at 10:57:15 AM - Added clickMenuItem

	@Created:
		< 2024
*)

use scripting additions
use script "core/Text Utilities"

use std : script "core/std"

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"
use dockLib : script "core/dock"

property logger : missing value

property retry : missing value
property dock : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	set spotScript to script "core/spot-test"
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Nonexistent App
		Manual: Terminate (Launch Automator). (Running/Not Running)
		Manual: Is Front Most (Running,Not Running)
		Manual: Quit App
		Dummy

		Manual: First App Window(Running, Not Running, No Windows, With Window)
		Manual: App Windows(Running, Not Running, No Windows, With Window)
		Manual: Windows Matching Name(Running, Not Running)
		Manual: Windows Not Matching Name(Running, Not Running)
		Manual: Windows Equal Name(Running, Not Running)

		Manual: Windows Not Equal Name(Running, Not Running)
		Manual: App Is Running
		Manual: Minimize
		Manual: Minimize All
		Manual: Is Fullscreen

		Manual: Force Quit
		Manual: com.github.Electron
		Manual: Wait App Activate
		Manual: Wait Window
		Manual: Fullscreen a window
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	(* Common SUTs *)
	set scriptEditorApp to new("Script Editor")
	set notRunning to new("App Store")

	logger's infof("Is minimized: {}", scriptEditorApp's isMinimized())
	logger's infof("Front window title: {}", scriptEditorApp's getFrontWindowTitle())
	logger's infof("Integration: process-dock-aware: {}", scriptEditorApp's isDockOverlappingWindow())

	if caseIndex is 2 then
		try
			set sut to new("Pasadena")
		on error
			logger's info("Passed.")
		end try

	else if caseIndex is 3 then
		logger's infof("isFrontMost-Script Editor: {}", scriptEditorApp's isFrontMost())
		logger's infof("isFrontMost-Terminal: {}", new("Terminal")'s isFrontMost())
		logger's infof("isFrontMost (Not Running): {}", notRunning's isFrontMost())


	else if caseIndex is 4 then
		set sutAppName to "Talon"
		logger's debugf("sutAppName: {}", sutAppName)

		set sut to new(sutAppName)
		-- sut's terminate()
		sut's quitApp()
		activate app sutAppName

	else if caseIndex is 5 then

	else if caseIndex is 6 then
		logger's logObj("First App Window", scriptEditorApp's getFirstWindow())

	else if caseIndex is 7 then
		set sutWindows to scriptEditorApp's getWindows()
		logger's logObj("Process Windows: ", sutWindows)
		logger's infof("Window Count: {}", the number of sutWindows)

	else if caseIndex is 8 then
		set sutWindows to scriptEditorApp's getWindowsMatchingName("Untitled")
		logger's logObj("Not Running: ", notRunning's getWindowsMatchingName("App"))
		logger's logObj("Matched Windows: ", sutWindows)
		logger's infof("Window Count: {}", the number of sutWindows)

	else if caseIndex is 9 then
		set sutWindows to scriptEditorApp's getWindowsNotMatchingName("Untitled")
		logger's logObj("Not Running: ", notRunning's getWindowsMatchingName("App"))
		logger's logObj("Unmatched Windows: ", sutWindows)
		logger's infof("Window Count: {}", the number of sutWindows)

	else if caseIndex is 10 then
		set sutWindows to scriptEditorApp's getWindowsEqualName("process.applescript")
		logger's logObj("Not Running: ", notRunning's getWindowsMatchingName("App"))
		logger's logObj("Equalled Windows: ", sutWindows)
		logger's infof("Window Count: {}", the number of sutWindows)

	else if caseIndex is 11 then
		set sutWindows to scriptEditorApp's getWindowsNotEqualName("process.applescript")
		logger's logObj("Not Running: ", notRunning's getWindowsMatchingName("App"))
		logger's logObj("Not Equalled Windows: ", sutWindows)
		logger's infof("Window Count: {}", the number of sutWindows)

	else if caseIndex is 12 then
		set sut to new("Script Editor")
		assertThat of std given condition:sut's isRunning(), messageOnFail:"Failed spot check"
		set sut to new("Migration Assistant")
		assertThat of std given condition:sut's isRunning() is false, messageOnFail:"Failed spot check"

	else if caseIndex is 13 then
		set sut to new("Script Editor")
		sut's minimize()

	else if caseIndex is 14 then
		set sut to new("Sublime Text")
		sut's minimizeAll()

	else if caseIndex is 15 then
		delay 5 -- App in another space is not detected, manually focus the space with the app.
		set sut to new("Safari")
		logger's infof("Is Fullscreen: {}", sut's isFullscreen())
		beep 1

	else if caseIndex is 16 then
		set sut to new("Safari")
		sut's forceQuit()

	else if caseIndex is 17 then
		set sut to new("com.github.Electron")
		sut's moveWindow(0, 0)

		logger's infof("Frontmost: {}", sut's isFrontMost())

	else if caseIndex is 18 then
		set sutProcessName to "Sequel Ace"
		set sutProcessName to "Passwords"
		logger's debugf("sutProcessName: {}", sutProcessName)

		set sut to new(sutProcessName)
		sut's waitActivate()

	else if caseIndex is 19 then
		set systemSettingsApp to new("System Settings")
		set sutWindowName to "Unicorn"
		set sutWindowName to "Sound"

		logger's infof("Window present: {}", systemSettingsApp's waitWindow(sutWindowName))

	else if caseIndex is 20 then
		set scriptEditorApp to new("Script Editor")
		scriptEditorApp's fullscreen()

	end if


	spot's finish()
	logger's finish()
end spotCheck


(*
	@pProcessName - the app name or the bundle identifier.
*)
on new(pProcessName)
	loggerFactory's injectBasic(me)
	set retry to retryLib's new()
	set dock to dockLib's new()

	set localProcessName to missing value
	set localBundleId to missing value

	set appFound to false
	if std's appExists(pProcessName) then
		set appFound to true
		set localProcessName to pProcessName

	else if std's appWithIdExists(pProcessName) then
		set appFound to true
		set localBundleId to pProcessName
	end if

	-- logger's debugf("localBundleId: {}", localBundleId)
	-- logger's debugf("appFound: {}", appFound)

	if not appFound then error "App: " & pProcessName & " could not be found."

	script ProcessInstance
		property processName : localProcessName
		property bundleId : localBundleId


		(*
			@returns true if app has been verified not running.
		*)
		on quitApp()
			if running of application processName is false then return true

			tell application processName to quit
			repeat 10 times
				if running of application processName is false then return true
				delay 0.5
			end repeat

			false
		end quitApp


		on clickMenuItem(menuTitle, menuItemTitle)
			tell application "System Events" to tell process (my processName)
				try
					click menu item menuItemTitle of menu 1 of menu bar item menuTitle of menu bar 1
					return true
				end try
			end tell

			false
		end clickMenuItem


		on getName()
			processName
		end getName


		on getFrontWindowTitle()
			if running of application processName is false then return missing value

			tell application "System Events" to tell process processName
				if (count windows) is 0 then return missing value

				try
					return title of front window
				end try
			end tell

			missing value
		end getFrontWindowTitle


		on waitActivate()
			script WaitAppWindow
				activate application processName
				tell application "System Events" to tell process processName
					if exists (window 1) then return true
				end tell
			end script
			set waitWindowResult to exec of retry on result for 4 by 0.5
			if waitWindowResult is not missing value then return

			dock's clickApp(processName)
		end waitActivate


		on focusWindows()
			script WaitFocus
				tell application "System Events" to tell process (my processName)
					set frontmost to true
				end tell

				tell application "System Events" to tell (first process whose frontmost is true)
					if name is my processName then return true
				end tell
			end script
			exec of retry on result for 3
		end focusWindows


		(*
			@Deprecated: use focusWindows because this actually raises all windows of the given app.
		*)
		on focusWindow()
			focusWindows()
		end focusWindow


		(* @returns true if the window was found. *)
		on waitWindow(windowName)
			script WindowWaiterScript
				tell application "System Events" to tell process (my processName)
					if exists (window windowName) then return true
				end tell
			end script
			exec of retry on result for 3
		end waitWindow


		on forceQuit()
			tell application "System Events" to tell (first process whose frontmost is true)
				try
					click (first menu item of menu 1 of menu bar item "Apple" of menu bar 1 whose title starts with "Force Quit")
				on error the errorMessage number the errorNumber
					logger's warn(errorMessage)
					return
				end try
				delay 1
			end tell

			set matchedRow to missing value
			set processRows to missing value
			tell application "System Events" to tell process "loginwindow"
				try
					set processRows to rows of table 1 of scroll area 1 of front window
				end try -- Sometimes loginwindow window is not available.
			end tell
			if processRows is missing value then return --

			repeat with nextRow in processRows
				tell application "System Events"
					if the name of static text 1 of UI element 1 of nextRow contains the processName then
						set matchedRow to the nextRow
						exit repeat
					end if
				end tell
			end repeat

			if matchedRow is not missing value then
				tell application "System Events" to tell process "loginwindow"
					set selected of matchedRow to true
					try
						click button "Force Quit" of front window
					end try
				end tell

				-- Confirm
				tell application "System Events" to tell process "loginwindow"
					try
						click button "Force Quit" of sheet 1 of front window
					end try
				end tell

			end if

			tell application "System Events" to tell process "loginwindow"
				-- Close the dialog
				try
					click (first button of front window whose description is "close button")
				on error the errorMessage number the errorNumber
					logger's infow(errorMessage)
				end try
			end tell
		end forceQuit


		on isMinimized()
			tell application "System Events" to tell process processName
				try
					return value of attribute "AXMinimized" of window 1
				end try
			end tell

			false
		end isMinimized


		on isFullscreen()
			tell application "System Events" to tell process processName
				return exists (first window whose value of attribute "AXFullScreen" is true)
			end tell

			false
		end isFullscreen


		on raiseWindows()
			tell application "System Events" to tell process processName
				try
					perform action "AXRaise" of windows
				end try
			end tell
		end raiseWindows


		(* Shares the same state as when minimized. *)
		on isHidden()
			tell application "System Events" to tell process processName
				not visible
			end tell
		end isHidden


		on hide()
			if running of application processName is false then return

			tell application "System Events" to tell process processName
				set visible to false
			end tell
		end hide


		on unhide()
			if running of application processName is false then return

			tell application "System Events" to tell process processName
				set visible to true
			end tell
		end unhide


		on minimize()
			if running of application processName is false then return

			tell application "System Events" to tell process processName
				try
					click (first button of front window whose description is "minimize button") -- There is no maximize equivalent, only "fullscreen"
				end try
			end tell
		end minimize


		on fullscreen()
			if running of application processName is false then return

			tell application "System Events" to tell process processName
				try
					click (first button of front window whose description is "full screen button")
				on error the errorMessage number the errorNumber
					log errorMessage

				end try
			end tell
		end fullscreen


		on unminimize()
			if running of application processName is false then return

			tell application "System Events" to tell process processName
				try
					set value of attribute "AXMinimized" of window 1 to false
				end try
			end tell

		end unminimize


		on minimizeAll()
			if running of application processName is false then return

			tell application "System Events" to tell process processName
				try
					click (first button of every window whose description contains "minimize")
				end try
			end tell
		end minimizeAll


		on isRunning()
			running of application processName
		end isRunning


		(*  *)
		on terminate()
			if std's appExists(processName) is false then return
			if not running of application processName then return

			try
				tell application processName to quit
			on error
				try
					do shell script (format {"killall '{}'", processName})
				end try
			end try

			repeat while running of application processName is true
				delay 0.01
			end repeat
		end terminate


		on isFrontMost()
			if not running of application processName then return false

			tell application "System Events" to tell process processName
				frontmost
			end tell
		end isFrontMost
	end script

	set decoratorWindow to script "core/dec-process-windows"
	set decoratorWindowResizer to script "core/dec-process-window-resizer"
	set decoratorWindowMover to script "core/dec-process-window-mover"
	set decoratorDockAware to script "core/dec-process-dock-aware"
	decoratorWindow's decorate(ProcessInstance)
	decoratorWindowResizer's decorate(result)
	decoratorWindowMover's decorate(result)
	decoratorDockAware's decorate(result)
	set nonBundleInstance to result

	set staticDecoratedInstance to missing value
	if localBundleId is not missing value then
		set decoratorBundle to script "core/dec-process-bundle"
		set decoratorBundleWindow to script "core/dec-process-bundle-windows"
		decoratorBundle's decorate(nonBundleInstance)
		set staticDecoratedInstance to decoratorBundleWindow's decorate(result)
	else
		set staticDecoratedInstance to nonBundleInstance
	end if

	-- Add dynamic decoration below if needed.

	staticDecoratedInstance
end new
