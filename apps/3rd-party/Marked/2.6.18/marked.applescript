(*
	@Version: 2.16.18

	@Project:
		applescript-core

	@Build:
		make build-marked
Closing windows of people extra
	@Last Modified: 2023-11-06 19:11:02

	@Known Issues:
		July 2, 2023 8:39 PM - Application keeps reference to closed windows,
			we need to use System Events instead to check actual windows.
*)

use std : script "core/std"

use listUtil : script "core/list"
use fileUtil : script "core/file"
use regexPatternLib : script "core/regex-pattern"

use loggerFactory : script "core/logger-factory"

use loggerLib : script "core/logger"
use configLib : script "core/config"

use spotScript : script "core/spot-test"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	set configSystem to configLib's new("system")

	set cases to listUtil's splitByLine("
		Open File - Not Running
		Open File - Running
		Open File - Running - No document
		Focus Doc - Manual
		Get Front Tab - Manual (Test Zoomed and non Zoomed)

		Manual: Find Tab With Name
		Manual: Close Tab
		Open File - Free Style 1-2s
		Open File Asynchronous
		Toggle Dark Mode

		Turn On Dark Mode
		Turn On Light Mode
		Manual: Set Raise Window on Update ON
		Manual: Set Raise Window on Update OFF
		Manual: Scroll to Bottom

		Manual: Set Preprocess Arguments
	")

	set examplesPath to configSystem's getValue("AppleScript Core Project Path") & "/apps/3rd-party/Marked"
	set testFile1 to examplesPath & "/example-1.md"
	set testFile2 to examplesPath & "/example-2.md"

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()
	if caseIndex is 1 then
		tell application "Marked" to quit
		delay 1
		set macTab to sut's openFile(testFile1)
		logger's infof("Open file: {}", name of macTab)

	else if caseIndex is 2 then
		tell application "Marked" to quit
		delay 2 -- 1s failed.
		activate application "Marked"
		delay 1
		tell application "Marked" to close every window

		set markedTab1 to sut's openFile(testFile1)
		logger's infof("Open file: {}", markedTab1's getDocumentName())
		set markedTab2 to sut's openFile(testFile2)
		logger's infof("Open file: {}", markedTab2's getDocumentName())

	else if caseIndex is 3 then
		tell application "Marked" to quit
		delay 1
		activate application "Marked"
		delay 1
		tell application "Marked" to close every window

		set markedTab1 to sut's openFile(testFile1)
		logger's infof("Open file: {}", markedTab1's getDocumentName())

	else if caseIndex is 4 then
		tell application "Marked" to quit
		delay 1
		activate application "Marked"
		delay 1
		tell application "Marked" to close every window

		set markedTab1 to sut's openFile(testFile1) -- Safari
		set markedTab2 to sut's openFile(testFile2) -- ST
		markedTab1's focus() -- Manually Switch
		markedTab2's focus()
		logger's infof("Open file: {}", markedTab1's getDocumentName())

	else if caseIndex is 5 then
		set frontTab to sut's getFrontTab()
		if frontTab is missing value then
			logger's info("No window found")

		else
			logger's infof("Open document name: {}", frontTab's getDocumentName())
		end if

	else if caseIndex is 6 then
		set mdTab to sut's findTabWithName("Safari-general.md")
		assertThat of std given condition:mdTab is not missing value, messageOnFail:"Expected found but missing"

		set mdTabMissing to sut's findTabWithName("Safari-general.mdx")
		assertThat of std given condition:(mdTabMissing is missing value), messageOnFail:"Expected missing but present"
		logger's info("Passed.")

	else if caseIndex is 7 then
		set mdTab to sut's findTabWithName("example-2.md")
		if mdTab is not missing value then mdTab's closeTab()

	else if caseIndex is 8 then
		sut's openFile(testFile2)

	else if caseIndex is 9 then
		sut's openFileAsync(testFile2)

	else if caseIndex is 10 then
		sut's toggleDarkMode()

	else if caseIndex is 11 then
		sut's turnOnDarkMode()

	else if caseIndex is 12 then
		sut's turnOnLightMode()

	else if caseIndex is 13 then
		sut's setRaiseWindowOnUpdate(true)

	else if caseIndex is 14 then
		sut's setRaiseWindowOnUpdate(false)

	else if caseIndex is 15 then
		sut's scrollToBottom()

	else if caseIndex is 16 then
		set markdownTab to sut's getFrontTab()
		markdownTab's setPreprocessorArguments("1234")
	end if

	spot's finish()
	logger's finish()
