(*
	This library is a wrapper to a running process. Error is raised if the app don't exist upon instantiation of this component.

	Notes:
		Process is synonymous to app in this context.

	Testing Notes:
		Debug in logging must be on to see spot check object introspection.
		Have 3 Script Editor windows, this window plus 2 Untitled windows.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/process
*)

use script "core/Text Utilities"
use scripting additions

use std : script "core/std"
use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"

use spotScript : script "core/spot-test"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()
	set caseId to "process-spotCheck"

	set cases to listUtil's splitByLine("
		Inexistent App
		Manual: Terminate (Launch Automator). (Running/Not Running)
		Manual: Is Front Most (Running,Not Running)
		Manual: Move Window
		Manual: Resize Window

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
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(caseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	(* Common SUTs *)
	set scriptEditorApp to new("Script Editor")
	set notRunning to new("App Store")

	if caseIndex is 1 then
		try
			set sut to new("Pasadena")
		on error
			logger's info("Passed.")
		end try

	else if caseIndex is 2 then
		set sut to new("Automator")
		sut's terminate()

	else if caseIndex is 3 then
		logger's infof("isFrontMost-Script Editor: {}", scriptEditorApp's isFrontMost())
		logger's infof("isFrontMost-Terminal: {}", new("Terminal")'s isFrontMost())
		logger's infof("isFrontMost (Not Running): {}", notRunning's isFrontMost())

	else if caseIndex is 4 then
		scriptEditorApp's moveWindow(100, 100)

	else if caseIndex is 5 then
		scriptEditorApp's setFirstWindowDimension(500, 500)

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

	end if

	spot's finish()
	logger's finish()
end spotCheck



on new(pProcessName)
	loggerFactory's injectBasic(me)

	if std's appExists(pProcessName) is false then tell me to error "App: " & pProcessName & " could not be found."

	script ProcessInstance
		property processName : pProcessName

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
				visible
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
					click (first button of front window whose description contains "minimize")
				end try
			end tell
		end minimize


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

		(* @windowName is case-insensitive. *)
		on getWindowsMatchingName(windowName)
			if running of application processName is false then return missing value

			tell application "System Events" to tell process processName
				try
					return windows whose name contains windowName
				end try
			end tell

			missing value
		end getWindowsMatchingName


		on getWindowsNotMatchingName(windowName)
			if running of application processName is false then return missing value

			tell application "System Events" to tell process processName
				try
					return first window whose name does not contain windowName
				end try
			end tell

			missing value
		end getWindowsNotMatchingName


		on getWindowsEqualName(windowName)
			if running of application processName is false then return missing value

			tell application "System Events" to tell process processName
				try
					return windows whose name is equal to windowName
				end try
			end tell
			missing value
		end getWindowsEqualName


		on getWindowsNotEqualName(windowName)
			if running of application processName is false then return missing value

			tell application "System Events" to tell process processName
				try
					return windows whose name is not equal to windowName
				end try
			end tell
			missing value
		end getWindowsNotEqualName


		on getFirstWindow()
			if running of application processName is false then return missing value

			set appWindows to getWindows()
			if the number of appWindows is 0 then return missing value

			first item of appWindows
		end getFirstWindow


		on getWindows()
			if running of application processName is false then return missing value

			tell application "System Events" to tell process processName
				windows
			end tell
		end getWindows

		on getNonMinimizedWindows()
			if running of application processName is false then return missing value

			tell application "System Events" to tell process processName
				try
					windows whose value of attribute "AXMinimized" is false
				on error
					windows
				end try
			end tell
		end getNonMinimizedWindows

		on hasWindows()
			if running of application processName is false then return false

			return the number of items in getWindows() is greater than 0
		end hasWindows


		on hasWindowsWithTitle(targetTitle)
			if running of application processName is false then return false

			return the number of items in getWindowsEqualName(targetTitle) is greater than 0
		end hasWindowsWithTitle


		on setFirstWindowDimension(w, h)
			if running of application processName is false then return

			tell application "System Events" to tell process processName
				try
					set size of first window to {w, h}
				end try
			end tell
		end setFirstWindowDimension


		on moveWindow(x, y)
			if processName is not "java" and running of application processName is false then return

			tell application "System Events" to tell process processName
				try
					set position of first window to {x, y}
				end try
			end tell
		end moveWindow

		on resizeWindow(w, h)
			if processName is not "java" and running of application processName is false then return

			tell application "System Events" to tell process processName
				try
					set size of first window to {w, h}
				end try
			end tell
		end resizeWindow

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
end new