end spotCheck

on new()
	loggerFactory's injectBasic(me)

	script MarkedInstance
		on startInspection()
			if running of application "Marked" is false then return

			tell application "System Events" to tell process "Marked"
				set frontmost to true
				set htmlContent to UI element 1 of scroll area 1 of group 1 of front window
				perform action 1 of htmlContent
				delay 0.1
				click menu item "Inspect Element" of menu 1 of htmlContent
			end tell
		end startInspection


		on scrollToBottom()
			if running of application "Marked" is false then return

			tell application "System Events" to tell process "Marked"
				set value of scroll bar 1 of scroll area 1 of group 1 of front window to 1
			end tell
		end scrollToBottom


		on setRaiseWindowOnUpdate(newValue)
			if running of application "Marked" is false then return

			tell application "System Events" to tell process "Marked"
				try
					click (first menu item of menu 1 of menu bar item "Marked" of menu bar 1 whose title starts with "Preferences")
				end try
				delay 0.1
				click button "General" of toolbar 1 of front window
				set currentValue to value of checkbox "Raise window on update" of front window
				logger's debugf("currentValue: {}", currentValue)
				if currentValue is 0 and newValue or currentValue is 1 and newValue is false then
					click checkbox "Raise window on update" of front window
					delay 0.1
				end if
				click (first button of front window whose description is "close button")
			end tell
		end setRaiseWindowOnUpdate


		on turnOnDarkMode()
			if running of application "Marked" is false then return

			tell application "System Events" to tell process "Marked"
				-- try
				set isChecked to value of attribute "AXMenuItemMarkChar" of menu item "Dark Mode" of menu 1 of menu bar item "Preview" of menu bar 1 is not missing value
				if isChecked then return

				-- end try
			end tell

			toggleDarkMode()
		end turnOnDarkMode


		on turnOnLightMode()
			tell application "System Events" to tell process "Marked"
				set frontmost to true
				try
					if value of attribute "AXMenuItemMarkChar" of menu item "Dark Mode" of menu 1 of menu bar item "Preview" of menu bar 1 is missing value then return
				end try
			end tell

			toggleDarkMode()
		end turnOnLightMode


		on toggleDarkMode()
			tell application "System Events" to tell process "Marked"
				set frontmost to true
				try
					click menu item "Dark Mode" of menu 1 of menu bar item "Preview" of menu bar 1
				end try
			end tell
		end toggleDarkMode

		(*
			Would it be faster if we use MON?
			@returns true if the operation completes without issues.
		*)
		on openFileAsync(posixFilePath)
			if not fileUtil's posixFilePathExists(posixFilePath) then return missing value

			if running of application "Marked" is false then
				activate application "Marked"
				delay 0.1
				tell application "Marked" to close every window
			end if

			set initialWinCount to _getSysEveWindowCount()
			set isFirstWindow to initialWinCount is 0
			if not isFirstWindow then set frontMarkedTab to getFrontTab()

			tell application "Marked"
				ignoring application responses
					open posixFilePath
				end ignoring
			end tell
		end openFileAsync

		(*
			Would it be faster if we use MON?
			@returns true if the operation completes without issues.
		*)
		on openFile(posixFilePath)
			if not fileUtil's posixFilePathExists(posixFilePath) then return missing value

			if running of application "Marked" is false then
				activate application "Marked"
				delay 0.1
				tell application "Marked" to close every window
			end if

			set initialWinCount to _getSysEveWindowCount()
			set isFirstWindow to initialWinCount is 0
			if not isFirstWindow then set frontMarkedTab to getFrontTab()

			tell application "Marked"
				open posixFilePath
				delay 0.1
				set tabInstance to my _new(front window)
			end tell

			set newWinCount to _getSysEveWindowCount()
			if newWinCount is 2 then
				frontMarkedTab's focus()

				mergeWindows()
			end if
			tabInstance's focus()

			tabInstance
		end openFile


		on getFrontTab()
			if running of application "Marked" is false then return missing value
			if _getSysEveWindowCount() is 0 then return missing value

			tell application "Marked"
				try
					return my _new(front window)
				on error
					missing value
				end try
			end tell
		end getFrontTab


		(*
			@Known Issues:
				Application keeps reference to closed windows, we need to use System Events instead to check actual windows.
		*)
		on findTabWithName(documentName)
			if running of application "Marked" is false then return missing value

			tell application "System Events" to tell process "Marked"
				if (count of (windows whose name contains documentName)) is 0 then return missing value
			end tell

			try
				tell application "Marked"
					-- set appWindow to first window whose name is documentName
					set appWindow to first window whose name contains documentName
				end tell
			on error
				return missing value
			end try
			_new(appWindow)
		end findTabWithName


		on showCustomProcessorLog()
			if running of application "Marked" is false then return missing value

			tell application "System Events" to tell process "Marked"
				set frontmost to true
				try
					click menu item "Show Custom Processor Log" of menu 1 of menu bar item "Help" of menu bar 1
				end try
			end tell
		end showCustomProcessorLog


		on _new(pAppWindow)
			script MarkedTabInstance
				property appWindow : pAppWindow

				on setPreprocessorArguments(arguments)
					if running of application "Marked" is false then return

					tell application "System Events" to tell process "Marked"
						try
							click (first menu item of menu 1 of menu bar item "Marked" of menu bar 1 whose title starts with "Settings")
							delay 0.1
							set moreItems to pop up button 1 of toolbar 1 of front window
							click moreItems
							delay 0.1
							click menu item "Advanced" of menu 1 of moreItems
							delay 0.1
							click radio button "Preprocessor" of tab group 1 of window "Advanced"
							delay 0.1
							set the value of text field 2 of tab group 1 of window "Advanced" to arguments
							delay 0.1
							click (first button of front window whose description is "close button")
						end try
					end tell
				end setPreprocessorArguments

				(*
					NOTE: Take into account when the document is zoomed, the percentage is displayed in the window title.
				*)
				on getDocumentName()
					set windowName to name of appWindow
					set regex to regexPatternLib's new(".*(?=\\s\\(\\d{2}%\\))")
					set zoomLessName to regex's firstMatchInString(windowName)
					if zoomLessName is not missing value then return zoomLessName

					windowName
				end getDocumentName

				on hideEditor()
					if running of application "Marked" is false then return

					tell application "System Events" to tell process "Marked"
						set frontmost to true
						try
							click menu item "Hide Editor Pane" of menu 1 of menu bar item "View" of menu bar 1
						end try -- ignore if it don't exist
					end tell
				end hideEditor

				on focus()
					if running of application "Marked" is false then return

					try
						tell application "System Events" to tell process "Marked"
							click (first menu item of first menu of menu bar item "Window" of first menu bar whose title is equal to name of my appWindow)
						end tell
						true
					on error
						false
					end try
				end focus

				on closeTab()
					tell appWindow to close
				end closeTab
			end script
		end _new


		(*
			@Requires app focus.
		*)
		on mergeWindows()
			if running of application "Marked" is false then return

			tell application "System Events" to tell process "Marked"
				set frontmost to true

				repeat
					click menu item "Merge All Windows" of menu 1 of menu bar item "Window" of menu bar 1
					if (count of windows) is 1 then exit repeat
					delay 0.1
				end repeat
			end tell
		end mergeWindows

		-- Private Codes below =======================================================

		on _getSysEveWindowCount()
			tell application "System Events" to tell process "Marked"
				count of windows
			end tell
		end _getSysEveWindowCount
	end script
end new
